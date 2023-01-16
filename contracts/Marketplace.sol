// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.12;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

import "./OwnableAndCollab.sol";

contract Marketplace is ReentrancyGuard, Ownable, Pausable {
    string public constant NAME = "";

    string public constant SYMBOL = "";

    enum LISTING_TYPE {
        NONE,
        FIXED_PRICE,
        AUCTION
    }

    struct Listing {
        bool initialized;
        address owner;
        address nftContract;
        LISTING_TYPE listingType;
        uint256 listedQuantity;
        uint256 tokenId;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }

    // use as params for list function
    struct ListData {
        LISTING_TYPE listingType;
        address nftContract;
        uint listQuantity;
        uint256 tokenId;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }

    struct TradeInfo {
        address payable buyer;
        address payable owner;
        uint totalPrice;
    }

    // use as params for trade function
    struct BuyData {
        uint256 tokenId;
        uint256 quantity;
        address nftContract;
        address fromAddress;
    }

    mapping(bytes32 => Listing) private listings;

    mapping(address => bool) public allowedPaymentTokens;

    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    event Purchase(
        address indexed nftContract,
        address indexed from,
        address indexed to,
        uint256 totalPrice,
        address paymentToken,
        uint tokenId
    );

    event NftList(
        address indexed owner,
        LISTING_TYPE listingType,
        address indexed nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 startTime,
        uint256 endTime
    );

    constructor() {
        allowedPaymentTokens[address(0)] = true;
    }

    /**
     * @dev create a listing for the given token id
     * @param _data (type ListData )
     */
    function list(ListData memory _data) public whenNotPaused {
        validateListing(_data);

        bytes32 _listingId = computeListingId(
            _data.nftContract,
            msg.sender,
            _data.tokenId
        );

        Listing storage _listing = listings[_listingId];

        if (_listing.initialized != true) {
            _listing.initialized = true;
            _listing.nftContract = _data.nftContract;
            _listing.tokenId = _data.tokenId;
            _listing.owner = msg.sender;
        }

        _listing.listingType = _data.listingType;
        _listing.listedQuantity = _data.listQuantity;
        _listing.price = _data.price;
        _listing.startTime = _data.startTime;
        _listing.endTime = _data.endTime;

        emit NftList(
            msg.sender,
            _data.listingType,
            _data.nftContract,
            _data.tokenId,
            _data.price,
            _data.startTime,
            _data.endTime
        );
    }

    function buy(
        BuyData memory _data
    ) external payable nonReentrant whenNotPaused {
        bytes32 listingId = validateBuy(_data);
        _trade(listingId, _data.quantity);
    }

    /**
     * @dev remove the listing for the given token id
     * @param nftContract (type address) - address of the nft contract
     * @param tokenId (type uint256) - token id of the nft to delist
     */
    function delist(address nftContract, uint256 tokenId) public whenNotPaused {
        bytes32 _listingId = computeListingId(nftContract, msg.sender, tokenId);
        require(
            listings[_listingId].initialized,
            "Marketplace: Listing not initi alized"
        );

        require(
            listings[_listingId].listingType != LISTING_TYPE.NONE,
            "Marketplace: Listing not set for sale"
        );

        _clearListing(_listingId);
    }

    function listBatch(ListData[] memory _data) public whenNotPaused {
        for (uint i = 0; i < _data.length; i++) {
            list(_data[i]);
        }
    }

    /**
     * @dev pause
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev unpause contract
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev validate the listing provided by the user
     */
    function validateListing(ListData memory _data) public view {
        bool isERC1155 = _checkContractIsERC1155(_data.nftContract);
        require(
            isERC1155 == true,
            "Marketplace: Provided address is not valid ERC1155 contract"
        );

        require(
            _data.listingType == LISTING_TYPE.FIXED_PRICE ||
                _data.listingType == LISTING_TYPE.FIXED_PRICE,
            "Marketplace: Invalid listing type"
        );

        require(_data.price > 0, "Marketplace: Price must be greater than 0");

        require(
            _data.tokenId ==
                _balanceOfERC1155(_data.nftContract, msg.sender, _data.tokenId)
        );

        require(_isTokensApproved(_data.nftContract, msg.sender));
    }

    function validateBuy(BuyData memory _data) public view returns (bytes32) {
        require(
            msg.sender != _data.fromAddress,
            "Marketplace: Cannot self buy"
        );

        bytes32 _listingId = computeListingId(
            _data.nftContract,
            _data.fromAddress,
            _data.tokenId
        );

        Listing memory listing = listings[_listingId];

        _isForSale(_listingId);
        bool isERC1155 = _checkContractIsERC1155(_data.nftContract);
        if (isERC1155) {
            uint sellerTokenBalance = _balanceOfERC1155(
                _data.nftContract,
                _data.fromAddress,
                _data.tokenId
            );
            // write a require check based on list quantity after research
            require(
                sellerTokenBalance >= _data.quantity,
                "Seller has insufficient ERC1155 Tokens"
            );
        }
        if (listings[_listingId].listingType == LISTING_TYPE.AUCTION) {
            require(
                listings[_listingId].listedQuantity == _data.quantity,
                "Marketplace: Buy quantity must be equal to listed quantity in auction!"
            );
        }

        return (_listingId);
    }

    /**
     * @dev create a unique listing id
     * @param nftContract (type address) - address of the nft contract
     * @param owner (type address) - address of the owner
     * @param tokenId (type tokenId) - token id of the nft
     * @return the unique listing id
     */
    function computeListingId(
        address nftContract,
        address owner,
        uint256 tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftContract, owner, tokenId));
    }

    /**
     * @dev trade
     */
    function _trade(bytes32 _listindId, uint256 _quantity) internal {
        Listing memory _sellerListing = listings[_listindId];
        TradeInfo memory tradeInfo;

        tradeInfo.totalPrice = _sellerListing.price * _quantity;
        tradeInfo.owner = payable(_sellerListing.owner);
        tradeInfo.buyer = payable(msg.sender);

        require(
            msg.value >= tradeInfo.totalPrice,
            "Marketplace: Insufficient balance"
        );

        (bool success, ) = tradeInfo.owner.call{value: msg.value}("");
        require(success, "Marketplace: Payment failed");

        IERC1155(_sellerListing.nftContract).safeTransferFrom(
            tradeInfo.owner,
            tradeInfo.buyer,
            _sellerListing.tokenId,
            _quantity,
            "0x"
        );
    }

    /**
     * @dev deletes the listing from the smart contract
     * @param _listingId (type bytes32)
     */
    function _clearListing(bytes32 _listingId) internal {
        Listing storage _listing = listings[_listingId];

        _listing.listingType = LISTING_TYPE.NONE;
        delete _listing.price;
        delete _listing.startTime;
        delete _listing.endTime;
    }

    /**
     * @dev
     */
    function _isForSale(bytes32 _listingId) internal view {
        require(
            listings[_listingId].initialized,
            "Marketplace: Not initialized"
        );

        require(
            listings[_listingId].listingType != LISTING_TYPE.NONE,
            "Marketplace: Not for sale"
        );
        _isActive(_listingId);
    }

    function _isActive(bytes32 _listingId) internal view {
        require(
            listings[_listingId].startTime < _currentTime(),
            "Marketplace: Sale not started "
        );

        if (
            listings[_listingId].listingType == LISTING_TYPE.FIXED_PRICE &&
            (listings[_listingId].endTime != 0 &&
                _currentTime() > listings[_listingId].endTime)
        ) {
            revert("Listing has expired");
        }
    }

    /**
     * @dev checks if contract is an ERC1155 implementation
     * @return a bool
     */
    function _checkContractIsERC1155(
        address _contract
    ) internal view returns (bool) {
        bool success = IERC1155(_contract).supportsInterface(
            _INTERFACE_ID_ERC1155
        );
        return success;
    }

    /**
     * @dev checks the balance
     */
    function _balanceOfERC1155(
        address _nftContract,
        address _owner,
        uint256 _tokenId
    ) internal view returns (uint) {
        IERC1155 _token = IERC1155(_nftContract);
        return _token.balanceOf(_owner, _tokenId);
    }

    function _isTokensApproved(
        address _nftContract,
        address _owner
    ) internal view returns (bool) {
        IERC1155 _token = IERC1155(_nftContract);
        return _token.isApprovedForAll(_owner, _nftContract);
    }

    function _currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }
}

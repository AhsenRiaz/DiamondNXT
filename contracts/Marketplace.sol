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
    string public constant NAME = "DiamondNXT Marketplace";

    string public constant SYMBOL = "DNXT";

    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;

    uint256 public immutable LISTING_FEES;

    mapping(address => bool) private whitelist;

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
        uint listedQuantity;
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

    struct Bid {
        address nftContract;
        uint256 tokenId;
        address[] bidders;
        uint256[] prices;
        uint256[] quantities;
        uint256[] bidExpirations;
    }

    struct BidData {
        address nftContract;
        uint256 tokenId;
        address bidder;
        uint256 price;
        uint256 quantity;
        uint256 bidExpiration;
    }

    mapping(bytes32 => Listing) private listings;

    mapping(bytes32 => Bid) private bids;

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

    event PriceUpdate(
        address indexed nftContract,
        address indexed owner,
        uint256 tokenId,
        uint256 newPrice
    );

    event BidOffer(
        address indexed nftContract,
        uint256 indexed tokenId,
        address indexed bidder,
        uint256 price,
        uint256 quantity,
        uint256 bidExpiration
    );

    constructor(address[] memory accounts, uint256 _listingFees) {
        for (uint i = 0; i < accounts.length; i++) {
            whitelist[accounts[i]] = true;
        }
        LISTING_FEES = _listingFees;
    }

    /**
     * @dev get listing details
     * @param tokenId (type uint256) - id of the token to get the listing details for
     */
    function getListingDetails(
        address nftContract,
        address owner,
        uint256 tokenId
    ) public view returns (Listing memory) {
        bytes32 _listingId = computeListingId(nftContract, owner, tokenId);
        return listings[_listingId];
    }

    function isAccountWhitelisted(address account) public view returns (bool) {
        return whitelist[account];
    }

    /**
     * @dev create a listing for the given token id
     * @param _data (type ListData )
     */
    function list(ListData memory _data) public payable whenNotPaused {
        if (!whitelist[msg.sender]) {
            require(
                msg.value >= LISTING_FEES,
                "Marketplace: Insufficient listing fees"
            );
        }

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
        _listing.listedQuantity = _data.listedQuantity;
        _listing.price = _data.price;
        _listing.startTime = _data.startTime;
        _listing.endTime = _data.endTime;

        (bool success, ) = payable(owner()).call{value: msg.value}("");
        require(success, "Marketplace: List transaction failedI");

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

    function bid(BidData memory _bidParam) external {
        require(
            _bidParam.nftContract != address(0),
            "Marketplace: NftContract cannot be zero address"
        );

        require(_bidParam.tokenId != 0, "Marketplace: Token id cannot be zero");

        bytes32 bidId = computeBidId(_bidParam.nftContract, _bidParam.tokenId);

        Bid storage _bid = bids[bidId];
        _bid.bidders.push(_bidParam.bidder);
        _bid.prices.push(_bidParam.price);
        _bid.quantities.push(_bidParam.quantity);
        _bid.bidExpirations.push(_bidParam.bidExpiration);
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
            "Marketplace: Listing not initialized"
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
            _balanceOfERC1155(_data.nftContract, msg.sender, _data.tokenId) >=
                _data.listedQuantity,
            "Marketplace: Insufficient ERC1155 token balance"
        );
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
        if (listing.listingType == LISTING_TYPE.AUCTION) {
            require(
                listing.listedQuantity == _data.quantity,
                "Marketplace: Buy quantity must be equal to listed quantity in auction!"
            );
        }

        return (_listingId);
    }

    /**
     * @dev create a unique listing id
     * @param nftContract (type address) - address of the nft contract
     * @param _owner (type address) - address of the owner
     * @param tokenId (type tokenId) - token id of the nft
     * @return the unique listing id
     */
    function computeListingId(
        address nftContract,
        address _owner,
        uint256 tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftContract, _owner, tokenId));
    }

    function computeBidId(
        address nftContract,
        uint256 tokenId
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(nftContract, tokenId));
    }

    function updatePrice(
        address nftContract,
        address _owner,
        uint256 tokenId,
        uint256 newPrice
    ) external {
        bytes32 _listindId = computeListingId(nftContract, _owner, tokenId);
        Listing storage listing = listings[_listindId];
        listing.price = newPrice;

        emit PriceUpdate(nftContract, _owner, tokenId, newPrice);
    }

    /**
     * @dev trade the token
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
        delete _listing.listedQuantity;
        delete _listing.listingType;
        delete _listing.tokenId;
        delete _listing.initialized;
        delete _listing.nftContract;
        delete _listing.owner;
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

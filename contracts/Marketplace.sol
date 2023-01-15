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
        address paymentToken;
        LISTING_TYPE listingType;
        uint256 tokenId;
        uint256 price;
        uint256 startTime;
        uint256 endTime;
    }

    // use as params for list function
    struct ListData {
        LISTING_TYPE listingType;
        address nftContract;
        address paymentToken;
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

    function list(ListData memory _data) external {
        validateListing(_data);
    }

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
            allowedPaymentTokens[_data.paymentToken] == true,
            "Marketplace: Invalid payment token"
        );

        require(
            _data.tokenId ==
                _balanceOfERC1155(_data.nftContract, msg.sender, _data.tokenId)
        );

        require(_isTokensApproved(_data.nftContract, msg.sender));
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

    function _checkContractIsERC1155(
        address _contract
    ) internal view returns (bool) {
        bool success = IERC1155(_contract).supportsInterface(
            _INTERFACE_ID_ERC1155
        );
        return success;
    }

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
}

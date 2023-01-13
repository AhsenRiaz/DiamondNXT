// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1155Asset is ERC1155, ERC1155Supply, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // contract name
    string public name;

    // number of tokens minted (Also includes burned and reminted tokens)
    uint public totalMinted;

    struct Token {
        address minter;
        string metadataUri;
    }

    // mapping of id to token;
    mapping(uint256 => Token) private _tokens;

    event TokensMinted(
        address indexed account,
        uint indexed tokenId,
        uint amount
    );
    event CollectionInitiated(
        address indexed contractOwner,
        uint amountOfSeries
    );

    modifier onlyMinter(uint tokenId) {
        require(exists(tokenId), "ERC1155: Token does not exist");
        require(
            msg.sender == _tokens[tokenId].minter,
            "ERC1155: Caller is not minter"
        );
        _;
    }

    constructor(string memory _name) ERC1155("") {
        name = _name;
    }

    /**
     * @dev mint `amount` of tokens of token type `id`, assigns them to `account`
     * @param account (type address) - address to mint tokens to
     * @param id (type uint256) - token id
     * @param amount (type uint256)  - amount of tokens to mint
     * @param metadataUri (type string) - the metadata uri
     */

    function mint(
        address account,
        uint256 id,
        uint256 amount,
        string calldata metadataUri
    ) external onlyOwner {
        require(!exists(id), "Token already exists");

        totalMinted += 1;
        _tokens[id].minter = account;
        _tokens[id].metadataUri = metadataUri;
        _mint(account, id, amount, "");

        emit TokensMinted(account, id, amount);
    }

    /**
     * @dev mint `amounts` of tokens of token types `ids`, assigns them to `account`
     * @param account (type address) - address to mint tokens to
     * @param ids (type uint256[]) - token id
     * @param amounts (type uint256[])  - amount of tokens to mint
     * @param metadataUris (type string[]) - the metadata uri
     */

    function mintBatch(
        address account,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        string[] calldata metadataUris
    ) external {
        uint arrayLength = ids.length;
        require(
            amounts.length == arrayLength && metadataUris.length == arrayLength,
            "ERC1155Asset: Input length mismatch"
        );
        totalMinted += arrayLength;
        for (uint i = 0; i < arrayLength; i++) {
            require(exists(ids[i]), "ERC1155Asset: A token id already exists");
            _tokens[ids[i]].minter = account;
            _tokens[ids[i]].metadataUri = metadataUris[i];
        }
        _mintBatch(account, ids, amounts, "");
    }

    /**
    @dev See {IERC165-supportsInterface}.
    */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev returns metadata uri of a token
     * @param tokenId (type uint256)
     */
    function uri(uint256 tokenId) public view override returns (string memory) {
        require(exists(tokenId), "ERC1155Asset: Token does not exist");
        return _tokens[tokenId].metadataUri;
    }

    function minterOf(uint256 tokenId) public view returns (address) {
        require(exists(tokenId), "ERC1155Asset: Token does not exist");
        return _tokens[tokenId].minter;
    }

    // The following functions are overrides required by solidity

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155Supply, ERC1155) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
}

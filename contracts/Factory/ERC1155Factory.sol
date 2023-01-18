// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./ERC1155BaseFactory.sol";
import "../Assets/ERC1155Asset.sol";

contract ERC1155Factory is Initializable, ERC1155BaseFactory {
    // owner 0xf1

    event ERC1155CollectionCreated(
        address indexed collection,
        string name,
        string symbol,
        address owner
    );

    struct Erc1155MintData {
        address to;
        uint256 tokenId;
        uint256 amount;
        string metadataUri;
    }

    struct Erc1155MintDataBatch {
        address to;
        uint256[] tokenIds;
        uint256[] amounts;
        string[] metadataUris;
    }

    function initialize(
        string memory _name,
        string memory _symbol
    ) external initializer {
        init(_name, _symbol);
    }

    /**
     * @dev function to create an erc1155 collection
     * @param _name (type string) - name of collection
     * @param _symbol (type string) - symbol of collection
     * @param _newOwner (type address) - address of the account creating the collection
     * @return address of the erc1155 collection
     */
    function createCollection(
        string memory _name,
        string memory _symbol,
        address _newOwner
    ) external whenNotPaused returns (address) {
        //  Set Owner and Collaborator based on conditions
        require(
            _newOwner != address(0),
            "ERC1155Factory: Owner cannot be address zero"
        );
        ERC1155Asset _erc1155 = new ERC1155Asset(_name, _symbol, _newOwner);
        createdCollections[address(_erc1155)] = true;
        emit ERC1155CollectionCreated(
            address(_erc1155),
            _name,
            _symbol,
            _newOwner
        );
        return address(_erc1155);
    }

    /**
     * @dev create NFT for account
     * @param _erc1155Collection (type address) - address of the collection contract
     * @param _mintData (type sruct) - an object of parameters
     */
    function createItem(
        address _erc1155Collection,
        Erc1155MintData calldata _mintData
    ) external {
        ERC1155Asset(_erc1155Collection).mint(
            _mintData.to,
            _mintData.tokenId,
            _mintData.amount,
            _mintData.metadataUri
        );
    }

    /**
     * @dev create multiple NFTs for account
     * @param _erc1155Collection (type address) - address of the collection contract
     * @param _mintData (type sruct) - an object of parameters
     */
    function createItemBatch(
        address _erc1155Collection,
        Erc1155MintDataBatch calldata _mintData
    ) external {
        ERC1155Asset(_erc1155Collection).mintBatch(
            _mintData.to,
            _mintData.tokenIds,
            _mintData.amounts,
            _mintData.metadataUris
        );
    }
}

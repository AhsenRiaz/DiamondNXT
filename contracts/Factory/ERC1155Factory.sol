// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./ERC1155BaseFactory.sol";
import "../Assets/ERC1155Asset.sol";

contract ERC1155Factory is Initializable, ERC1155BaseFactory {
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
    ) public initializer {
        init(_name, _symbol);
    }

    function createCollection(
        string memory _name,
        string memory _symbol,
        address _newOwner
    ) external whenNotPaused returns (address) {
        //  Set Owner and Collaborator based on conditions
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

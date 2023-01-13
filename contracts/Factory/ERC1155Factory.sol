// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC1155BaseFactory.sol";

contract ERC1155Factory is Initializable, ERC1155BaseFactory {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    event ERC1155CollectionCreated(
        address indexed collection,
        address indexed owner,
        string name,
        string metadataUri
    );

    struct Erc1155MintData {
        address to;
        uint256 tokenId;
        uint256 amount;
        string metadataUri;
    }

    function initialize(
        string memory _name,
        string memory _symbol
    ) public initializer {
        init(_name, _symbol);
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract ERC1155BaseFactory is Initializable, Ownable, Pausable {
    // contract name
    string public name;

    // contract symbol
    string public symbol;

    // mapping of address to bool for createdCollections
    mapping(address => bool) public createdCollections;

    function init(
        string memory _name,
        string memory _symbol
    ) internal onlyInitializing {
        name = _name;
        symbol = _symbol;
    }

    /**
     * @dev pause contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev unpause contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}

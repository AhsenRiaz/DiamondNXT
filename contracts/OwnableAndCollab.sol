// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.12;

contract OwnableAndCollab {
    address private _owner;

    mapping(address => bool) private _collaborators;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event CollaboratorStatusChanged(
        address indexed account,
        bool isCollaborator
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address newOwner) {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner or collaborator.
     */
    modifier onlyOwnerAndCollaborator() {
        require(
            owner() == msg.sender || _collaborators[msg.sender] == true,
            "OwnableAndCollab: caller is not the owner or a collaborator"
        );
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns if account is collaborator or not
     */
    function isAccountCollaborator(
        address account
    ) public view virtual returns (bool) {
        return _collaborators[account];
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @dev sets collaborator status on or off for accounts
     */
    function setCollaborator(
        address account,
        bool isCollaborator
    ) public virtual onlyOwner {
        require(
            account != address(0),
            "OwnableAndCollab: account is zero address"
        );
        _setCollaborator(account, isCollaborator);
        emit CollaboratorStatusChanged(account, isCollaborator);
    }

    function _setCollaborator(address account, bool isCollaborator) internal {
        _collaborators[account] = isCollaborator;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts@v5.0.2/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts@v5.0.2/access/Ownable.sol";

/// @title ERC20 contract which allows the owner to sanction addresses to send and receive tokens
/// @author marioiordanov
/// @notice Ordinary user can use this contract for basic token functionality, but the owner can also stop you from sending and receiving tokens
/// @dev s_sanctionedAddresses is a mapping holding the sanctioned addresses
contract ERC20WithSanctions is ERC20, Ownable {
    uint256 private constant INITIAL_OWNER_BALANCE = 1 ether;
    // state vars
    mapping(address => bool) private s_sanctionedAddresses;

    // events
    event AddressSanctioned(address indexed account);
    event AddressIsNotSanctioned(address indexed account);

    // errors
    error SanctionedSender();
    error SanctionedReceiver();

    constructor(
        string memory name,
        string memory symbol
    ) ERC20(name, symbol) Ownable(msg.sender) {
        _mint(owner(), INITIAL_OWNER_BALANCE);
    }

    function sanctionAddress(address account) external onlyOwner {
        s_sanctionedAddresses[account] = true;
        emit AddressSanctioned(account);
    }

    function removeSanctionForAddress(address account) external onlyOwner {
        s_sanctionedAddresses[account] = false;
        emit AddressIsNotSanctioned(account);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function transfer(
        address to,
        uint256 value
    ) public override returns (bool) {
        if (isAddressSanctioned(msg.sender)) {
            revert SanctionedSender();
        }

        if (isAddressSanctioned(to)) {
            revert SanctionedReceiver();
        }

        super._transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public override returns (bool) {
        if (isAddressSanctioned(from)) {
            revert SanctionedSender();
        }

        if (isAddressSanctioned(to)) {
            revert SanctionedReceiver();
        }

        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function isAddressSanctioned(address account) public view returns (bool) {
        return s_sanctionedAddresses[account];
    }
}

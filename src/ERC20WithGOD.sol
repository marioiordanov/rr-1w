// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts@v5.0.2/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts@v5.0.2/access/Ownable.sol";

/// @title ERC20 contract which has a GOD address that can transfer tokens from anyone to anyone
/// @author marioiordanov
/// @notice Ordinary user can use this contract for basic token functionality, but the GOD address can transfer its balance to another address
/// @dev s_god is the GOD address, its set by the owner in the constructor
contract ERC20WithGOD is ERC20, Ownable {
    uint256 private constant INITIAL_OWNER_BALANCE = 1 ether;
    // state vars
    address private immutable s_god;

    constructor(string memory name, string memory symbol, address god) ERC20(name, symbol) Ownable(msg.sender) {
        s_god = god;
        _mint(owner(), INITIAL_OWNER_BALANCE);
    }

    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (msg.sender != s_god) {
            _spendAllowance(from, msg.sender, value);
        }

        _transfer(from, to, value);
        return true;
    }
}

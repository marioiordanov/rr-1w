// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20WithSanctions} from "../src/ERC20WithSanctions.sol";

contract ERC20WithSanctionsTest is Test {
    ERC20WithSanctions private erc20;
    address private OWNER = address(1);
    address private SANCTIONED = address(2);
    address private RANDOM_USER = address(3);

    function setUp() public {
        vm.prank(OWNER);
        erc20 = new ERC20WithSanctions("Sanctions", "STT");

        vm.startPrank(OWNER);
        erc20.mint(SANCTIONED, 1 ether);
        erc20.mint(RANDOM_USER, 1 ether);
        vm.stopPrank();
    }

    modifier withSaction() {
        vm.prank(OWNER);
        erc20.sanctionAddress(SANCTIONED);
        _;
    }

    function testSanctionedUserCantTransferTokens() public withSaction {
        vm.prank(SANCTIONED);
        vm.expectRevert(ERC20WithSanctions.SanctionedSender.selector);
        erc20.transfer(RANDOM_USER, 1 ether);
    }

    function testSanctionedUserCantTransferFromTokens() public withSaction {
        vm.prank(SANCTIONED);
        erc20.approve(RANDOM_USER, type(uint256).max);

        vm.prank(RANDOM_USER);
        vm.expectRevert(ERC20WithSanctions.SanctionedSender.selector);
        erc20.transferFrom(SANCTIONED, RANDOM_USER, 1 ether);
    }

    function testOnlyOwnerCanSanctionAddress() public {
        vm.prank(RANDOM_USER);
        vm.expectRevert();
        erc20.sanctionAddress(SANCTIONED);
        assertEq(erc20.isAddressSanctioned(SANCTIONED), false);

        vm.prank(OWNER);
        erc20.sanctionAddress(SANCTIONED);
        assertEq(erc20.isAddressSanctioned(SANCTIONED), true);
    }

    function testSanctionedUserCantReceiveTokensViaTransfer() public withSaction {
        vm.prank(RANDOM_USER);
        vm.expectRevert(ERC20WithSanctions.SanctionedReceiver.selector);
        erc20.transfer(SANCTIONED, 1 ether);
    }

    function testSanctionedUserCantReceiveTokensViaTransferFrom() public withSaction {
        vm.prank(OWNER);
        erc20.approve(RANDOM_USER, type(uint256).max);

        vm.prank(RANDOM_USER);
        vm.expectRevert(ERC20WithSanctions.SanctionedReceiver.selector);
        erc20.transferFrom(OWNER, SANCTIONED, 1 ether);
    }
}

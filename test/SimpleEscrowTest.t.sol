// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SimpleEscrow} from "../src/SimpleEscrow.sol";
import {ERC20Mock} from "@openzeppelin/contracts@v5.0.2/mocks/token/ERC20Mock.sol";

contract SimpleEscrowTest is Test {
    SimpleEscrow private escrow;
    ERC20Mock private erc20;
    address private DEPOSITOR = address(1);
    address private RECEIVER = address(2);

    modifier depositorDeposits() {
        vm.startPrank(DEPOSITOR);
        erc20.approve(address(escrow), 1 ether);
        escrow.deposit(1 ether);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        erc20 = new ERC20Mock();
        erc20.mint(DEPOSITOR, 2 ether);
        escrow = new SimpleEscrow(address(erc20), RECEIVER);
    }

    function testReceiverWithdrawsSuccessfully() public depositorDeposits {
        uint256 receiverBalance = erc20.balanceOf(RECEIVER);

        vm.warp(block.timestamp + 3 days);

        vm.prank(RECEIVER);
        escrow.withdraw();
        assert(receiverBalance < erc20.balanceOf(RECEIVER));
    }

    function testOnlyReceiverCanWithdraw() public depositorDeposits {
        vm.prank(DEPOSITOR);
        vm.expectRevert(SimpleEscrow.NotIntendedReceiver.selector);
        escrow.withdraw();
    }

    function testOnlyReceiverCanWithdrawAfterLockPeriod()
        public
        depositorDeposits
    {
        vm.warp(block.timestamp + 2 days);
        vm.prank(RECEIVER);
        vm.expectRevert(SimpleEscrow.NotEnoughTimePassed.selector);
        escrow.withdraw();
    }
}

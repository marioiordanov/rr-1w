// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20WithGOD} from "../src/ERC20WithGOD.sol";
import {IERC20Errors} from "@openzeppelin/contracts@v5.0.2/interfaces/draft-IERC6093.sol";

contract ERC20WithGODTest is Test {
    ERC20WithGOD private erc20;
    address private OWNER = address(1);
    address private GOD = address(2);
    address private RANDOM_USER = address(3);

    function setUp() public {
        vm.prank(OWNER);
        erc20 = new ERC20WithGOD("GOD TOKEN", "GOD", GOD);

        vm.startPrank(OWNER);
        erc20.mint(RANDOM_USER, 100 ether);
        vm.stopPrank();
    }

    function testGodCanTransferTokensFromAnyoneToAnyone() public {
        uint256 godInitialBalance = erc20.balanceOf(GOD);
        uint256 randomInitialBalance = erc20.balanceOf(RANDOM_USER);
        uint256 amountToTransfer = 1 ether;

        vm.prank(GOD);
        erc20.transferFrom(RANDOM_USER, GOD, amountToTransfer);

        assertEq(erc20.balanceOf(GOD), godInitialBalance + amountToTransfer);
        assertEq(
            erc20.balanceOf(RANDOM_USER),
            randomInitialBalance - amountToTransfer
        );
    }

    function testNonGodCannotTransferTokensFromAnyoneToAnyone() public {
        vm.prank(OWNER);
        erc20.mint(GOD, 1 ether);

        vm.prank(RANDOM_USER);
        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientAllowance.selector,
                RANDOM_USER,
                0,
                1 ether
            )
        );
        erc20.transferFrom(GOD, RANDOM_USER, 1 ether);
    }
}

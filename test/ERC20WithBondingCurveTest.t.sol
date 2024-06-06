// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20WithBondingCurve} from "../src/ERC20WithBondingCurve.sol";

contract ERC20WithBondingCurveTest is Test {
    ERC20WithBondingCurve private erc20;
    address private USER1 = address(1);
    address private USER2 = address(2);

    function setUp() public {
        erc20 = new ERC20WithBondingCurve("Bonding Curve Token", "BCT");
        vm.deal(USER1, 1000 ether);
        vm.deal(USER2, 1000 ether);
    }

    function assertApproxEq(
        uint256 left,
        uint256 right,
        uint256 decimals
    ) private pure {
        uint256 epsilon = 10 ** decimals;
        if (left > right) {
            assert(left - right < epsilon);
        } else {
            assert(right - left < epsilon);
        }
    }

    // simulation of front running attack
    function testUserCannotReceiveLessThanMinimumAmountSpecified() public {
        vm.prank(USER1);
        uint256 weiFor5tokens = erc20._getWeiAmountForTokens(
            5 * 10 ** erc20.decimals()
        );

        // front running simulation
        vm.startPrank(USER2);
        uint256 mintedTokens = erc20.mint{value: uint256(4 * 1 ether) / 3}(
            1 * 10 ** erc20.decimals() - 10
        );
        assertEq(erc20.balanceOf(USER2), mintedTokens);

        vm.stopPrank();

        vm.startPrank(USER1);
        uint256 expectedTokens = 5 * 10 ** erc20.decimals();
        vm.expectRevert(ERC20WithBondingCurve.NotEnoughTokensMinted.selector);
        erc20.mint{value: weiFor5tokens}((expectedTokens * 95) / 100);
    }

    function testUserCanBuyAndSell() public {
        uint256 user1InitialBalance = USER1.balance;
        vm.startPrank(USER1);
        uint256 user1minted = erc20.mint{value: 4.5 ether}(
            1 * 10 ** erc20.decimals()
        );
        vm.stopPrank();

        vm.startPrank(USER2);
        erc20.mint{value: 20 ether}(4 * 10 ** erc20.decimals());
        vm.stopPrank();

        vm.prank(USER1);
        erc20.burn(user1minted, 16 ether);
        assert(user1InitialBalance < USER1.balance);
    }
}

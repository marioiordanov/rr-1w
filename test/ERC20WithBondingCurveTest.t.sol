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

    function testXTokensCostYEther() public view {
        assertApproxEq(
            erc20.getPriceForAmountOfTokensInWei(3 * 10 ** erc20.decimals()),
            8e18,
            1
        );

        assertApproxEq(
            erc20.getPriceForAmountOfTokensInWei(5 * 10 ** erc20.decimals()),
            20e18,
            1
        );
    }

    function testYEtherBuysXTokens() public view {
        assertApproxEq(
            5 * 10 ** erc20.decimals(),
            erc20.getTokensAmountForWei(20e18),
            1
        );
    }

    function testUserCanMintAndThenBurn() public {
        vm.startPrank(USER1);
        uint256 tokenToMintAmount = 5 * 10 ** erc20.decimals();

        uint256 priceToMint = erc20.getPriceForAmountOfTokensInWei(
            tokenToMintAmount
        );

        uint256 userInitialBalance = USER1.balance;

        uint256 mintedTokens = erc20.mint{value: priceToMint + 0 ether}(
            tokenToMintAmount
        );

        assertEq(erc20.balanceOf(USER1), tokenToMintAmount);
        assertEq(USER1.balance, userInitialBalance - priceToMint);

        uint256 weiReturned = erc20.burn(mintedTokens, priceToMint - 10);
        assertApproxEq(weiReturned, priceToMint, 1);
        assertApproxEq(USER1.balance, userInitialBalance, 1);
    }

    // simulation of front running attack
    function testUserCannotReceiveLessThanMinimumAmountSpecified() public {
        vm.prank(USER1);
        uint256 weiFor5tokens = erc20.getPriceForAmountOfTokensInWei(
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
        erc20.mint{value: weiFor5tokens}((expectedTokens * 9) / 10);
    }

    function testUserCanSellForBetterPriceIfThereAreBuyersAfterHim() public {
        uint256 user1InitialBalance = USER1.balance;
        vm.prank(USER1);
        uint256 tokensMinted = erc20.mint{value: 2 ether}(0);
        vm.prank(USER2);
        erc20.mint{value: 2 ether}(0);
        vm.prank(USER1);
        uint256 minimumWeiReturn = 2 ether;
        uint256 weiReturned = erc20.burn(tokensMinted, minimumWeiReturn);
        assert(weiReturned > minimumWeiReturn);
        assert(USER1.balance > user1InitialBalance);
    }

    function testPriceOfTokenAfter2Sales() public {
        vm.prank(USER1);
        erc20.mint{value: 2 ether}(0);
        vm.prank(USER2);
        erc20.mint{value: 2 ether}(0);

        console.log(address(erc20).balance);
        console.log(erc20.getCurrentPrice());
    }
}

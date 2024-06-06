// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts@v5.0.2/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts@v5.0.2/utils/math/Math.sol";

/// @title ERC20 contract with a bonding curve.
/// @author marioiordanov
/// @notice ERC20 with buying/selling functionality.
/// @notice The price of the token increases with each mint and decreases with each burn.
/// @notice Price of token is denominated in wei.
/// @dev Linear bonding curve function is used: price = 4/3*total_supply
contract ERC20WithBondingCurve is ERC20 {
    using Math for uint256;

    uint256 private constant BONDING_CURVE_FUNCTION_NUMERATOR = 4;
    uint256 private constant BONDING_CURVE_FUNCTION_DENOMINATOR = 3;
    uint256 private constant ETHER_TO_WEI = 1e18;
    uint256 private constant SCALING_FACTOR = 1e18;

    uint256 private constant B_COEFICIENT = 1e18;
    uint256 private constant A_COEFICIENT = 2e18;
    uint256 private constant C_COEFICIENT = 6e18;

    uint256 private constant TRIANGLE_FORMULA_DENOMINATOR = 2;

    error NotEnoughTokensMinted();
    error NotEnoughWeiReturnedAfterBurn();
    error TransferFailed();

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(
        uint256 minimumAmountMinted
    ) external payable returns (uint256) {
        uint256 newTokensMinted = _getTokensAmountForWei(msg.value);
        if (newTokensMinted < minimumAmountMinted) {
            revert NotEnoughTokensMinted();
        }
        _mint(msg.sender, newTokensMinted);
        return newTokensMinted;
    }

    function burn(
        uint256 tokenAmount,
        uint256 minimumWeiReturned
    ) external returns (uint256) {
        uint256 currentTotalWei = _getPriceForAmountOfTokensInWei(
            totalSupply(),
            false
        );

        uint256 totalWeiAfterBurn = _getPriceForAmountOfTokensInWei(
            totalSupply() - tokenAmount,
            false
        );

        uint256 weiReturned = currentTotalWei - totalWeiAfterBurn;

        if (weiReturned < minimumWeiReturned) {
            revert NotEnoughWeiReturnedAfterBurn();
        }

        _burn(msg.sender, tokenAmount);
        (bool success, ) = msg.sender.call{value: weiReturned}("");
        if (!success) {
            revert TransferFailed();
        }
        return weiReturned;
    }

    function getCurrentPrice() public view returns (uint256) {
        return _getPriceForAmountOfTokensInWei(totalSupply(), true);
    }

    function getPriceForAmountOfTokensInWei(
        uint256 tokenAmount
    ) public view returns (uint256) {
        if (totalSupply() == 0) {
            return
                _getPriceForAmountOfTokensInWei(
                    totalSupply() + tokenAmount,
                    true
                );
        }
        return
            _getPriceForAmountOfTokensInWei(totalSupply() + tokenAmount, true) -
            _getPriceForAmountOfTokensInWei(totalSupply(), true);
    }

    function getTokensAmountForWei(
        uint256 weiAmount
    ) public view returns (uint256) {
        return _getTokensAmountForWei(weiAmount);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    // Convert tokens to price in wei, regarding token decimals
    // price = (x.y + y) / 2
    // x - total supply + token amount
    // y - calculated from x
    function _getPriceForAmountOfTokensInWei(
        uint256 tokensTotalSupply,
        bool roundUp
    ) private pure returns (uint256) {
        uint256 x = tokensTotalSupply;
        if (roundUp) {
            uint256 y = (x * BONDING_CURVE_FUNCTION_NUMERATOR).ceilDiv(
                BONDING_CURVE_FUNCTION_DENOMINATOR
            );

            return
                (y * (x + 1 * 10 ** decimals())).ceilDiv(
                    (TRIANGLE_FORMULA_DENOMINATOR * (10 ** decimals()))
                );
        } else {
            uint256 y = (x * BONDING_CURVE_FUNCTION_NUMERATOR) /
                BONDING_CURVE_FUNCTION_DENOMINATOR;

            return
                (y * (x + 1 * 10 ** decimals())) /
                ((TRIANGLE_FORMULA_DENOMINATOR * (10 ** decimals())));
        }
    }

    // amount of tokens to returns is calculated by the formula:
    // derived from square root formula, for positive root only
    // tokens = (-1 + sqrt( 1 + 6 * wei amount)) / 2
    function _getTokensAmountForWei(
        uint256 weiAmount
    ) private view returns (uint256) {
        uint256 x = totalSupply();
        uint256 y = (x * BONDING_CURVE_FUNCTION_NUMERATOR) /
            BONDING_CURVE_FUNCTION_DENOMINATOR;

        weiAmount +=
            (y * (x + 1 * 10 ** decimals())) /
            ((TRIANGLE_FORMULA_DENOMINATOR * (10 ** decimals())));

        uint256 squareRoot = ((B_COEFICIENT +
            ((C_COEFICIENT / SCALING_FACTOR) * weiAmount)) * SCALING_FACTOR)
            .sqrt();

        uint256 updatedTotalSupply = ((squareRoot - B_COEFICIENT) *
            10 ** decimals()) / A_COEFICIENT;

        return updatedTotalSupply - totalSupply();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts@v5.0.2/token/ERC20/ERC20.sol";
import {Math} from "@openzeppelin/contracts@v5.0.2/utils/math/Math.sol";

/// @title ERC20 contract with a bonding curve.
/// @author marioiordanov
/// @notice ERC20 with buying/selling functionality.
/// @notice The price of the token increases with each mint and decreases with each burn.
/// @notice Price of token is denominated in wei.
/// @dev Linear bonding curve function is used: price = total_supply
contract ERC20WithBondingCurve is ERC20 {
    using Math for uint256;

    uint256 private constant ETHER_TO_WEI = 1e18;
    uint256 private constant SCALING_FACTOR = 1e18;

    uint256 private constant TRIANGLE_AREA_DENOMINATOR = 2;

    error NotEnoughTokensMinted();
    error NotEnoughWeiReturnedAfterBurn();
    error TransferFailed();

    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(
        uint256 minimumAmountMinted
    ) external payable returns (uint256) {
        uint256 currentTotalSupply = totalSupply();

        uint256 currentTotalSupplyInWei = _getWeiAmountForTokens(
            currentTotalSupply
        );

        uint256 newTokensMinted = _getAmountOfTokensForWei(
            currentTotalSupplyInWei + msg.value
        ) - currentTotalSupply;

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
        uint256 currentTotalSupply = totalSupply();
        uint256 currentTotalSupplyInWei = _getWeiAmountForTokens(
            currentTotalSupply
        );
        uint256 totalSupplyInWeiAfterBurn = _getWeiAmountForTokens(
            currentTotalSupply - tokenAmount
        );

        uint256 weiReturned = currentTotalSupplyInWei -
            totalSupplyInWeiAfterBurn;

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

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    // calculate area of a triangle between curve, origin(0,0) and x, f(x)
    // area = x * y / 2
    function _getWeiAmountForTokens(
        uint256 tokenAmount
    ) public pure returns (uint256) {
        uint256 x = tokenAmount;
        uint256 y = x;

        return
            _convertTokensToWei(
                (x * y) / TRIANGLE_AREA_DENOMINATOR / 10 ** decimals()
            );
    }

    // derived from formula for tokens -> wei:
    // price = x * f(x) / 2 => x * f(x) = price * w
    // f(x) = x => x^2 = price * 2 => x = sqrt(price * 2)
    function _getAmountOfTokensForWei(
        uint256 weiAmount
    ) public pure returns (uint256) {
        uint256 newTokens = (TRIANGLE_AREA_DENOMINATOR *
            weiAmount *
            SCALING_FACTOR).sqrt();
        return _convertWeiToTokens(newTokens);
    }

    // converting tokens unit to wei unit
    function _convertTokensToWei(
        uint256 tokenAmount
    ) private pure returns (uint256) {
        return (tokenAmount * ETHER_TO_WEI) / 10 ** decimals();
    }

    // f(x) = x
    // converting wei unit to token unit
    function _convertWeiToTokens(
        uint256 weiAmount
    ) private pure returns (uint256) {
        return (weiAmount * 10 ** decimals()) / ETHER_TO_WEI;
    }
}

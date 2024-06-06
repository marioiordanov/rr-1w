// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;
import {SafeERC20} from "@openzeppelin/contracts@v5.0.2/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts@v5.0.2/token/ERC20/IERC20.sol";

contract SimpleEscrow {
    uint256 private constant LOCK_PERIOD = 3 days;
    IERC20 private immutable s_token;
    address private immutable s_receiver;
    uint256 private s_amountToReceive;
    uint256 private s_timestampOfLastDeposit;

    event Deposited(uint256 amount);
    event WithdrawnAll();

    error NotEnoughTimePassed();
    error NotIntendedReceiver();

    modifier onlyReceiver() {
        if (msg.sender != s_receiver) revert NotIntendedReceiver();
        _;
    }

    constructor(address _token, address _receiver) {
        s_token = IERC20(_token);
        s_receiver = _receiver;
    }

    function deposit(uint256 _amount) external {
        uint256 initialBalanceOfThisContract = s_token.balanceOf(address(this));
        SafeERC20.safeTransferFrom(
            IERC20(s_token),
            msg.sender,
            address(this),
            _amount
        );
        uint256 depositedAmount = s_token.balanceOf(address(this)) -
            initialBalanceOfThisContract;
        s_amountToReceive += depositedAmount;

        s_timestampOfLastDeposit = block.timestamp;
        emit Deposited(depositedAmount);
    }

    // no need for reentrancy guard
    function withdraw() external onlyReceiver {
        if (!canWithdraw()) {
            revert NotEnoughTimePassed();
        }
        uint256 amountToReceive = s_amountToReceive;
        s_amountToReceive = 0;
        SafeERC20.safeTransfer(IERC20(s_token), s_receiver, amountToReceive);
        emit WithdrawnAll();
    }

    function canWithdraw() public view returns (bool) {
        return block.timestamp >= s_timestampOfLastDeposit + LOCK_PERIOD;
    }
}

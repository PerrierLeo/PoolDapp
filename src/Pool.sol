// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title Pools
/// @author Léo

import "@openzeppelin/contracts/access/Ownable.sol";

error CollectIsFinished();
error GoalAlreadyReached();
error CollectNotFinished();
error FailedToSendEther();
error NotEnoughFund();
error NoContribution();

contract Pool is Ownable {
    uint256 public end;
    uint256 public goal;
    uint256 public totalCollected;
    mapping(address => uint256) public contributions;

    event Contribute(address indexed contributor, uint256 amount);

    constructor(uint256 _duration, uint256 _goal) Ownable(msg.sender) {
        end = block.timestamp + _duration;
        goal = _goal;
    }

    /// @notice contribute to the pool
    function contribute() external payable {
        if (block.timestamp >= end) {
            revert CollectIsFinished();
        }

        if (totalCollected >= goal) {
            revert GoalAlreadyReached();
        }

        if (msg.value == 0) {
            revert NotEnoughFund();
        }

        contributions[msg.sender] += msg.value;
        totalCollected += msg.value;

        emit Contribute(msg.sender, msg.value);
    }

    /// @notice Allow the owner to withdraw
    function withdraw() external onlyOwner {
        if (block.timestamp < end) {
            revert CollectNotFinished();
        }
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        if (!success) {
            revert FailedToSendEther();
        }
    }

    /// @notice allow user to get his contribution back
    function refund() external {
        if (block.timestamp < end) {
            revert CollectNotFinished();
        }

        if (totalCollected >= goal) {
            revert GoalAlreadyReached();
        }

        if (contributions[msg.sender] == 0) {
            revert NoContribution();
        }

        (bool success, ) = msg.sender.call{value: contributions[msg.sender]}(
            ""
        );

        if (!success) {
            revert FailedToSendEther();
        }
        totalCollected -= contributions[msg.sender];
        contributions[msg.sender] = 0;
    }
}

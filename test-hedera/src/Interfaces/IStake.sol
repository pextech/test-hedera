// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4;


interface IStake {

    struct Stake {
        uint256 startTime;
        uint256 duration;
        int64 reward;
        int64 penalty;
        uint256 balance;
        bool claimed;
        bool staked;
    }
    event Staked(address indexed owner, uint256 duration);
    event Unstaked(address indexed owner);
    event RewardClaimed(address indexed owner, int64 amount);

}
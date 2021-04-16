//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface DepositStrategy{
    function deposit(uint256[10] memory amounts) external returns(uint256);
    function withdraw(uint256[10] memory amounts) external returns(uint256);
    function setRewardCoin(address rewardCoin) external returns(bool);
}
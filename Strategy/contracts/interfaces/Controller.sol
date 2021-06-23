//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;


interface Controller{
    function stake(uint256 amount) external;
    function unstake(uint256 amount) external returns(uint256);
    function unstakeAll() external returns(uint256);
    function claimCRV() external;
    function stakedAmount() external view returns(uint256);
}

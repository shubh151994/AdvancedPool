//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;


interface Controller{
    function stake(uint256 amount) external;
    function unstake() external returns(uint256);
    function claimCRV() external;
}

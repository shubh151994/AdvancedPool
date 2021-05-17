//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;


interface Controller{
    function stake(uint256 amount) external;
    function updateGasUsed(uint256 gasUsed) external;
    function defaultGas() external returns(uint256);
}



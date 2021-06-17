//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;


interface Controller{
    function updateGasUsed(uint256 gasUsed, address adminAddress) external;
    function defaultGas() external returns(uint256);
}



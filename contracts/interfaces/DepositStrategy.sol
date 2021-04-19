//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface DepositStrategy{
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
}
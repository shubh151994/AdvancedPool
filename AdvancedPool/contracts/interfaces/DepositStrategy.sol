//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface DepositStrategy{
    function deposit(uint256 amount, uint256 minMintAmount) external;
    function withdraw(uint256 amount, uint256 maxBurnAmount) external;
    function withdrawAll(uint256 minAmount) external;
    function claimAndConvertCRV() external returns(uint256);
    function depositedAmount() external view returns(uint256);
}
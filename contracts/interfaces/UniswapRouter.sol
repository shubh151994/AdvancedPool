//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface  UniswapV2Router02  {
    function swapExactTokensForETH(uint, uint, address[] calldata, address, uint) external  returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory);
    function WETH() external pure returns (address); 
}
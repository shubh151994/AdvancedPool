//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface  UniswapV2Router  {
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory);
    function WETH() external pure returns (address); 
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to,uint deadline) external returns (uint[] memory amounts);
}
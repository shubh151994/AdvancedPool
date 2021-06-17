//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface CurvePool{
    function add_liquidity(uint256[3] calldata, uint256, bool) external returns(uint256);
    function remove_liquidity_imbalance(uint256[3] calldata, uint256, bool) external returns(uint256);
    function remove_liquidity_one_coin(uint256, int128, uint256, bool) external returns(uint256);
}


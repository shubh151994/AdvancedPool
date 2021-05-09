//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface CurvePool{
    function add_liquidity(uint256[3] calldata, uint256) external;
    function remove_liquidity_imbalance(uint256[3] calldata, uint256) external;
}


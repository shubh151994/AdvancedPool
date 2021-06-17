//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface Gauge {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function claimable_tokens(address) external view returns(uint256);
    function totalSupply() external view returns(uint256);
}

interface Minter {
    function mint(address) external;
}

interface FeeDistributor{
    function claim() external returns(uint256);
}

interface VotingEscrow{
    function create_lock(uint256,uint256) external ;
    function increase_amount(uint256) external;
    function increase_unlock_time(uint256) external;
    function withdraw() external;
    function totalSupply() external view returns(uint256);
}

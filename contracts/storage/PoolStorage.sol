
//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.0;
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol"; 
import "../interfaces/DepositStrategy.sol";


contract PoolStorageV1 {
    
    bytes32 constant ADVANCED_POOL_STORAGE_POSITION = keccak256("diamond.standard.advancedPool.storage");

    using SafeMath for uint256;
    struct PoolStorage {
        bool initialized;
    
        IERC20[] coins;
        IERC20 poolToken;
        
        DepositStrategy[] depositStrategies;
        
        uint256 DENOMINATOR;
        uint256 PRECISION;
    
        uint256 depositFees;
        uint256 withdrawFees;
        uint256 minLiquidity;
        uint256 maxLiquidity;
        uint256 adminGasUsed;
        uint256 totalStaked; //IN POOL TOKEN PRECISION
        
        mapping(uint256 => uint256[]) coinsPositionInStrategy;//strategyId => []
        mapping(uint256 => uint256) strategyForCoin;  //coinIndex => strategyId
        mapping(uint256 => uint256) poolBalances; //IN COIN PRECISION   //coinIndex => balance // total coins staked in this pool irrespective of the strategy
        mapping(uint256 => uint256) coinsDepositInStrategy; // IN COIN PRECISION    //coinIndex => amount
        mapping(uint256 => uint256) feesCollected;
        
        bool  locked;
        address  owner;
    }

    function poolStorage() internal pure returns (PoolStorage storage ps) {
        bytes32 position = ADVANCED_POOL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.0;
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol"; 
import "../interfaces/DepositStrategy.sol";
import "../interfaces/UniswapRouter.sol";


contract PoolStorageV1 {
    
    bytes32 constant ADVANCED_POOL_STORAGE_POSITION = keccak256("diamond.standard.advancedPool.storage");

    using SafeMath for uint256;
    struct PoolStorage {
        bool initialized;
    
        IERC20 coin;
        IERC20 poolToken;
        
        DepositStrategy depositStrategy;
        UniswapV2Router02 uniswapRouter;
        
        uint256 DENOMINATOR;

        uint256 depositFees;
        uint256 withdrawFees;
        uint256 minLiquidity;
        uint256 maxLiquidity;
        uint256 adminGasUsed;
        uint256 poolBalance; // coin Precision
        uint256 feesCollected;
        uint256 strategyDeposit;
        uint256 maxWithdrawalAllowed; //coin Precision
           
        bool  locked;
        address  owner;

        uint256 defaultGas;
        mapping(address => uint256) gasUsed;

    }

    function poolStorage() internal pure returns (PoolStorage storage ps) {
        bytes32 position = ADVANCED_POOL_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

}
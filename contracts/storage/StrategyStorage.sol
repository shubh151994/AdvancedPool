
//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.0;
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol"; 
import "../interfaces/TriPool.sol";
import "../interfaces/UniswapRouter.sol";


contract StrategyStorageV1 {
    
    bytes32 constant STRATGEY_STORAGE_POSITION = keccak256("diamond.standard.strategy.storage");

    using SafeMath for uint256;

    struct StrategyStorage {
        bool initialized;
    
        IERC20[3] coins;
        IERC20 crvToken;
        IERC20 poolToken;
    
        Pool poolAddress;
        
        Gauge gauge;
        
        Minter minter;
        
        VotingEscrow votingEscrow;
    
        FeeDistributor feeDistributor;
        
        UniswapV2Router uniswapRouter;
        
        address poolOwner;
        
        uint256 availableCRVToSwap;
        uint256 crvLockPercent;
        uint256 availableCRVToLock;
        uint256 rewardCoin;
    
        uint256 DENOMINATOR;

    }

    function strategyStorage() internal pure returns (StrategyStorage storage ss) {
        bytes32 position = STRATGEY_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }

}
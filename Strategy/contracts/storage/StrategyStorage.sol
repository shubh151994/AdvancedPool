
//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.0;
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol"; 
import "../interfaces/Controller.sol"; 
import "../interfaces/CurvePool.sol";
import "../interfaces/UniswapRouter.sol";


contract StrategyStorageV1 {
    
    bytes32 constant STRATGEY_STORAGE_POSITION = keccak256("diamond.standard.strategy.storage");

    using SafeMath for uint256;

    struct StrategyStorage {
        bool initialized;
    
        IERC20[3] coins;
        IERC20 crvToken;
        IERC20 curvePoolToken;
    
        CurvePool curvePool;
           
        UniswapV2Router uniswapRouter;

        Controller controller;
        
        address pool;
        uint256 coinIndex; 
    }

    function strategyStorage() internal pure returns (StrategyStorage storage ss) {
        bytes32 position = STRATGEY_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }

}
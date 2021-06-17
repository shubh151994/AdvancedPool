
//SPDX-License-Identifier: UNLICENSED
pragma solidity >0.6.0;
import "../libraries/SafeMath.sol";
import "../interfaces/IERC20.sol"; 
import "../interfaces/Curve.sol"; 
import "../interfaces/UniswapRouter.sol";


contract ControllerStorageV1 {
    
    bytes32 constant CONTROLLER_STORAGE_POSITION = keccak256("diamond.standard.controller.storage");

    using SafeMath for uint256;

    struct ControllerStorage {
        bool initialized;
    
        IERC20 crvToken;
        IERC20 adminFeeToken;

        mapping(address => Gauge) strategyGauges;
        mapping(address => IERC20) strategyLPTokens;
        mapping(address => bool) isStratgey;
        mapping(address => uint256) availableCRV;

        address[] depositStrategies;
        
        Minter minter;
        
        VotingEscrow votingEscrow;
    
        FeeDistributor feeDistributor;
        
        UniswapV2Router uniswapRouter;
        
        address controllerOwner;
        address controllerSuperOwner;
        
        uint256 crvLockPercent;
        uint256 DENOMINATOR;
        uint256 totalStrategies;
        uint256 availableCRVToLock;
        uint256 defaultGas;
        mapping(address => uint256) claimableGas;    
        mapping(address => uint256) ethReceived;
        mapping(address => bool) isPool;
    }

    function controllerStorage() internal pure returns (ControllerStorage storage cs) {
        bytes32 position = CONTROLLER_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
import "../storage/StrategyStorage.sol";
import "../libraries/SafeMath.sol";

contract TriPoolStrategy is StrategyStorageV1 {
    
    using SafeMath for uint256;
    
  
/****MODIFIERS****/
    modifier onlyPool(){
        StrategyStorage storage ss = strategyStorage();
        require(msg.sender == ss.pool, "Only pool can call!!");
        _;
    }
    
/****CONSTRUCTOR****/
    function initialize(
        CurvePool _curvePool,
        IERC20 _curvePoolToken,
        IERC20 _crvToken, 
        IERC20[3] memory _coins,
        UniswapV2Router _uniswapRouter,
        address _pool,
        Controller _controller,
        uint256 _coinIndex
    ) public{
        StrategyStorage storage ss = strategyStorage();
        require(!ss.initialized, 'Already initialized');
        ss.curvePool = _curvePool;
        ss.curvePoolToken = _curvePoolToken;
        ss.crvToken = _crvToken;
        ss.coins = _coins;
        ss.uniswapRouter = _uniswapRouter; 
        ss.pool = _pool;
        ss.controller = _controller;
        ss.coinIndex = _coinIndex;
        ss.initialized = true;
    }

/****POOL FUNCTIONS****/
    
    function deposit(uint256 amount) external onlyPool(){
        StrategyStorage storage ss = strategyStorage();
        uint256[3] memory amountArray;
        amountArray[ss.coinIndex] = amount;
        ss.coins[ss.coinIndex].transferFrom(msg.sender, address(this), amount);
        ss.coins[ss.coinIndex].approve(address(ss.curvePool), amount);
        ss.curvePool.add_liquidity(amountArray, 0);
        stakeOnController();
    }
    
    function withdraw(uint256 amount) external onlyPool(){
        StrategyStorage storage ss = strategyStorage();
        uint256[3] memory amountArray;
        amountArray[ss.coinIndex] = amount;
        uint256 unstakedAmount = unstakeFromController();
        ss.curvePool.remove_liquidity_imbalance(amountArray, unstakedAmount);
        ss.coins[ss.coinIndex].transfer(ss.pool, ss.coins[ss.coinIndex].balanceOf(address(this)));
        stakeOnController();
    }
    
/****INTERNAL FUNCTIONS****/

    function stakeOnController() internal {
        StrategyStorage storage ss = strategyStorage();
        uint256 stakeAmount = ss.curvePoolToken.balanceOf(address(this)) ;
        ss.curvePoolToken.approve(address(ss.controller), stakeAmount);
        ss.controller.stake(stakeAmount);  
    }

    function unstakeFromController() internal returns(uint256){
        StrategyStorage storage ss = strategyStorage();
        uint256 unstakedAmount = ss.controller.unstake();
        return unstakedAmount;
    }

/****OPEN FUNCTIONS****/    
    
    function claimAndConverCRV() external returns(uint256) {
        StrategyStorage storage ss = strategyStorage();
        ss.controller.claimCRV();
        uint256 claimedAmount = ss.crvToken.balanceOf(address(this));
        require(claimedAmount > 0, "Nothing to claim");
        ss.crvToken.approve(address(ss.uniswapRouter), claimedAmount);
        address[] memory path = new address[](3);
        path[0] = address(ss.crvToken);
        path[1] = ss.uniswapRouter.WETH();
        path[2] = address(ss.coins[ss.coinIndex]);
        
        ss.uniswapRouter.swapExactTokensForTokens(
            claimedAmount, 
            uint256(0), 
            path, 
            address(this), 
            block.timestamp + 1800
        );
        uint256 tokenReceived = ss.coins[ss.coinIndex].balanceOf(address(this));
        ss.coins[ss.coinIndex].transfer(ss.pool, tokenReceived);
        return tokenReceived;
    }
}
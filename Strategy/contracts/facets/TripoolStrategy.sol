// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
import "../storage/StrategyStorage.sol";
import "../libraries/SafeMath.sol";

contract TriPoolStrategy is StrategyStorageV1 {
    
    using SafeMath for uint256;
    
  
/****MODIFIERS****/
    modifier onlyPoolOnwer(){
        StrategyStorage storage ss = strategyStorage();
        require(ss.poolOwner == msg.sender, "Only poolOwner can call!!");
        _;
    }
    
/****CONSTRUCTOR****/
    function initialize(
        Pool _poolAddress,
        IERC20 _crvToken, 
        IERC20 _poolToken,
        IERC20[3] memory _coins,
        UniswapV2Router _uniswapRouter,
        address _poolOwner,
        Controller _controller,
        uint256 _coinIndex
    ) public{
        StrategyStorage storage ss = strategyStorage();
        require(!ss.initialized, 'Already initialized');
        ss.poolAddress = _poolAddress;
        ss.crvToken = _crvToken;
        ss.coins = _coins;
        ss.uniswapRouter = _uniswapRouter; 
        ss.poolOwner = _poolOwner;
        ss.poolToken = _poolToken;
        ss.controller = _controller;
        ss.coinIndex = _coinIndex;
        ss.initialized = true;
    }

/****POOLOWNER FUNCTIONS****/

    function updateOwner(address newOwner) external onlyPoolOnwer() returns(bool){
        StrategyStorage storage ss = strategyStorage();
        ss.poolOwner = newOwner;
        return true;
    } 
    
    function deposit(uint256 amount) external onlyPoolOnwer(){
        StrategyStorage storage ss = strategyStorage();
        uint256[3] memory amountArray;
        amountArray[ss.coinIndex] = amount;
        ss.coins[ss.coinIndex].transferFrom(msg.sender, address(this), amount);
        ss.coins[ss.coinIndex].approve(address(ss.poolAddress), amount);
        ss.poolAddress.add_liquidity(amountArray, 0);
       // stakeOnController();
    }
    
    function withdraw(uint256 amount) external onlyPoolOnwer(){
        StrategyStorage storage ss = strategyStorage();
        uint256[3] memory amountArray;
        amountArray[ss.coinIndex] = amount;
        uint256 unstakedAmount = unStakeFromController();
        ss.poolAddress.remove_liquidity_imbalance(amountArray, unstakedAmount);
        ss.coins[ss.coinIndex].transfer(ss.poolOwner, ss.coins[ss.coinIndex].balanceOf(address(this)));
        stakeOnController();
    }
    
/****INTERNAL FUNCTIONS****/

    function stakeOnController() internal {
        StrategyStorage storage ss = strategyStorage();
        uint256 stakeAmount = ss.poolToken.balanceOf(address(this)) ;
        ss.poolToken.approve(address(ss.controller), stakeAmount);
        ss.controller.stake(stakeAmount);  
    }
    //currently unstaking all
    function unStakeFromController() internal returns(uint256){
        StrategyStorage storage ss = strategyStorage();
        uint256 unstakedAmount = ss.controller.unStake();
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
        ss.coins[ss.coinIndex].transfer(ss.poolOwner, tokenReceived);
        return tokenReceived;
    }

}
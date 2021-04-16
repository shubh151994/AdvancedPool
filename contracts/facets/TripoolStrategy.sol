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
        Gauge _gauge, 
        Minter _minter, 
        IERC20 _crvToken, 
        IERC20 _poolToken,
        VotingEscrow _votingEscrow,
        FeeDistributor _feeDistributor,
        IERC20[3] memory _coins,
        UniswapV2Router _uniswapRouter,
        address _poolOwner,
        uint256 _crvLockPercent
        
    ) public{
        StrategyStorage storage ss = strategyStorage();
        require(!ss.initialized, 'Already initialized');
        ss.poolAddress = _poolAddress;
        ss.gauge = _gauge;
        ss.minter = _minter;
        ss.crvToken = _crvToken;
        ss.votingEscrow = _votingEscrow;
        ss.feeDistributor = _feeDistributor;
        ss.coins = _coins;
        ss.uniswapRouter = _uniswapRouter; 
        ss.poolOwner = _poolOwner;
        ss.poolToken = _poolToken;
        ss.crvLockPercent = _crvLockPercent;
        ss.DENOMINATOR = 10000;
        ss.initialized = true;
    }

/****POOLOWNER FUNCTIONS****/

    function transferOwnership(address newOwner) external onlyPoolOnwer() returns(bool){
        StrategyStorage storage ss = strategyStorage();
        ss.poolOwner = newOwner;
        return true;
    } 
    
    function setRewardCoin(IERC20 _rewardCoin) external onlyPoolOnwer() returns(bool){
        StrategyStorage storage ss = strategyStorage();
        for(uint256 i = 0; i < ss.coins.length; i++){
            if(ss.coins[i] == _rewardCoin){
                ss.rewardCoin = i;
                break;
            }
        }
        return true;
    }
    
    function deposit(uint256[10] memory amounts) external onlyPoolOnwer(){
        StrategyStorage storage ss = strategyStorage();
        uint256[3] memory updatedAmounts;
        for(uint8 i = 0 ; i < updatedAmounts.length; i++){
            updatedAmounts[i] = amounts[i];
            if(amounts[i] > 0){
                ss.coins[i].transferFrom(msg.sender, address(this), amounts[i]);
                // ss.coins[i].approve(address(ss.poolAddress), amounts[i]);
            }
        }
        ss.poolAddress.add_liquidity(updatedAmounts, 0);
        stake();
    }
    
    function withdraw(uint256[10] memory amounts) external onlyPoolOnwer(){
        StrategyStorage storage ss = strategyStorage();
        uint coinIndex;
        uint256[3] memory updatedAmounts;
        for(uint256 i = 0 ; i < updatedAmounts.length; i++){
            updatedAmounts[i] = amounts[i];
            if(updatedAmounts[i] > 0 ){
                coinIndex = i;
            }
        }
        uint256 unstakeAmount = ss.gauge.balanceOf(address(this));
        unStake(unstakeAmount);
        ss.poolAddress.remove_liquidity_imbalance(updatedAmounts,unstakeAmount);
        ss.coins[coinIndex].transfer(ss.poolOwner, ss.coins[coinIndex].balanceOf(address(this)));
        stake();
    }
    
/****INTERNAL FUNCTIONS****/

    function stake() internal {
        StrategyStorage storage ss = strategyStorage();
        uint256 stakeAmount = ss.poolToken.balanceOf(address(this)) ;
        // ss.poolToken.approve(address(ss.gauge), stakeAmount);
        ss.gauge.deposit(stakeAmount);  
    }
    
    function unStake(uint amount) internal{
        StrategyStorage storage ss = strategyStorage();
        ss.gauge.withdraw(amount);
    }

/****OPEN FUNCTIONS****/
 
    function claimCRV() external returns(uint256){
        StrategyStorage storage ss = strategyStorage();
        uint256 oldBalance = ss.crvToken.balanceOf(address(this));
        Minter(ss.minter).mint(address(ss.gauge));
        uint256 newBalance = ss.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 crvToLock = crvReceived * ss.crvLockPercent / ss.DENOMINATOR;
        ss.availableCRVToLock = ss.availableCRVToLock.add(crvToLock);
        ss.availableCRVToSwap = ss.availableCRVToSwap.add(crvReceived - crvToLock);
        return crvReceived;
    }
    
    function createLock(uint256 _value, uint256 _unlockTime) external{
        StrategyStorage storage ss = strategyStorage();
        require(_value <= ss.availableCRVToLock, 'Insufficient CRV' );
        ss.availableCRVToLock = ss.availableCRVToLock.sub(_value);
        // ss.crvToken.approve(address(ss.votingEscrow), _value);
        VotingEscrow(ss.votingEscrow).create_lock(_value, _unlockTime);
    } 
    
    function releaseLock() external{
        StrategyStorage storage ss = strategyStorage();
        uint256 oldBalance = ss.crvToken.balanceOf(address(this));
        VotingEscrow(ss.votingEscrow).withdraw();  
        uint256 newBalance = ss.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 crvToLock = crvReceived * ss.crvLockPercent / ss.DENOMINATOR;
        ss.availableCRVToLock = ss.availableCRVToLock.add(crvToLock);
        ss.availableCRVToSwap = ss.availableCRVToSwap.add(crvReceived - crvToLock);
    }
    
    function increaseLockAmount(uint256 _value) external {
        StrategyStorage storage ss = strategyStorage();
        require(_value <= ss.availableCRVToLock, 'Insufficient CRV' );
        ss.availableCRVToLock = ss.availableCRVToLock.sub(_value);
        // ss.crvToken.approve(address(ss.votingEscrow), _value);
        VotingEscrow(ss.votingEscrow).increase_amount(_value);
    }
   
    function claimAndConvert3CRV() external returns(uint256){
        StrategyStorage storage ss = strategyStorage();
        uint256 oldBalance = ss.poolToken.balanceOf(address(this));
        FeeDistributor(ss.feeDistributor).claim();
        uint256 newBalance = ss.poolToken.balanceOf(address(this));
        uint256 tokenReceived = newBalance - oldBalance;
        oldBalance = ss.coins[ss.rewardCoin].balanceOf(address(this));
        ss.poolAddress.remove_liquidity_one_coin(tokenReceived, int128(ss.rewardCoin), 0);
        newBalance = ss.coins[ss.rewardCoin].balanceOf(address(this));
        tokenReceived = newBalance - oldBalance;
        ss.coins[ss.rewardCoin].transfer(ss.poolOwner, tokenReceived);
        return tokenReceived;
    }
    
    function convertCRV(uint256 amount) external returns(uint256) {
        StrategyStorage storage ss = strategyStorage();
        require(amount <= ss.availableCRVToSwap, "insufficient token");
        ss.availableCRVToSwap = ss.availableCRVToSwap.sub(amount);
        uint256 oldBalance = ss.coins[ss.rewardCoin].balanceOf(address(this));
        // ss.crvToken.approve(address(ss.uniswapRouter), amount);
        address[] memory path = new address[](3);
        path[0] = address(ss.crvToken);
        path[1] = ss.uniswapRouter.WETH();
        path[2] = address(ss.coins[ss.rewardCoin]);
        
        ss.uniswapRouter.swapExactTokensForTokens(
            amount, 
            uint256(0), 
            path, 
            address(this), 
            block.timestamp + 1800
        );
        
        uint256 newBalance = ss.coins[ss.rewardCoin].balanceOf(address(this));
        uint256 tokenReceived = newBalance - oldBalance;
        ss.coins[ss.rewardCoin].transfer(ss.poolOwner, tokenReceived);
        return tokenReceived;
    }

}
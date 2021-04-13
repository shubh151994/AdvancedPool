// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
import './SafeMath.sol';
import './IERC20.sol';

interface DepositStrategy{
    function deposit(uint256[] memory amounts) external returns(uint256);
    function withdraw(uint256[] memory amounts) external returns(uint256);
    function setRewardCoin(address rewardCoin) external returns(bool);
}

contract AdvancePool {
    
/****VARIABLES*****/
    using SafeMath for uint256;
    
    IERC20[] public coins;
    IERC20 public poolToken;
    
    DepositStrategy[] public depositStrategies;
    
    uint256 public constant DENOMINATOR = 10000;
    uint256 public constant PRECISION = 10**18;
 
    
    uint256 public depositFees;
    uint256 public withdrawFees;
    uint256 public minLiquidity;
    uint256 public maxLiquidity;
    uint256 public adminGasUsed;
    uint256 public totalDeposits; //IN POOL TOKEN PRECISION
    
    mapping(uint256 => uint256[]) public coinsPositionInPool;
    mapping(uint256 => uint256) public poolsForCoin;
    mapping(uint256 => uint256) public poolBalances; //IN COIN PRECISION
    mapping(uint256 => uint256) public deposits; // IN COIN PRECISION
    mapping(uint256 => uint256) public feesCollected;
    
    bool public locked;
    
    address public owner;

/****MODIFIERS*****/
    
    modifier onlyOnwer(){
      require(owner == msg.sender, "Only admin can call!!");
      _;
    }
    modifier notLocked {
        require(!locked, "contract is locked");
        _;
    }
  
/****EVENTS****/ 
    event userDeposits(address user,uint amount);
    event userWithdrawal(address user,uint amount);
    event poolDeposit(address user, address pool, address coin, uint amount);
    event poolWithdrawal(address user, address pool, address coin, uint amount);
    
/****CONSTRUCTOR****/
    constructor(
        IERC20[] memory _coins,
        IERC20 _poolToken, 
        uint256 _minLiquidity, 
        uint256 _maxLiquidity, 
        uint256 _withdrawFees, 
        uint256 _depositFees,
        DepositStrategy[] memory _depositStrategies,
        uint256[] memory _poolsForCoin,
        uint256[][] memory _coinsPositionInPool
    ){
        
        owner = msg.sender;
        coins = _coins;
        poolToken = _poolToken;
        minLiquidity = _minLiquidity;
        maxLiquidity = _maxLiquidity;
        withdrawFees = _withdrawFees;
        depositFees = _depositFees;
        depositStrategies = _depositStrategies;
        for(uint256 i = 0; i < _poolsForCoin.length; i++){
            coinsPositionInPool[i] = _coinsPositionInPool[i];
            poolsForCoin[i] = _poolsForCoin[i];
        }
    }
    
/*****USERS FUNCTIONS****/
    // amount will be in coins precision
    function stake(uint256 coinIndex, uint256 amount) external notLocked() returns(uint256){
        poolBalances[coinIndex] = poolBalances[coinIndex].add(amount);
        totalDeposits = totalDeposits.add(amount.mul(PRECISION).div(coins[coinIndex].decimal()));
        uint256 mintAmount = calculatePoolTokens(amount, coinIndex);
        coins[coinIndex].transferFrom(msg.sender, address(this), amount);
        poolToken.mint(msg.sender, mintAmount);
        emit userDeposits(msg.sender,amount);
        return mintAmount;
    }
    //amount is the amount of LP token user want to burn
    function unStake(uint256 coinIndex, uint256 amount) external notLocked() returns(uint256){
        require(amount <= maxWithdrawalAllowed(coinIndex), "Dont have enough fund, Please try later!!");
        uint256 tokenAmount = calculateStableCoins(amount, coinIndex);
        poolBalances[coinIndex] = poolBalances[coinIndex].sub(tokenAmount);
        totalDeposits = totalDeposits.sub(tokenAmount.mul(PRECISION).div(coins[coinIndex].decimal()));
        coins[coinIndex].transfer(msg.sender, tokenAmount);
        poolToken.burn(msg.sender, amount);  
        emit userWithdrawal(msg.sender,amount);
        return tokenAmount;
    }
    
/****ADMIN FUNCTIONS*****/
    
    function updateLiquidityParam(uint256 _minLiquidity, uint256 _maxLiquidity) external onlyOnwer() notLocked() returns(bool){
        minLiquidity = _minLiquidity;
        maxLiquidity = _maxLiquidity;
        return true;
    }
    
    function updateFees(uint256 _depositFees, uint256 _withdrawFees) external onlyOnwer() notLocked() returns(bool){
        withdrawFees = _withdrawFees;
        depositFees = _depositFees;
        return true;
    }
    
    function changeLockStatus() external onlyOnwer() returns(bool){
        locked = !locked;
        return locked;
    }
    
    function transferOwnership(address newOwner) external onlyOnwer() returns(bool){
        owner = newOwner;
        return true;
    } 
    
    function setStrategyRewardCoin(uint256 poolIndex, uint256 coinIndex) external onlyOnwer() notLocked() returns(bool){
        depositStrategies[poolIndex].setRewardCoin(address(coins[coinIndex]));
        return true;
    }
    
/****POOL FUNCTIONS****/

    function addToPool(uint256 coinIndex) external notLocked() returns(uint256){
        uint256 amount = amountToDeposit(coinIndex);
        require(amount > 0 , "Nothing to deposit");
        deposits[coinIndex] = deposits[coinIndex].add(amount);
        uint256 poolIndex = poolsForCoin[coinIndex];
        uint256[] memory amounts;
        for(uint256 i = 0; i < coinsPositionInPool[poolIndex].length; i++ ){
            if(coinsPositionInPool[poolIndex][i] == coinIndex){
                amounts[coinsPositionInPool[poolIndex][i]] = amount;
            }
            else{
                amounts[coinsPositionInPool[poolIndex][i]] = 0;
            }
        }
        coins[coinIndex].approve(address(depositStrategies[poolIndex]), amount);
        depositStrategies[poolIndex].deposit(amounts);
        emit poolDeposit(msg.sender, address(depositStrategies[poolIndex]), address(coins[coinIndex]), amount);
        return amount;
        
    }
    
    function removeFromPool(uint256 coinIndex) external notLocked() returns(uint256){
        uint256 amount = amountToWithdraw(coinIndex);
        require(amount > 0 , "Nothing to withdraw");
        deposits[coinIndex] = deposits[coinIndex].sub(amount);
        uint256 poolIndex = poolsForCoin[coinIndex];
        uint256[] memory amounts;
        for(uint256 i = 0; i < coinsPositionInPool[poolIndex].length; i++ ){
            if(coinsPositionInPool[poolIndex][i] == coinIndex){
                amounts[coinsPositionInPool[poolIndex][i]] = amount;
            }
            else{
                amounts[coinsPositionInPool[poolIndex][i]] = 0;
            }
        }
        depositStrategies[poolIndex].withdraw(amounts);
        emit poolWithdrawal(msg.sender, address(depositStrategies[poolIndex]), address(coins[coinIndex]),  amount);
        return amount;
    }
    
/****OTHER FUNCTIONS****/
    
    //TOKEN MUST BE SENT IN COINS PRECISION
    function calculatePoolTokens(uint256 amountOfStableCoins, uint256 coinIndex) public view returns(uint256){
        amountOfStableCoins = amountOfStableCoins.mul(PRECISION).div(coins[coinIndex].decimal());
        return amountOfStableCoins * stableCoinPrice();
    }
    
    //Returning in pool token PRECISION
    function stableCoinPrice() public view returns(uint256){
        return (poolToken.totalSupply() == 0 || totalDeposits == 0) ? PRECISION : PRECISION * poolToken.totalSupply()/totalDeposits;
    }
    
       //RETURNING IN COIN PRECISION
    function calculateStableCoins(uint256 amountOfPoolToken, uint256 coinIndex) public view returns(uint256){
        amountOfPoolToken = amountOfPoolToken * poolTokenPrice();
        return amountOfPoolToken.mul(coins[coinIndex].decimal()).div(PRECISION);
    }
    
     function poolTokenPrice() public view returns(uint256){
        return (poolToken.totalSupply() == 0 || totalDeposits == 0) ? PRECISION : PRECISION * totalDeposits/poolToken.totalSupply();
    }
    
    
    // returning max number of pool token that can be burnt
    // if min is also less than actual
    function maxWithdrawalAllowed(uint256 coinIndex) public view returns(uint256){
        uint256 maxTokenAmount = poolBalances[coinIndex] * minLiquidity / (2 * DENOMINATOR);
        return calculatePoolTokens(maxTokenAmount, coinIndex);
    }
    
    function currentLiquidity(uint256 coinIndex) public view returns(uint256){
        return poolBalances[coinIndex] - deposits[coinIndex];
    }
   
    function idealAmount(uint256 coinIndex) public view returns(uint256){
        return poolBalances[coinIndex] * (minLiquidity + maxLiquidity) / (2 * DENOMINATOR);
    }
     
    function maxLiquidityAllowedInPool(uint256 coinIndex) public view returns(uint256){
        return poolBalances[coinIndex] * maxLiquidity / DENOMINATOR;
    }
    function amountToDeposit(uint256 coinIndex) public view returns(uint256){
        return currentLiquidity(coinIndex) <= maxLiquidityAllowedInPool(coinIndex) ? 0 : currentLiquidity(coinIndex) - idealAmount(coinIndex);
    }
    
      
    function minLiquidityAllowedInPool(uint256 coinIndex) public view returns(uint256){
        return poolBalances[coinIndex] * minLiquidity / DENOMINATOR;
    }
   
    function amountToWithdraw(uint256 coinIndex) public view returns(uint256){
        return currentLiquidity(coinIndex) > minLiquidityAllowedInPool(coinIndex) || deposits[coinIndex] == 0 || deposits[coinIndex] < idealAmount(coinIndex) - currentLiquidity(coinIndex) ? 0 : idealAmount(coinIndex) - currentLiquidity(coinIndex);
    }
    
}
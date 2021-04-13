// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import './SafeMath.sol';

import './IERC20.sol';

interface Pool{
   function deposit(uint256[] memory amounts) external returns(uint256);
}

contract AdvancePool {
    
    /****VARIABLES*****/
    using SafeMath for uint256;
    
    IERC20[] public coins;
    IERC20 public poolToken;
    
    uint256 public depositFees;
    uint256 public withdrawFees;
    uint256 public minLiquidity;
    uint256 public maxLiquidity;
    uint256 public adminGasUserd;
    uint256 public totalDeposits; //IN COINS PRECISION
  
    
    bool public locked;
    
    mapping(uint256 => uint256) public poolBalances; //IN POOL TOKEN PRECISION
    mapping(uint256 => uint256) public deposits;
    mapping(uint256 => uint256) public feesCollected;
    mapping(uint256 => uint256[]) public coinsPositionInPool;
    mapping(uint256 => uint256) public poolsForCoin;
    
    
    address public owner;
    address[] public depositStrategies;
    address[] public poolGauges;
    address public uniswapRouter;
    address public curveMinter;
    address public curveVotingEscrow;
    address public curveFeeDistributor;

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
    
    
    constructor(
        IERC20[] memory _coins,
        IERC20 _poolToken, 
        uint256 _minLiquidity, 
        uint256 _maxLiquidity, 
        uint256 _withdrawFees, 
        uint256 _depositFees,
        address[] memory _depositStrategies,
        uint256[] memory _poolsForCoin,
        uint256[][] memory _coinsPositionInPool,
    ){
        
        owner = msg.sender;
        coins = _coins;
        poolToken = _poolToken;
        minLiquidity = _minLiquidity;
        maxLiquidity = _maxLiquidity;
        withdrawFees = _withdrawFees;
        depositFees = _depositFees;
        depositStrategies = _depositStrategies;
        for(uint256 i = 0; i < _poolsForCoin; i++){
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
    
    // returning max number of pool token that can be burnt
    function maxWithdrawalAllowed(uint256 coinIndex) public view returns(uint256){
        uint256 maxTokenAmount = poolBalances[coinIndex] / 2;
        return calculatePoolTokens(maxTokenAmount, coinIndex);
    }
    
    //TOKEN MUST BE SENT IN COINS PRECISION
    function calculatePoolTokens(uint256 amountOfStableCoins, uint256 coinIndex) public view returns(uint256){
        amountOfStableCoins = amountOfStableCoins.mul(PRECISION).div(coins[coinIndex].decimal());
        return amountOfStableCoins * stableCoinPrice();
    }
    
    //RETURNING IN COIN PRECISION
    function calculateStableCoins(uint256 amountOfPoolToken, uint256 coinIndex) public view returns(uint256){
        amountOfPoolToken = amountOfPoolToken * poolTokenPrice();
        return amountOfPoolToken.mul(coins[coinIndex].decimal()).div(PRECISION);
    }
    
    /*****POOL FUNCTIONS****/
    
    function addToPool(uint256 coinIndex) external notLocked() returns(uint256){
        uint256 amount = amountToDeposit(coinIndex);
        require(amount > 0 , "Nothing to deposit");
        deposits[coinIndex] = deposits[coinIndex].add(amount);
        uint256 poolIndex = poolsForCoin[coinIndex];
        uint256[] amounts;
        for(uint256 i = 0; i < coinsPositionInPool[poolIndex].length; i++ ){
            if(coinsPositionInPool[poolIndex][i] == coinIndex){
                amounts[coinsPositionInPool[poolIndex][i]] = amount;
            }
            else{
                amounts[coinsPositionInPool[poolIndex][i]] = 0;
            }
        }
        IERC20(coins[coinIndex]).transferFrom(msg.sender, address(this), amount);
        IERC20(coins[coinIndex]).approve(depositStrategies[poolIndex], amount);
        Pool depositStrategy = Pool(depositStrategies[poolIndex]);
        depositStrategy.deposit(updatedAmounts);
        event poolDeposit(msg.sender, address pool, address coin, uint amount);
        return amount;
        
    }

    function removeFromPool(uint256 coinIndex) external notLocked() returns(uint256){
        uint256 amount = amountToWithdraw(coinIndex);
        require(amount > 0 , "Nothing to withdraw");
        deposits[coinIndex] = deposits[coinIndex].sub(amount);
        uint256 poolIndex = poolsForCoin[coinIndex];
        uint256[] amounts;
        for(uint256 i = 0; i < coinsPositionInPool[poolIndex].length; i++ ){
            if(coinsPositionInPool[poolIndex][i] == coinIndex){
                amounts[coinsPositionInPool[poolIndex][i]] = amount;
            }
            else{
                amounts[coinsPositionInPool[poolIndex][i]] = 0;
            }
        }
        Pool depositStrategy = Pool(depositStrategies[poolIndex]);
        depositStrategy.withdraw(updatedAmounts);
        emit poolWithdrawal(msg.sender, depositStrategies[poolIndex], coins[coinIndex],  amount);
        return amount;
    }
    
    /****UNISWAP FUNCTIONS****/
    
    function swapCRV(uint256 amount) external notLocked() returns(uint256){
        
    }
    
    function swapFees(uint256 coin) external notLocked() returns(uint256){
        
    }
    
    function swapTokens(address tokenA, address tokenB, uint256 amount) external notLocked() returns(uint256){
        
    }
    
    /****ADMIN FUNCTIONS****/
    
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
    
    function claimGasFees() external onlyOnwer() returns(uint256){
        
    }
    
    function transferOwnership(address newOwner) external onlyOnwer() returns(bool){
        owner = newOwner;
    } 
    
    /****OTHER FUNCTIONS****/
    
    function poolTokenPrice() public view returns(uint256){
        (poolToken.totalSupply() == 0 || totalDeposits == 0) ? PRECISION : totalDeposits/poolToken.totalSupply();
    }
    
    function stableCoinPrice() public view returns(uint256){
        (poolToken.totalSupply() == 0 || totalDeposits == 0) ? PRECISION : poolToken.totalSupply()/totalDeposits;
    }
     
    function checkValidAmounts(uint256[] memory amounts) internal view returns(bool){
        for(uint256 i = 0; i< amounts.length; i++){
            if(amounts[i] > 0 ){
                return true;
            }
        return false;
     }
    }
     
    //these all are returning in coin precision
    
     function checkValidAmounts(uint256[] memory amounts) internal view returns(bool){
        for(uint256 i = 0; i< amounts.length; i++){
            if(amounts[i] > 0 ){
                return true;
            }
        return false;
     }
     
    //these all are returning in coin precision
    function idealAmount(uint256 coinIndex) public view returns(uint256){
        }
        return poolBalances[coinIndex] * (minLiquidity + maxLiquidity) / (2 * DENOMINATOR);
    }
     
    function maxLiquidityAllowedInPool(uint256 coinIndex) public view returns(uint256){
        return poolBalances[coinIndex] * maxLiquidity / DENOMINATOR;
    }
     
    function minLiquidityAllowedInPool(uint256 coinIndex) public view returns(uint256){
        return poolBalances[coinIndex] * minLiquidity / DENOMINATOR;
    }
    function currentLiquidity(uint256 coinIndex) public view returns(uint256){
        return poolBalances[coinIndex] - deposits[coinIndex];
    }
    function amountToDeposit(uint256 coinIndex){
        return currentLiquidity(coinIndex) <= maxLiquidityAllowedInPool(coinIndex) ? 0 : currentLiquidity(coinIndex) - idealAmount(coinIndex);
    }
    function amountToWithdraw(uint256 coinIndex){
        return currentLiquidity(coinIndex) > minLiquidityAllowedInPool(coinIndex) || deposits[coinIndex] == 0 || deposits[coinIndex] < idealAmount(coinIndex) - currentLiquidity(coinIndex) ? 0 : idealAmount(coinIndex) - currentLiquidity(coinIndex);
    }
}
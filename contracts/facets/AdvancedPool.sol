// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
import "../storage/PoolStorage.sol";
contract AdvancedPool is PoolStorageV1 {
    
/****VARIABLES*****/
    using SafeMath for uint256;
   

/****MODIFIERS*****/
    
    modifier onlyOnwer(){
        PoolStorage storage ps = poolStorage();
        require(ps.owner == msg.sender, "Only admin can call!!");
        _;
    }
    modifier notLocked {
        PoolStorage storage ps = poolStorage();
        require(!ps.locked, "contract is locked");
        _;
    }
  
/****EVENTS****/ 
    event userDeposits(address user,uint amount);
    event userWithdrawal(address user,uint amount);
    event poolDeposit(address user, address pool, address coin, uint amount);
    event poolWithdrawal(address user, address pool, address coin, uint amount);
    
/****CONSTRUCTOR****/
    function initialize(
        IERC20[] memory _coins,
        IERC20 _poolToken, 
        uint256 _minLiquidity, 
        uint256 _maxLiquidity, 
        uint256 _withdrawFees, 
        uint256 _depositFees,
        DepositStrategy[] memory _depositStrategies,
        uint256[] memory _strategyForCoin,
        uint256[][] memory _coinsPositionInStrategy
    ) public {
        PoolStorage storage ps = poolStorage();
        require(!ps.initialized, 'Already initialized');
        ps.owner = msg.sender;
        ps.DENOMINATOR = 10000;
        ps.PRECISION = 10**18;
        ps.coins = _coins;
        ps.poolToken = _poolToken;
        ps.minLiquidity = _minLiquidity;
        ps.maxLiquidity = _maxLiquidity;
        ps.withdrawFees = _withdrawFees;
        ps.depositFees = _depositFees;
        ps.depositStrategies = _depositStrategies;
        ps.initialized = true;
        for(uint256 i = 0; i < _strategyForCoin.length; i++){
            ps.strategyForCoin[i] = _strategyForCoin[i];
        }
        for(uint256 i = 0; i < _coinsPositionInStrategy.length; i++){
            ps.coinsPositionInStrategy[i] = _coinsPositionInStrategy[i];
        }
    }
    
/*****USERS FUNCTIONS****/
    // amount will be in coins precision
    function stake(uint256 coinIndex, uint256 amount) external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 feeAmount = amount * ps.depositFees / ps.DENOMINATOR;
        ps.feesCollected[coinIndex] = ps.feesCollected[coinIndex] + feeAmount;
        ps.poolBalances[coinIndex] = ps.poolBalances[coinIndex].add(amount);
        uint256 mintAmount = calculatePoolTokens(amount - feeAmount, coinIndex);
        ps.totalStaked = ps.totalStaked.add(amount.mul(ps.PRECISION).div(10**ps.coins[coinIndex].decimals()));
        ps.coins[coinIndex].transferFrom(msg.sender, address(this), amount);
        ps.poolToken.mint(msg.sender, mintAmount);
        emit userDeposits(msg.sender,amount);
        return mintAmount;
    }
    
    //amount is the amount of LP token user want to burn
    function unStake(uint256 coinIndex, uint256 amount) external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        require(amount <= ps.poolToken.balanceOf(msg.sender), "You dont have enough pool token!!");
        require(amount <= maxBurnAllowed(coinIndex), "Dont have enough fund, Please try later!!");
        uint256 tokenAmount = calculateStableCoins(amount, coinIndex);
        uint256 feeAmount = tokenAmount * ps.withdrawFees/ ps.DENOMINATOR;
        ps.feesCollected[coinIndex] = ps.feesCollected[coinIndex] + feeAmount;
        ps.poolBalances[coinIndex] = ps.poolBalances[coinIndex].sub(tokenAmount - feeAmount);
        ps.totalStaked = ps.totalStaked.sub((tokenAmount - feeAmount).mul(ps.PRECISION).div(10**ps.coins[coinIndex].decimals()));
        ps.coins[coinIndex].transfer(msg.sender, tokenAmount - feeAmount);
        ps.poolToken.burn(msg.sender, amount);  
        emit userWithdrawal(msg.sender,amount);
        return tokenAmount - feeAmount;
    }
    
/****ADMIN FUNCTIONS*****/
    
    function updateLiquidityParam(uint256 _minLiquidity, uint256 _maxLiquidity) external onlyOnwer() notLocked() returns(bool){
        PoolStorage storage ps = poolStorage();
        ps.minLiquidity = _minLiquidity;
        ps.maxLiquidity = _maxLiquidity;
        return true;
    }
    
    function updateFees(uint256 _depositFees, uint256 _withdrawFees) external onlyOnwer() notLocked() returns(bool){
        PoolStorage storage ps = poolStorage();
        ps.withdrawFees = _withdrawFees;
        ps.depositFees = _depositFees;
        return true;
    }
    
    function changeLockStatus() external onlyOnwer() returns(bool){
        PoolStorage storage ps = poolStorage();
        ps.locked = !ps.locked;
        return ps.locked;
    }
    
    function updateOwner(address newOwner) external onlyOnwer() returns(bool){
        PoolStorage storage ps = poolStorage();
        ps.owner = newOwner;
        return true;
    } 
    
    function setStrategyRewardCoin(uint256 strategyIndex, uint256 coinIndex) external onlyOnwer() notLocked() returns(bool){
        PoolStorage storage ps = poolStorage();
        ps.depositStrategies[strategyIndex].setRewardCoin(address(ps.coins[coinIndex]));
        return true;
    }
    
/****POOL FUNCTIONS****/

    function addToStrategy(uint256 coinIndex) external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 amount = amountToDeposit(coinIndex);
        require(amount > 0 , "Nothing to deposit");
        ps.coinsDepositInStrategy[coinIndex] = ps.coinsDepositInStrategy[coinIndex].add(amount);
        uint256 strategyIndex = ps.strategyForCoin[coinIndex];
        uint256[10] memory amounts;
        for(uint256 i = 0; i < ps.coinsPositionInStrategy[strategyIndex].length; i++ ){
            if(ps.coinsPositionInStrategy[strategyIndex][i] == coinIndex){
                amounts[ps.coinsPositionInStrategy[strategyIndex][i]] = amount;
            }
            else{
                amounts[ps.coinsPositionInStrategy[strategyIndex][i]] = 0;
            }
        }
        ps.coins[coinIndex].approve(address(ps.depositStrategies[strategyIndex]), amount);
        ps.depositStrategies[strategyIndex].deposit(amounts);
        emit poolDeposit(msg.sender, address(ps.depositStrategies[strategyIndex]), address(ps.coins[coinIndex]), amount);
        return amount;
        
    }
    
    function removeFromPool(uint256 coinIndex) external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 amount = amountToWithdraw(coinIndex);
        require(amount > 0 , "Nothing to withdraw");
        ps.coinsDepositInStrategy[coinIndex] = ps.coinsDepositInStrategy[coinIndex].sub(amount);
        uint256 strategyIndex = ps.strategyForCoin[coinIndex];
        uint256[10] memory amounts;
        for(uint256 i = 0; i < ps.coinsPositionInStrategy[strategyIndex].length; i++ ){
            if(ps.coinsPositionInStrategy[strategyIndex][i] == coinIndex){
                amounts[ps.coinsPositionInStrategy[strategyIndex][i]] = amount;
            }
            else{
                amounts[ps.coinsPositionInStrategy[strategyIndex][i]] = 0;
            }
        }
        ps.depositStrategies[strategyIndex].withdraw(amounts);
        emit poolWithdrawal(msg.sender, address(ps.depositStrategies[strategyIndex]), address(ps.coins[coinIndex]),  amount);
        return amount;
    }
    
/****OTHER FUNCTIONS****/
    
    //TOKEN MUST BE SENT IN COINS PRECISION
    function calculatePoolTokens(uint256 amountOfStableCoins, uint256 coinIndex) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        amountOfStableCoins = amountOfStableCoins.mul(ps.PRECISION).div(10**ps.coins[coinIndex].decimals());
        return amountOfStableCoins * stableCoinPrice() / ps.PRECISION;
    }
    
    //Returning in pool token PRECISION
    function stableCoinPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || ps.totalStaked == 0) ? ps.PRECISION : ps.PRECISION * ps.poolToken.totalSupply()/ps.totalStaked;
    }
    
       //RETURNING IN COIN PRECISION
    function calculateStableCoins(uint256 amountOfPoolToken, uint256 coinIndex) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        amountOfPoolToken = amountOfPoolToken * poolTokenPrice() / ps.PRECISION;
        return amountOfPoolToken.mul(10 ** ps.coins[coinIndex].decimals()).div(ps.PRECISION);
    }
    
     function poolTokenPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || ps.totalStaked == 0) ? ps.PRECISION : ps.PRECISION * ps.totalStaked/ps.poolToken.totalSupply();
    }
    
    
    // returning max number of pool token that can be burnt
    // if min is also less than actual
    function maxBurnAllowed(uint256 coinIndex) public view returns(uint256){
        uint256 maxTokenAmount = minLiquidityToMaintainInPool(coinIndex)/2;
        return calculatePoolTokens(maxTokenAmount, coinIndex);
    }
    
    function feesCollected(uint256 coinIndex) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.feesCollected[coinIndex];
    }

    function currentLiquidity(uint256 coinIndex) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalances[coinIndex] - ps.coinsDepositInStrategy[coinIndex];
    }
   
    function idealAmount(uint256 coinIndex) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalances[coinIndex] * (ps.minLiquidity + ps.maxLiquidity) / (2 * ps.DENOMINATOR);
    }
     
    function maxLiquidityAllowedInPool(uint256 coinIndex) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalances[coinIndex] * ps.maxLiquidity / ps.DENOMINATOR;
    }

    function amountToDeposit(uint256 coinIndex) public view returns(uint256){
        return currentLiquidity(coinIndex) <= maxLiquidityAllowedInPool(coinIndex) ? 0 : currentLiquidity(coinIndex) - idealAmount(coinIndex);
    }
    
      
    function minLiquidityToMaintainInPool(uint256 coinIndex) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalances[coinIndex] * ps.minLiquidity / ps.DENOMINATOR;
    }
   
    function amountToWithdraw(uint256 coinIndex) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return currentLiquidity(coinIndex) > minLiquidityToMaintainInPool(coinIndex) || ps.coinsDepositInStrategy[coinIndex] == 0 || ps.coinsDepositInStrategy[coinIndex] < idealAmount(coinIndex) - currentLiquidity(coinIndex) ? 0 : idealAmount(coinIndex) - currentLiquidity(coinIndex);
    }
    
}
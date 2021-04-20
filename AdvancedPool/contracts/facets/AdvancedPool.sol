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
        IERC20 _coin,
        IERC20 _poolToken, 
        uint256 _minLiquidity, 
        uint256 _maxLiquidity, 
        uint256 _withdrawFees, 
        uint256 _depositFees,
        DepositStrategy _depositStrategy,
        uint256 _maxWithdrawalAllowed
    ) public {
        PoolStorage storage ps = poolStorage();
        require(!ps.initialized, 'Already initialized');
        ps.owner = msg.sender;
        ps.DENOMINATOR = 10000;
        ps.coin = _coin;
        ps.poolToken = _poolToken;
        ps.minLiquidity = _minLiquidity;
        ps.maxLiquidity = _maxLiquidity;
        ps.withdrawFees = _withdrawFees;
        ps.depositFees = _depositFees;
        ps.depositStrategy = _depositStrategy;
        ps.maxWithdrawalAllowed = _maxWithdrawalAllowed;
        ps.initialized = true;
    }
    
/*****USERS FUNCTIONS****/
    // amount will be in coins precision
    function stake(uint256 amount) external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 feeAmount = amount * ps.depositFees / ps.DENOMINATOR;
        ps.feesCollected = ps.feesCollected + feeAmount;
        ps.poolBalance = ps.poolBalance.add(amount);
        uint256 mintAmount = calculatePoolTokens(amount - feeAmount);
        ps.coin.transferFrom(msg.sender, address(this), amount);
        ps.poolToken.mint(msg.sender, mintAmount);
        emit userDeposits(msg.sender,amount);
        return mintAmount;
    }
    
    //amount is the amount of LP token user want to burn
    function unStake(uint256 amount) external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        require(amount <= ps.poolToken.balanceOf(msg.sender), "You dont have enough pool token!!");
        require(amount <= maxBurnAllowed(), "Dont have enough fund, Please try later!!");
        require(ps.poolBalance - ps.strategyDeposit - amount >= minLiquidityToMaintainInPool() , "Dont have enough fund, Please try later!!");
        uint256 tokenAmount = calculateStableCoins(amount);
        uint256 feeAmount = tokenAmount * ps.withdrawFees/ ps.DENOMINATOR;
        ps.feesCollected = ps.feesCollected + feeAmount;
        ps.poolBalance = ps.poolBalance.sub(tokenAmount - feeAmount);
        ps.coin.transfer(msg.sender, tokenAmount - feeAmount);
        ps.poolToken.burn(msg.sender, amount);  
        emit userWithdrawal(msg.sender,amount);
        return tokenAmount - feeAmount;
    }
    
/****ADMIN FUNCTIONS*****/
    
    function updateLiquidityParam(uint256 _minLiquidity, uint256 _maxLiquidity, uint256 _maxWithdrawalAllowed) external onlyOnwer() notLocked() returns(bool){
        PoolStorage storage ps = poolStorage();
        ps.minLiquidity = _minLiquidity;
        ps.maxLiquidity = _maxLiquidity;
        ps.maxWithdrawalAllowed = _maxWithdrawalAllowed;
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
    
/****POOL FUNCTIONS****/

    function addToStrategy() external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 amount = amountToDeposit();
        require(amount > 0 , "Nothing to deposit");
        ps.strategyDeposit = ps.strategyDeposit.add(amount);
        ps.coin.approve(address(ps.depositStrategy), amount);
        ps.depositStrategy.deposit(amount);
        emit poolDeposit(msg.sender, address(ps.depositStrategy), address(ps.coin), amount);
        return amount;
    }
    
    function removeFromPool() external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 amount = amountToWithdraw();
        require(amount > 0 , "Nothing to withdraw");
        ps.strategyDeposit = ps.strategyDeposit.sub(amount);
        ps.depositStrategy.withdraw(amount);
        emit poolWithdrawal(msg.sender, address(ps.depositStrategy), address(ps.coin),  amount);
        return amount;
    }
    
/****OTHER FUNCTIONS****/
    
    //TOKEN MUST BE SENT IN COINS PRECISION
    function calculatePoolTokens(uint256 amountOfStableCoins) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return amountOfStableCoins * stableCoinPrice() / ps.coin.decimals() ;
    }
    
    //Returning in pool token PRECISION
    function stableCoinPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || ps.poolBalance == 0) ? ps.coin.decimals() : ps.coin.decimals() * ps.poolToken.totalSupply()/ps.poolBalance;
    }
    
       //RETURNING IN COIN PRECISION
    function calculateStableCoins(uint256 amountOfPoolToken) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        amountOfPoolToken = amountOfPoolToken * poolTokenPrice() / ps.coin.decimals();
        return amountOfPoolToken;
    }
    
    function poolTokenPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || ps.poolBalance == 0) ? ps.poolToken.decimals() : ps.poolToken.decimals() * ps.poolBalance/ps.poolToken.totalSupply();
    }
    
    
    // returning max number of pool token that can be burnt
    // if min is also less than actual
    function maxBurnAllowed() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return calculatePoolTokens(ps.maxWithdrawalAllowed);
    }
    
    function feesCollected() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.feesCollected;
    }

    function currentLiquidity() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance - ps.strategyDeposit;
    }
   
    function idealAmount() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance * (ps.minLiquidity + ps.maxLiquidity) / (2 * ps.DENOMINATOR);
    }
     
    function maxLiquidityAllowedInPool() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance * ps.maxLiquidity / ps.DENOMINATOR;
    }

    function amountToDeposit() public view returns(uint256){
        return currentLiquidity() <= maxLiquidityAllowedInPool() ? 0 : currentLiquidity() - idealAmount();
    }
    
      
    function minLiquidityToMaintainInPool() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance * ps.minLiquidity / ps.DENOMINATOR;
    }
   
    function amountToWithdraw() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return currentLiquidity() > minLiquidityToMaintainInPool() || ps.strategyDeposit == 0 || ps.strategyDeposit < idealAmount() - currentLiquidity() ? 0 : idealAmount() - currentLiquidity();
    }
    
}
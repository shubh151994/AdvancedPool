// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;
library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
   
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }
  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
    
        return c;
    }
  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
interface DepositStrategy{
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AdvancedPool {
    
/****VARIABLES*****/
        using SafeMath for uint256;
        bool public initialized;
    
        IERC20 public coin;
        IERC20 public poolToken;
        
        DepositStrategy public depositStrategy;
        
        uint256 public DENOMINATOR;

        uint256 public depositFees;
        uint256 public withdrawFees;
        uint256 public minLiquidity;
        uint256 public maxLiquidity;
        uint256 public adminGasUsed;
        uint256 public poolBalance; // coin Precision
        uint256 public feesCollected;
        uint256 private strategyDeposit;
        uint256 public maxWithdrawalAllowed; //coin Precision
           
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
        
        require(!initialized, 'Already initialized');
        owner = msg.sender;
        DENOMINATOR = 10000;
        coin = _coin;
        poolToken = _poolToken;
        minLiquidity = _minLiquidity;
        maxLiquidity = _maxLiquidity;
        withdrawFees = _withdrawFees;
        depositFees = _depositFees;
        depositStrategy = _depositStrategy;
        maxWithdrawalAllowed = _maxWithdrawalAllowed;
        initialized = true;
    }
    
/*****USERS FUNCTIONS****/
    // amount will be in coins precision
    function stake(uint256 amount) external notLocked() returns(uint256){
        
        uint256 feeAmount = amount * depositFees / DENOMINATOR;
        feesCollected = feesCollected + feeAmount;
        uint256 mintAmount = calculatePoolTokens(amount - feeAmount);
        poolBalance = poolBalance.add(amount);
        coin.transferFrom(msg.sender, address(this), amount);
        poolToken.mint(msg.sender, mintAmount);
        emit userDeposits(msg.sender,amount);
        return mintAmount;
    }
    
    //amount is the amount of LP token user want to burn
    function unStake(uint256 amount) external notLocked() returns(uint256){
        
        require(amount <= poolToken.balanceOf(msg.sender), "You dont have enough pool token!!");
        require(amount <= maxBurnAllowed(), "Dont have enough fund, Please try later!!");
        require(poolBalance - strategyDeposit - amount >= minLiquidityToMaintainInPool() , "Dont have enough fund, Please try later!!");
        uint256 tokenAmount = calculateStableCoins(amount);
        uint256 feeAmount = tokenAmount * withdrawFees/ DENOMINATOR;
        feesCollected = feesCollected + feeAmount;
        poolBalance = poolBalance.sub(tokenAmount - feeAmount);
        coin.transfer(msg.sender, tokenAmount - feeAmount);
        poolToken.burn(msg.sender, amount);  
        emit userWithdrawal(msg.sender,amount);
        return tokenAmount - feeAmount;
    }
    
/****ADMIN FUNCTIONS*****/
    
    function updateLiquidityParam(uint256 _minLiquidity, uint256 _maxLiquidity, uint256 _maxWithdrawalAllowed) external onlyOnwer() notLocked() returns(bool){
        
        minLiquidity = _minLiquidity;
        maxLiquidity = _maxLiquidity;
        maxWithdrawalAllowed = _maxWithdrawalAllowed;
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
    
    function updateOwner(address newOwner) external onlyOnwer() returns(bool){
        
        owner = newOwner;
        return true;
    } 

    function updateStrategy(DepositStrategy _depositStrategy) external onlyOnwer() returns(bool){
        
        depositStrategy = _depositStrategy;
        return true;
    } 
    
/****POOL FUNCTIONS****/

    function addToStrategy() external notLocked() returns(uint256){
        
        uint256 amount = amountToDeposit();
        require(amount > 0 , "Nothing to deposit");
        strategyDeposit = strategyDeposit.add(amount);
        coin.approve(address(depositStrategy), amount);
        depositStrategy.deposit(amount);
        emit poolDeposit(msg.sender, address(depositStrategy), address(coin), amount);
        return amount;
    }
    
    function removeFromPool() external notLocked() returns(uint256){
        
        uint256 amount = amountToWithdraw();
        require(amount > 0 , "Nothing to withdraw");
        strategyDeposit = strategyDeposit.sub(amount);
        depositStrategy.withdraw(amount);
        emit poolWithdrawal(msg.sender, address(depositStrategy), address(coin),  amount);
        return amount;
    }
    
/****OTHER FUNCTIONS****/
    
    //TOKEN MUST BE SENT IN COINS PRECISION
    function calculatePoolTokens(uint256 amountOfStableCoins) public view returns(uint256){
        
        return amountOfStableCoins * stableCoinPrice() / 10 ** coin.decimals() ;
    }
    
    //Returning in pool token PRECISION
    function stableCoinPrice() public view returns(uint256){
        
        return (poolToken.totalSupply() == 0 || poolBalance == 0) ? 10 ** coin.decimals() : 10 ** coin.decimals() * poolToken.totalSupply()/poolBalance;
    }
    
       //RETURNING IN COIN PRECISION
    function calculateStableCoins(uint256 amountOfPoolToken) public view returns(uint256){
        
        amountOfPoolToken = amountOfPoolToken * poolTokenPrice() /10 **coin.decimals();
        return amountOfPoolToken;
    }
    
    function poolTokenPrice() public view returns(uint256){
        
        return (poolToken.totalSupply() == 0 || poolBalance == 0) ? 10**poolToken.decimals() : 10**poolToken.decimals() * poolBalance/poolToken.totalSupply();
    }
    
    // returning max number of pool token that can be burnt
    // if min is also less than actual
    function maxBurnAllowed() public view returns(uint256){
        
        return calculatePoolTokens(maxWithdrawalAllowed);
    }

    function currentLiquidity() public view returns(uint256){
        
        return poolBalance - strategyDeposit;
    }
   
    function idealAmount() public view returns(uint256){
        
        return poolBalance * (minLiquidity + maxLiquidity) / (2 * DENOMINATOR);
    }
     
    function maxLiquidityAllowedInPool() public view returns(uint256){
        
        return poolBalance * maxLiquidity / DENOMINATOR;
    }

    function amountToDeposit() public view returns(uint256){
        return currentLiquidity() <= maxLiquidityAllowedInPool() ? 0 : currentLiquidity() - idealAmount();
    }
    
      
    function minLiquidityToMaintainInPool() public view returns(uint256){
        
        return poolBalance * minLiquidity / DENOMINATOR;
    }
   
    function amountToWithdraw() public view returns(uint256){
        
        return currentLiquidity() > minLiquidityToMaintainInPool() || strategyDeposit == 0 || strategyDeposit < idealAmount() - currentLiquidity() ? 0 : idealAmount() - currentLiquidity();
    }

    function lockStatus() public view returns(bool){
        
        return locked;
    }

    function totalDeposit() public view returns(uint256){
        
        return poolBalance;
    }
    
}
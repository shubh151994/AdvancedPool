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

interface DepositStrategy{
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
}

contract AdvancedPool {
/****EVENTS****/
    event userDeposits(address user, uint256 amount);
    event userWithdrawal(address user,uint256 amount);
    event poolDeposit(address user, address pool, uint256 amount);
    event poolWithdrawal(address user, address pool, uint256 amount);

/****VARIABLES*****/
    using SafeMath for uint256;

    uint256 public depositFees;
    uint256 public withdrawFees;
    uint256 public minLiquidity;
    uint256 public maxLiquidity;
    uint256 public maxWithdrawalAllowed;
    uint256 public poolBalance;
    uint256 public feesCollected;
    uint256 private strategyDeposit;
    uint256 public DENOMINATOR;

    IERC20 public coin;
    IERC20 public poolToken;

    DepositStrategy public depositStrategy;

    bool public initialized;
    bool public locked;

    address public owner;
     

/****MODIFIERS****/
    modifier onlyOnwer(){
        require(owner == msg.sender, "Only Owner can call!!");
        _;
    }
    modifier notLocked {
        require(!locked, "Contract is locked!!");
        _;
    }

/****CONSTRUCTOR****/
    function initialize(
        IERC20 _coin,
        IERC20 _poolToken, 
        uint256 _minLiquidity, 
        uint256 _maxLiquidity, 
        uint256 _withdrawFees, 
        uint256 _depositFees,
        uint256 _maxWithdrawalAllowed,
        DepositStrategy _depositStrategy
    ) public {
        require(!initialized, 'Already initialized');
        owner = msg.sender;
        DENOMINATOR = 10000;
        coin = _coin;
        poolToken = _poolToken;
        minLiquidity = _minLiquidity;
        maxLiquidity = _maxLiquidity;
        maxWithdrawalAllowed = _maxWithdrawalAllowed;
        withdrawFees = _withdrawFees;
        depositFees = _depositFees;
        depositStrategy = _depositStrategy;
        initialized = true;
    }

/****OWNER FUNCTIONS****/
    function updateLiquidityParam(uint256 _minLiquidity, uint256 _maxLiquidity, uint256 _maxWithdrawalAllowed) external onlyOnwer() returns(bool){
        require(_minLiquidity > 0 &&  _maxLiquidity > 0 && _maxWithdrawalAllowed > 0, 'Parameters can be zero!!');
        require(_minLiquidity <  _maxLiquidity, 'Min liquidity cant be greater than max liquidity!!');
        require(_minLiquidity <  _maxLiquidity, 'Min liquidity cant be greater than max liquidity!!');
   
        minLiquidity = _minLiquidity;
        maxLiquidity = _maxLiquidity;
        maxWithdrawalAllowed = _maxWithdrawalAllowed;
        
        if(amountToDeposit() > 0){
            addToStrategy();
        }else if(amountToWithdraw() > 0){
            removeFromStrategy();
        }
        return true;
    }

    function updateFees(uint256 _depositFees, uint256 _withdrawFees) external onlyOnwer() returns(bool){    
        withdrawFees = _withdrawFees;
        depositFees = _depositFees;
        return true;
    }

    function changeLockStatus() external onlyOnwer() returns(bool){
        locked = !locked;
        return locked;
    }

    function updateOwner(address newOwner) external onlyOnwer() returns(bool){
        require(newOwner != address(0), 'Invalid Address');
        owner = newOwner;
        return true;
    } 

/****USERS FUNCTIONS****/

    function stake(uint256 amount) external notLocked() returns(uint256){
        require(amount > 0, 'Invalid Amount');
        uint256 feeAmount = amount * depositFees / DENOMINATOR;
        feesCollected = feesCollected + feeAmount;
        uint256 mintAmount = calculatePoolTokens(amount - feeAmount);
        poolBalance = poolBalance.add(amount);
        coin.transferFrom(msg.sender, address(this), amount);
        poolToken.mint(msg.sender, mintAmount);
        emit userDeposits(msg.sender, amount);
        return mintAmount;
    }
    //AMOUNT IS THE NUM OF POOL TOKEN USER WANT TO BURN
    function unStake(uint256 amount) external notLocked() returns(uint256){
        require(amount <= poolToken.balanceOf(msg.sender), "You dont have enough pool token!!");
        require(amount <= maxBurnAllowed(), "Dont have enough fund, Please try later!!");
        uint256 tokenAmount = calculateStableCoins(amount);
        uint256 feeAmount = tokenAmount * withdrawFees/DENOMINATOR;
        feesCollected = feesCollected + feeAmount;
        poolBalance = poolBalance.sub(tokenAmount - feeAmount);
        poolToken.burn(msg.sender, amount);  
        coin.transfer(msg.sender, tokenAmount - feeAmount);
        emit userWithdrawal(msg.sender,amount);
        return tokenAmount - feeAmount;
    }

/****HELPER/VIEW FUNCTIONS****/

    function calculatePoolTokens(uint256 amountOfStableCoins) public view returns(uint256){
        return amountOfStableCoins * stableCoinPrice() / 10**coin.decimals() ;
    }

    function stableCoinPrice() public view returns(uint256){
        return (poolToken.totalSupply() == 0 || poolBalance == 0) ? 10**coin.decimals() : 10 ** coin.decimals() * poolToken.totalSupply()/poolBalance;
    }

    function maxWithdrawal() public view returns(uint256){
        return minLiquidityToMaintainInPool()/2 < maxWithdrawalAllowed ? minLiquidityToMaintainInPool()/2 : maxWithdrawalAllowed;
    }

    function maxBurnAllowed() public view returns(uint256){
        return calculatePoolTokens(maxWithdrawal());
    }

    function minLiquidityToMaintainInPool() public view returns(uint256){
        return poolBalance * minLiquidity/DENOMINATOR;
    }

    function availableLiquidity() public view returns(uint256){
        return poolBalance - strategyDeposit;
    }

    function poolTokenPrice() public view returns(uint256){
        return (poolToken.totalSupply() == 0 || poolBalance == 0) ? 10**poolToken.decimals() : 10**poolToken.decimals() * poolBalance/poolToken.totalSupply();
    }

    function calculateStableCoins(uint256 amountOfPoolToken) public view returns(uint256){
        amountOfPoolToken = amountOfPoolToken * poolTokenPrice()/10**coin.decimals();
        return amountOfPoolToken;
    }

    function maxLiquidityAllowedInPool() public view returns(uint256){
        return poolBalance * maxLiquidity / DENOMINATOR;
    }

    function idealAmount() public view returns(uint256){
        return poolBalance * (minLiquidity + maxLiquidity) / (2 * DENOMINATOR);
    }

    function amountToDeposit() public view returns(uint256){
        return availableLiquidity() <= maxLiquidityAllowedInPool() ? 0 : availableLiquidity() - idealAmount();
    }

    function amountToWithdraw() public view returns(uint256){
        return availableLiquidity() >= minLiquidityToMaintainInPool() || strategyDeposit == 0 || strategyDeposit < idealAmount() - availableLiquidity() ? 0 : idealAmount() - availableLiquidity();
    }

    //HAVE TO ADD GETTER FOR DIAMOND
    

/****POOL FUNCTIONS****/

    function addToStrategy() public notLocked() returns(uint256){
        uint256 amount = amountToDeposit();
        require(amount > 0 , "Nothing to deposit");
        strategyDeposit = strategyDeposit.add(amount);
        coin.approve(address(depositStrategy), amount);
        depositStrategy.deposit(amount);
        emit poolDeposit(msg.sender, address(depositStrategy), amount);
        return amount;
    }

    function removeFromStrategy() public notLocked() returns(uint256){
        uint256 amount = amountToWithdraw();
        require(amount > 0 , "Nothing to withdraw!!");
        strategyDeposit = strategyDeposit.sub(amount);
        depositStrategy.withdraw(amount);
        emit poolWithdrawal(msg.sender, address(depositStrategy), amount);
        return amount;
    }

}
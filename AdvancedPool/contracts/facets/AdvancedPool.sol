// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../storage/PoolStorage.sol";

contract AdvancedPool is PoolStorageV1 {
    
/****VARIABLES*****/
    using SafeMath for uint256;
   

/****MODIFIERS*****/
    
    modifier onlyOwner(){
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
    event userDeposits(address user, uint256 amount);
    event userWithdrawal(address user,uint256 amount);
    event poolDeposit(address user, address pool, uint256 amount);
    event poolWithdrawal(address user, address pool, uint256 amount);
    

/****CONSTRUCTOR****/
    function initialize(
        IERC20 _coin,
        IERC20 _poolToken, 
        uint256 _minLiquidity, 
        uint256 _maxLiquidity, 
        uint256 _withdrawFees, 
        uint256 _depositFees,
        uint256 _maxWithdrawalAllowed,
        address _owner,
        DepositStrategy _depositStrategy,
        UniswapV2Router02 _uniswapRouter
    ) public {
        PoolStorage storage ps = poolStorage();
        require(!ps.initialized, 'Already initialized');
        ps.owner = _owner;
        ps.DENOMINATOR = 10000;
        ps.coin = _coin;
        ps.poolToken = _poolToken;
        ps.minLiquidity = _minLiquidity;
        ps.maxLiquidity = _maxLiquidity;
        ps.withdrawFees = _withdrawFees;
        ps.depositFees = _depositFees;
        ps.depositStrategy = _depositStrategy;
        ps.maxWithdrawalAllowed = _maxWithdrawalAllowed;
        ps.uniswapRouter = _uniswapRouter;
        ps.initialized = true;
    }
    

/*****USERS FUNCTIONS****/

    function stake(uint256 amount) external notLocked() returns(uint256){
        require(amount > 0, 'Invalid Amount');

        PoolStorage storage ps = poolStorage();
        uint256 feeAmount = amount * ps.depositFees / ps.DENOMINATOR;
        ps.feesCollected = ps.feesCollected + feeAmount;
        uint256 mintAmount = calculatePoolTokens(amount - feeAmount);
        ps.poolBalance = ps.poolBalance.add(amount - feeAmount);
        ps.coin.transferFrom(msg.sender, address(this), amount);
        ps.poolToken.mint(msg.sender, mintAmount);
        emit userDeposits(msg.sender,amount);
        return mintAmount;
    }

    function unstake(uint256 amount) external notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        require(amount <= maxWithdrawal(), "Dont have enough fund, Please try later!!");
       
        uint256 burnAmount = calculatePoolTokens(amount);
        require(burnAmount <= ps.poolToken.balanceOf(msg.sender), "You dont have enough pool token!!");

        uint256 feeAmount = amount * ps.withdrawFees/ ps.DENOMINATOR;
        ps.feesCollected = ps.feesCollected + feeAmount;
        ps.poolBalance = ps.poolBalance.sub(amount);

        ps.coin.transfer(msg.sender, amount - feeAmount);
        ps.poolToken.burn(msg.sender, burnAmount);  
        emit userWithdrawal(msg.sender, amount);
        return amount - feeAmount;
    }


/****POOL FUNCTIONS****/

    function addToStrategy() public notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].add((gasleft().add(ps.defaultGas)).mul(tx.gasprice));
        uint256 amount = amountToDeposit();
        require(amount > 0, "Nothing to deposit");
        ps.strategyDeposit = ps.strategyDeposit.add(amount);
        ps.coin.approve(address(ps.depositStrategy), amount);
        ps.depositStrategy.deposit(amount);
        emit poolDeposit(msg.sender, address(ps.depositStrategy), amount);
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].sub(gasleft().mul(tx.gasprice)); 
        return amount;
    }
    
    function removeFromStrategy() public notLocked() returns(uint256){
        PoolStorage storage ps = poolStorage();
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].add((gasleft().add(ps.defaultGas)).mul(tx.gasprice));
        uint256 amount = amountToWithdraw();
        require(amount > 0 , "Nothing to withdraw");
        ps.strategyDeposit = ps.strategyDeposit.sub(amount);
        ps.depositStrategy.withdraw(amount);
        emit poolWithdrawal(msg.sender, address(ps.depositStrategy), amount);
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].sub(gasleft().mul(tx.gasprice)); 
        return amount;
    }
    

/****ADMIN FUNCTIONS*****/
    
    function updateLiquidityParam(uint256 _minLiquidity, uint256 _maxLiquidity, uint256 _maxWithdrawalAllowed) external onlyOwner() returns(bool){
        require(_minLiquidity > 0 &&  _maxLiquidity > 0 && _maxWithdrawalAllowed > 0, 'Parameters cant be zero!!');
        require(_minLiquidity <  _maxLiquidity, 'Min liquidity cant be greater than max liquidity!!');
   
        PoolStorage storage ps = poolStorage();
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].add((gasleft().add(ps.defaultGas)).mul(tx.gasprice));
        ps.minLiquidity = _minLiquidity;
        ps.maxLiquidity = _maxLiquidity;
        ps.maxWithdrawalAllowed = _maxWithdrawalAllowed;
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].sub(gasleft().mul(tx.gasprice)); 
        if(amountToDeposit() > 0){
            addToStrategy();
        }else if(amountToWithdraw() > 0){
            removeFromStrategy();
        }
        return true;
    }
    
    function updateFees(uint256 _depositFees, uint256 _withdrawFees) external onlyOwner() returns(bool){
        PoolStorage storage ps = poolStorage();
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].add((gasleft().add(ps.defaultGas)).mul(tx.gasprice));
        ps.withdrawFees = _withdrawFees;
        ps.depositFees = _depositFees;
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].sub(gasleft().mul(tx.gasprice));
        return true;
    }
    
    function changeLockStatus() external onlyOwner() returns(bool){
        PoolStorage storage ps = poolStorage();
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].add((gasleft().add(ps.defaultGas)).mul(tx.gasprice));
        ps.locked = !ps.locked;
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].sub(gasleft().mul(tx.gasprice));
        return ps.locked;
    }
    
    function updateOwner(address newOwner) external onlyOwner() returns(bool){
        PoolStorage storage ps = poolStorage();
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].add((gasleft().add(ps.defaultGas)).mul(tx.gasprice));
        ps.owner = newOwner;
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].sub(gasleft().mul(tx.gasprice));
        return true;
    } 

    function getYield() public onlyOwner(){
        PoolStorage storage ps = poolStorage();
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].add((gasleft().add(ps.defaultGas)).mul(tx.gasprice));
        uint256 tokenReceived = ps.depositStrategy.claimAndConvertCRV();
        ps.poolBalance = ps.poolBalance.add(tokenReceived);
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].sub(gasleft().mul(tx.gasprice)); 
    }


/****OTHER FUNCTIONS****/

    function calculatePoolTokens(uint256 amountOfStableCoins) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (amountOfStableCoins * stableCoinPrice())/10**ps.coin.decimals() ;
    }

    function stableCoinPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || ps.poolBalance == 0) ? 10**ps.coin.decimals() : ((10**ps.coin.decimals()) * ps.poolToken.totalSupply())/ps.poolBalance;
    }
    
    function calculateStableCoins(uint256 amountOfPoolToken) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        amountOfPoolToken = (amountOfPoolToken*poolTokenPrice())/(10**ps.poolToken.decimals());
        return amountOfPoolToken;
    }

    function poolTokenPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || ps.poolBalance == 0) ? 10**ps.poolToken.decimals() : ((10**ps.poolToken.decimals())*ps.poolBalance)/ps.poolToken.totalSupply();
    }
    
    function maxWithdrawal() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return minLiquidityToMaintainInPool()/2 < ps.maxWithdrawalAllowed ? minLiquidityToMaintainInPool()/2 : ps.maxWithdrawalAllowed;
    }

    function currentLiquidity() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance - ps.strategyDeposit;
    }
   
    function idealAmount() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolBalance * (ps.minLiquidity.add(ps.maxLiquidity))) / (2 * ps.DENOMINATOR);
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

    function lockStatus() public view returns(bool){
        PoolStorage storage ps = poolStorage();
        return ps.locked;
    }

    function totalDeposit() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance;
    }

    function strategyDeposit() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.strategyDeposit;
    }
       
    function feesCollected() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.feesCollected;
    }

    function currentFees() public view returns(uint256, uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.depositFees, ps.withdrawFees);
    }

    function claimGasFee() public{
        PoolStorage storage ps = poolStorage();
        uint256 gasAtStart = (gasleft().add(ps.defaultGas)).mul(tx.gasprice);
        uint256 claimableAmount = ps.gasUsed[msg.sender];
        require(claimableAmount > 0, "Nothing to claim");
        require(address(this).balance >= claimableAmount, "Dont have enough fund, Try later!!");
        ps.gasUsed[msg.sender] = 0;
        msg.sender.transfer(claimableAmount);
        uint256 gasAtEnd = gasleft().mul(tx.gasprice);
        ps.gasUsed[msg.sender] = gasAtStart - gasAtEnd;
    }

    function convertFeesToETH() external {
        PoolStorage storage ps = poolStorage();
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].add((gasleft().add(ps.defaultGas)).mul(tx.gasprice));
        address[] memory path = new address[](2);
        uint256 amountToSwap = ps.feesCollected;
        ps.feesCollected = 0;
        ps.coin.approve(address(ps.uniswapRouter), amountToSwap);
        path[0] = address(ps.coin);
        path[1] = ps.uniswapRouter.WETH();
        uint256 amountOutMin = 0;
        ps.uniswapRouter.swapExactTokensForETH(amountToSwap, amountOutMin, path, address(this), block.timestamp + 100000);
        ps.gasUsed[msg.sender] = ps.gasUsed[msg.sender].sub(gasleft().mul(tx.gasprice));
    }

    receive() external payable {
    }
}
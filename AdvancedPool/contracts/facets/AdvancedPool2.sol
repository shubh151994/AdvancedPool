// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../storage/PoolStorage.sol";

contract AdvancedPool2 is PoolStorageV1 {
    
/****VARIABLES*****/
    using SafeMath for uint256;
   

/****MODIFIERS*****/
    
    modifier onlyOwner(){
        PoolStorage storage ps = poolStorage();
        require(ps.owner == msg.sender || ps.superOwner == msg.sender, "Only admin can call!!");
        _;
    }
    modifier onlySuperOwner(){
        PoolStorage storage ps = poolStorage();
        require(ps.superOwner == msg.sender, "Only super admin can call!!");
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
        require(amount <= ps.coin.balanceOf(address(this)), "Dont have enough fund, Please try later!!!");
        
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

/****ADMIN FUNCTIONS*****/

    function addToStrategy(uint256 minMintAmount) public notLocked() onlyOwner() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        uint256 amount = amountToDeposit();
        require(amount > 0, "Nothing to deposit");
        ps.poolBalance = ps.poolBalance - amount;
        ps.coin.approve(address(ps.depositStrategy), 0);
        ps.coin.approve(address(ps.depositStrategy), amount);
        ps.depositStrategy.deposit(amount, minMintAmount);
        emit poolDeposit(msg.sender, address(ps.depositStrategy), amount);
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
        return amount;
    }
    
    function removeFromStrategy(uint256 maxBurnAmount) public notLocked() onlyOwner() returns(uint256){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        uint256 amount = amountToWithdraw();
        require(amount > 0 , "Nothing to withdraw");
        ps.poolBalance = ps.poolBalance + amount;
        ps.depositStrategy.withdraw(amount, maxBurnAmount);
        emit poolWithdrawal(msg.sender, address(ps.depositStrategy), amount);
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender); 
        return amount;
    }

    function removeAllFromStrategy(uint256 minAmount) public notLocked() onlySuperOwner(){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        require(strategyDeposit() > 0 , "Nothing to withdraw");
        uint256 oldBalance = ps.coin.balanceOf(address(this));
        ps.depositStrategy.withdrawAll(minAmount);
        uint256 newBalance = ps.coin.balanceOf(address(this));
        uint256 tokenReceived = newBalance - oldBalance;
        ps.poolBalance = ps.poolBalance + tokenReceived;
        emit poolWithdrawal(msg.sender, address(ps.depositStrategy), tokenReceived);
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender); 
    }
    
    function updateLiquidityParam(uint256 _minLiquidity, uint256 _maxLiquidity, uint256 _maxWithdrawalAllowed, uint256 maxBurnOrMinMint) external onlySuperOwner() returns(bool){
        require(_minLiquidity > 0 &&  _maxLiquidity > 0 && _maxWithdrawalAllowed > 0, 'Parameters cant be zero!!');
        require(_minLiquidity <  _maxLiquidity, 'Min liquidity cant be greater than max liquidity!!');
   
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);   
        ps.minLiquidity = _minLiquidity;
        ps.maxLiquidity = _maxLiquidity;
        ps.maxWithdrawalAllowed = _maxWithdrawalAllowed;
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
        if(amountToDeposit() > 0){
            addToStrategy(maxBurnOrMinMint);
        }else if(amountToWithdraw() > 0){
            removeFromStrategy(maxBurnOrMinMint);
        }
        return true;
    }
    
    function updateStrategy(DepositStrategy _newStrategy) public onlySuperOwner(){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        require(strategyDeposit() == 0, 'Withdraw all funds first');
        ps.depositStrategy = _newStrategy;
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
    }

/****OTHER FUNCTIONS****/

    function calculatePoolTokens(uint256 amountOfStableCoins) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (amountOfStableCoins * stableCoinPrice())/10**ps.coin.decimals() ;
    }

    function stableCoinPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || totalDeposit() == 0) ? 10**ps.coin.decimals() : ((10**ps.coin.decimals()) * ps.poolToken.totalSupply())/totalDeposit();
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
        return ps.poolBalance;
    }
   
    function idealAmount() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (totalDeposit() * (ps.minLiquidity.add(ps.maxLiquidity))) / (2 * ps.DENOMINATOR);
    }
     
    function maxLiquidityAllowedInPool() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return totalDeposit() * ps.maxLiquidity / ps.DENOMINATOR;
    }

    function amountToDeposit() public view returns(uint256){
        return currentLiquidity() <= maxLiquidityAllowedInPool() ? 0 : currentLiquidity() - idealAmount();
    }
    
    function minLiquidityToMaintainInPool() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance * ps.minLiquidity / ps.DENOMINATOR;
    }
   
    function amountToWithdraw() public view returns(uint256){
        return currentLiquidity() > minLiquidityToMaintainInPool() || strategyDeposit() == 0 || strategyDeposit() < idealAmount() - currentLiquidity() ? 0 : idealAmount() - currentLiquidity();
    }

    function totalDeposit() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance + strategyDeposit();
    }

    function strategyDeposit() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.depositStrategy.depositedAmount();
    }

}
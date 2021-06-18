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
    

/****CONSTRUCTOR****/
    function initialize(
        IERC20 _coin,
        IERC20 _poolToken, 
        uint256 _minLiquidity, 
        uint256 _maxLiquidity, 
        uint256 _withdrawFees, 
        uint256 _depositFees,
        uint256 _maxWithdrawalAllowed,
        address[] memory _owners,
        DepositStrategy _depositStrategy,
        UniswapV2Router02 _uniswapRouter,
        Controller _controller
    ) public {
        PoolStorage storage ps = poolStorage();
        require(!ps.initialized, 'Already initialized');
        ps.owner = _owners[0];
        ps.superOwner = _owners[1];
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
        ps.controller = _controller;
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
        ps.strategyDeposit = ps.strategyDeposit.add(amount);
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
        ps.strategyDeposit = ps.strategyDeposit.sub(amount);
        ps.depositStrategy.withdraw(amount, maxBurnAmount);
        emit poolWithdrawal(msg.sender, address(ps.depositStrategy), amount);
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender); 
        return amount;
    }

    function removeAllFromStrategy(uint256 minAmount) public notLocked() onlySuperOwner(){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        require(ps.strategyDeposit > 0 , "Nothing to withdraw");
        ps.strategyDeposit = 0;
        ps.depositStrategy.withdrawAll(minAmount);
        emit poolWithdrawal(msg.sender, address(ps.depositStrategy), ps.coin.balanceOf(address(this)));
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
    
    function updateFees(uint256 _depositFees, uint256 _withdrawFees) external onlySuperOwner() returns(bool){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        ps.withdrawFees = _withdrawFees;
        ps.depositFees = _depositFees;
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
        return true;
    }
    
    function changeLockStatus() external onlyOwner() returns(bool){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        ps.locked = !ps.locked;
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
        return ps.locked;
    }
    
    function updateOwners(address newOwner, address newSuperOwner) external onlySuperOwner() returns(bool){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        ps.owner = newOwner;
        ps.superOwner = newSuperOwner;
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
        return true;
    } 

    function getYield() public onlyOwner(){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        uint256 tokenReceived = ps.depositStrategy.claimAndConvertCRV();
        ps.poolBalance = ps.poolBalance.add(tokenReceived);
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
    }
    
    
    function updateStrategy(DepositStrategy _newStrategy) public onlySuperOwner(){
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        require(ps.strategyDeposit == 0, 'Withdraw all funds first');
        ps.depositStrategy = _newStrategy;
        uint256 gasUsed = gasAtBegining.sub(gasleft().mul(tx.gasprice)); 
        ps.controller.updateGasUsed(gasUsed, msg.sender);
    }

    function convertFeesToETH() external onlyOwner() {
        PoolStorage storage ps = poolStorage();
        uint256 gasAtBegining = (gasleft().add(ps.controller.defaultGas())).mul(tx.gasprice);
        address[] memory path = new address[](2);
        uint256 amountToSwap = ps.feesCollected;
        ps.feesCollected = 0;
        ps.coin.approve(address(ps.uniswapRouter), 0);
        ps.coin.approve(address(ps.uniswapRouter), amountToSwap);
        path[0] = address(ps.coin);
        path[1] = ps.uniswapRouter.WETH();
        uint256 amountOutMin = 0;
        ps.uniswapRouter.swapExactTokensForETH(amountToSwap, amountOutMin, path, address(ps.controller), block.timestamp + 100000);
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

    function currentLiquidityParams() public view returns(uint256, uint256, uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.minLiquidity, ps.maxLiquidity, ps.maxWithdrawalAllowed);
    }

    function owners() public view returns(address, address){
        PoolStorage storage ps = poolStorage();
        return (ps.owner, ps.superOwner);
    }

    receive() external payable {
    }
}
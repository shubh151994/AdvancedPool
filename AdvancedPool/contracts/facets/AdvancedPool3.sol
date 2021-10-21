// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "../storage/PoolStorage.sol";

contract AdvancedPool3 is PoolStorageV1 {
    
/****VARIABLES*****/
    using SafeMath for uint256;
   

/****MODIFIERS*****/
    modifier notLocked {
        PoolStorage storage ps = poolStorage();
        require(!ps.locked, "contract is locked");
        _;
    }
  
/****EVENTS****/ 
    event userWithdrawal(address user,uint256 amount);

/*****USERS FUNCTIONS****/

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
    
/****OTHER FUNCTIONS****/

    function calculatePoolTokens(uint256 amountOfStableCoins) public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (amountOfStableCoins * stableCoinPrice())/10**ps.coin.decimals() ;
    }

    function stableCoinPrice() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return (ps.poolToken.totalSupply() == 0 || totalDeposit() == 0) ? 10**ps.coin.decimals() : ((10**ps.coin.decimals()) * ps.poolToken.totalSupply())/totalDeposit();
    }
    
    function maxWithdrawal() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return currentLiquidity() - minLiquidityToMaintainInPool()/2 < ps.maxWithdrawalAllowed ? currentLiquidity() - minLiquidityToMaintainInPool()/2 : ps.maxWithdrawalAllowed;
    }

    function currentLiquidity() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return ps.poolBalance;
    }
    
    function minLiquidityToMaintainInPool() public view returns(uint256){
        PoolStorage storage ps = poolStorage();
        return totalDeposit() * ps.minLiquidity / ps.DENOMINATOR;
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
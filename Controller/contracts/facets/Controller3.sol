// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
import "../storage/ControllerStorage.sol";
import "../libraries/SafeMath.sol";

contract Controller3 is ControllerStorageV1 {
    
    using SafeMath for uint256;
    
  
/****MODIFIERS****/
    modifier onlyOwner(){
        ControllerStorage storage cs = controllerStorage();
        require(cs.controllerOwner == msg.sender || cs.controllerSuperOwner == msg.sender, "Only admins can call!!");
        _;
    }

    modifier onlyStrategy(){
        ControllerStorage storage cs = controllerStorage();
        require(cs.isStratgey[msg.sender], "Only strategy can call!!");
        _;
    }


/****STRATEGY FUNCTIONS****/

    function stake(uint256 amount) external onlyStrategy(){
        ControllerStorage storage cs = controllerStorage();
        cs.strategyLPTokens[msg.sender].transferFrom(msg.sender, address(this), amount);
        cs.strategyLPTokens[msg.sender].approve(address(cs.strategyGauges[msg.sender]), 0);
        cs.strategyLPTokens[msg.sender].approve(address(cs.strategyGauges[msg.sender]), amount);
        cs.strategyDeposits[msg.sender] = cs.strategyDeposits[msg.sender] + amount;
        cs.strategyGauges[msg.sender].deposit(amount);  
    }
    
    function unstake(uint256 amount) external onlyStrategy() returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        cs.strategyDeposits[msg.sender] = cs.strategyDeposits[msg.sender] - amount;
        cs.strategyGauges[msg.sender].withdraw(amount);
        cs.strategyLPTokens[msg.sender].transfer(msg.sender, amount);
        return amount;
    }

    function unstakeAll() external onlyStrategy() returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        uint256 unstakedAmount =  cs.strategyDeposits[msg.sender];
        cs.strategyDeposits[msg.sender] = 0;
        cs.strategyGauges[msg.sender].withdraw(unstakedAmount);
        cs.strategyLPTokens[msg.sender].transfer(msg.sender, unstakedAmount);
        return unstakedAmount;
    }

    function claimCRVAdmin(address gauge) external onlyOwner() returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        uint256 oldBalance = cs.crvToken.balanceOf(address(this));
        Minter(cs.minter).mint(gauge);
        uint256 newBalance = cs.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 crvToLock = crvReceived * cs.crvLockPercent / cs.DENOMINATOR;
        cs.availableCRVToLock = cs.availableCRVToLock + crvToLock;
        uint256 crvToSend = crvReceived - crvToLock;
        uint256 totalStakedLPToken = Gauge(gauge).balanceOf(address(this));
        uint256 distributedCRV = 0;
        for(uint8 i = 0; i < cs.depositStrategies.length; i++){
            if(address(cs.strategyGauges[cs.depositStrategies[i]]) == gauge){
                cs.claimableCRV[cs.depositStrategies[i]] = cs.claimableCRV[cs.depositStrategies[i]] + cs.strategyDeposits[cs.depositStrategies[i]] * crvToSend / totalStakedLPToken;
                distributedCRV = distributedCRV + cs.strategyDeposits[cs.depositStrategies[i]] * crvToSend / totalStakedLPToken;
            }
        }
        if(crvToSend > distributedCRV){
             cs.availableCRVToLock = cs.availableCRVToLock + crvToSend - distributedCRV;
        }
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
        return crvReceived - crvToLock;
    }

    function claimCRV() external onlyStrategy() returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        uint256 crvToSend = cs.claimableCRV[msg.sender];
        cs.claimableCRV[msg.sender] = 0;
        cs.crvToken.transfer(msg.sender, crvToSend);
        return crvToSend;
    }

    function stakedAmount() public onlyStrategy() view returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        return cs.strategyDeposits[msg.sender];
    }

    function claimableCRVTokens(address strategy) public view returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        return cs.claimableCRV[strategy];
    }

    function fixOldValues(address strategy) public onlyOwner(){
        ControllerStorage storage cs = controllerStorage();
        cs.strategyDeposits[strategy] = cs.strategyGauges[strategy].balanceOf(address(this));
    }

}
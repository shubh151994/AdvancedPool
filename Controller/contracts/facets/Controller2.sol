// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
import "../storage/ControllerStorage.sol";
import "../libraries/SafeMath.sol";

contract Controller2 is ControllerStorageV1 {
    
    using SafeMath for uint256;

    modifier onlyStrategy(){
        ControllerStorage storage cs = controllerStorage();
        require(cs.isStratgey[msg.sender], "Only strategy can call!!");
        _;
    }
    
    function stakedAmount() public onlyStrategy() view returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        return cs.strategyGauges[msg.sender].balanceOf(address(this));
    }
}
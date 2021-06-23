// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
import "../storage/StrategyStorage.sol";
import "../libraries/SafeMath.sol";

contract Strategy2 is StrategyStorageV1 {
    
    using SafeMath for uint256;

/****VIEW FUNTION****/
    function depositedAmount() public view returns(uint256){
        StrategyStorage storage ss = strategyStorage();
        uint256 stakedAmount = ss.controller.stakedAmount();
        return (curveLPTokenPrice() * stakedAmount / (10**ss.curvePoolToken.decimals())) / (10**(ss.curvePoolToken.decimals() - ss.coins[ss.coinIndex].decimals()));
    }

    function curveLPTokenPrice() public view returns(uint256){
        StrategyStorage storage ss = strategyStorage();
        return ss.curvePool.get_virtual_price();
    }
}
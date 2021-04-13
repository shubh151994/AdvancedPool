// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

import './IERC20.sol';
import './SafeMath.sol';
interface Pool{
    function add_liquidity(uint256[3] calldata, uint256) external;
    function remove_liquidity_imbalance(uint256[3] calldata, uint256) external;
    function calc_token_amount(uint256[3] memory, bool) external returns(uint256);
}

interface Gauge {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
    function claimable_tokens(address) external view returns(uint256);
    function totalSupply() external view returns(uint256);
}

interface Minter {
    function mint(address) external;
}

interface FeeDistributor{
    function claim() external;
}

interface VotingEscrow{
    function create_lock(uint256,uint256) external ;
    function increase_amount(uint256)  external;
    function increase_unlock_time(uint256)  external;
    function withdraw()  external;
    function totalSupply()  external view returns(uint256);
}

interface  UniswapV2Router  {
    function swapExactTokensForETH(uint, uint, address[] calldata, address, uint) external  returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory);
    function WETH() external pure returns (address); 
}

contract TriPoolStrategy {
    
/****VARIABLES****/
    using SafeMath for uint256;
    
    IERC20[3] public coins;
    IERC20 public crvToken;
    IERC20 public poolToken;
   
    Pool public poolAddress;
    
    Gauge public gauge;
    
    Minter public minter;
    
    VotingEscrow public votingEscrow;
    
    FeeDistributor public feeDistributor;
    
    UniswapV2Router public uniswapRouter;
    
    address public poolOwner;
    
    uint256 public availableCRVToSwap;
    uint256 public crvLockPercent;
    uint256 public availableCRVToLock;
    uint256 public rewardCoin;
    
    uint256 public constant DENOMINATOR = 10000;

/****MODIFIERS****/
    modifier onlyPoolOnwer(){
        require(poolOwner == msg.sender, "Only poolOwner can call!!");
        _;
    }
    
/****CONSTRUCTOR****/
    constructor(
        Pool _poolAddress,
        Gauge _gauge, 
        Minter _minter, 
        IERC20 _crvToken, 
        IERC20 _poolToken,
        VotingEscrow _votingEscrow,
        FeeDistributor _feeDistributor,
        IERC20[3] memory _coins,
        UniswapV2Router _uniswapRouter,
        address _poolOwner,
        uint256 _crvLockPercent,
        
    ){
        poolAddress = _poolAddress;
        gauge = _gauge;
        minter = _minter;
        crvToken = _crvToken;
        votingEscrow = _votingEscrow;
        feeDistributor = _feeDistributor;
        coins = _coins;
        uniswapRouter = _uniswapRouter; 
        poolOwner = _poolOwner;
        poolToken = _poolToken;
        crvLockPercent = _crvLockPercent;
    }

/****POOLOWNER FUNCTIONS****/

    function transferOwnership(address newOwner) external onlyPoolOnwer() returns(bool){
        poolOwner = newOwner;
        return true;
    } 
    
    function setRewardCoin(IERC20 _rewardCoin) external onlyPoolOnwer() returns(bool){
        for(uint256 i = 0; i < coins.length; i++){
            if(coins[i] == _rewardCoin){
                rewardCoin = i;
                break;
            }
        }
        return true;
    }
    
    function deposit(uint256[] memory amounts) external onlyPoolOnwer(){
        uint256[3] memory updatedAmounts;
        for(uint8 i = 0 ; i < updatedAmounts.length; i++){
            updatedAmounts[i] = amounts[i];
            if(amounts[i] > 0){
                coins[i].transferFrom(msg.sender, address(this), amount[i]);
                coins[i].approve(address(poolAddress), amounts[0]);
            }
        }
        poolAddress.add_liquidity(amounts, 0);
        stake();
    }
    
    function withdraw(uint256[] memory amounts) external onlyPoolOnwer(){
        uint coinIndex;
        uint256[3] memory updatedAmounts;
        for(uint256 i = 0 ; i < updatedAmounts.length; i++){
            updatedAmounts[i] = amounts[i];
            if(updatedAmounts[i] > 0 ){
                coinIndex = i;
            }
        }
        uint256 unstakeAmount = gauge.balanceOf(address(this));
        unStake(unstakeAmount);
        poolAddress.remove_liquidity_imbalance(updatedAmounts,unstakeAmount);
        coins[coinIndex].transfer(poolOwner, coins[coinIndex].balanceOf(address(this)));
        stake();
    }
    
/****INTERNAL FUNCTIONS****/

    function stake() internal {
        uint256 stakeAmount = poolToken.balanceOf(address(this)) ;
        poolToken.approve(address(gauge), stakeAmount);
        gauge.deposit(stakeAmount);  
    }
    
    function unStake(uint amount) internal{
        gauge.withdraw(amount);
    }

/****OPEN FUNCTIONS****/
 
    function claimCRV() external returns(uint256){
        uint256 oldBalance = crvToken.balanceOf(address(this));
        Minter(minter).mint(address(gauge));
        uint256 newBalance = crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 crvToLock = crvReceived * crvLockPercent / DENOMINATOR;
        availableCRVToLock = availableCRVToLock.add(crvToLock);
        availableCRVToSwap = availableCRVToSwap.add(crvReceived - crvToLock);
        return crvReceived;
    }
    
    function createLock(uint256 _value, uint256 _unlockTime) external{
        require(_value <= availableCRVToLock, 'Insufficient CRV' );
        availableCRVToLock.sub(_value);
        crvToken.approve(address(votingEscrow), _value);
        VotingEscrow(votingEscrow).create_lock(_value, _unlockTime);
    } 
    
    function releaseLock() external{
        uint256 oldBalance = crvToken.balanceOf(address(this));
        VotingEscrow(votingEscrow).withdraw();  
        uint256 newBalance = crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 crvToLock = crvReceived * crvLockPercent / DENOMINATOR;
        availableCRVToLock = availableCRVToLock.add(crvToLock);
        availableCRVToSwap = availableCRVToSwap.add(crvReceived - crvToLock);
    }
    
    function increaseLockAmount(uint256 _value) external {
        require(_value <= availableCRVToLock, 'Insufficient CRV' );
        availableCRVToLock.sub(_value);
        crvToken.approve(address(votingEscrow), _value);
        VotingEscrow(votingEscrow).increase_amount(_value);
    }
   
    function claimAndConvert3CRV() external returns(uint256){
        uint256 oldBalance = poolToken.balanceOf(address(this));
        FeeDistributor(feeDistributor).claim();
        uint256 newBalance = poolToken.balanceOf(address(this));
        uint256 tokenReceived = newBalance - oldBalance;
        oldBalance = coins[rewardCoin].balanceOf(address(this));
        poolAddress.remove_liquidity_one_coin(tokenReceived, rewardCoin, 0);
        newBalance = coins[rewardCoin].balanceOf(address(this));
        tokenReceived = newBalance - oldBalance;
        coins[rewardCoin].transfer( poolOwner, tokenReceived);
        return tokenReceived;
    }
    
    function convertCRV(uint256 amount) external returns(uint256) {
        require(amount <= availableCRVToSwap, "insufficient token");
        availableCRVToSwap = availableCRVToSwap.sub()
        uint256 oldBalance = coins[rewardCoin].balanceOf(address(this));
        crvToken.approve(uniswapRouter, amount);
        address[] memory path = new address[](3);
        path[0] = crvToken;
        path[1] = UniswapRouter(uniswapRouter).WETH();
        path[2] = address(coins[rewardCoin]);
        
        UniswapRouter(uniswapRouter).swapExactTokensForTokens(
            amount, 
            uint256(0), 
            path, 
            address(this), 
            now + 1800
        );
        
        uint256 newBalance = coins[rewardCoin].balanceOf(address(this));
        uint256 tokenReceived = newBalance - oldBalance;
        coins[rewardCoin].transfer(poolOwner, tokenReceived);
        return tokenReceived;
    }

}
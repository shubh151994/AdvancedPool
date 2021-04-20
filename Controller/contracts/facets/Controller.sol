// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
import "../storage/ControllerStorage.sol";
import "../libraries/SafeMath.sol";

contract Controller is ControllerStorageV1 {
    
    using SafeMath for uint256;
    
  
/****MODIFIERS****/
    modifier onlyPoolOnwer(){
        ControllerStorage storage cs = controllerStorage();
        require(cs.controllerOwner == msg.sender, "Only controllerOwner can call!!");
        _;
    }

    modifier onlyStrategy(){
        ControllerStorage storage cs = controllerStorage();
        require(cs.isStratgey[msg.sender], "Only strategy can call!!");
        _;
    }
    
/****CONSTRUCTOR****/
    function initialize(
        address[] memory _depositStrategies,
        Gauge[] memory _gauges, 
        Minter _minter, 
        IERC20 _crvToken, 
        IERC20[] memory _strategyLPToken,
        VotingEscrow _votingEscrow,
        FeeDistributor _feeDistributor,
        UniswapV2Router _uniswapRouter,
        address _controllerOwner,
        uint256 _crvLockPercent,
        IERC20 _adminFeeToken
    ) public{
        ControllerStorage storage cs = controllerStorage();
        cs.depositStrategies = _depositStrategies;
        require(!cs.initialized, 'Already initialized');
        for(uint256 i = 0; i < _depositStrategies.length; i++){
            cs.strategyGauges[cs.depositStrategies[i]] = _gauges[i];
            cs.strategyLPTokens[cs.depositStrategies[i]] = _strategyLPToken[i];
            cs.isStratgey[_depositStrategies[i]] = true;
        }
        cs.minter = _minter;
        cs.crvToken = _crvToken;
        cs.votingEscrow = _votingEscrow;
        cs.feeDistributor = _feeDistributor;
        cs.uniswapRouter = _uniswapRouter; 
        cs.controllerOwner = _controllerOwner;
        cs.crvLockPercent = _crvLockPercent;
        cs.DENOMINATOR = 10000;
        cs.initialized = true;
        cs.adminFeeToken = _adminFeeToken;
        cs.totalStrategies = _depositStrategies.length;
    }

/****controllerOwner FUNCTIONS****/

    function updateOwner(address newOwner) external onlyPoolOnwer() returns(bool){
        ControllerStorage storage cs = controllerStorage();
        cs.controllerOwner = newOwner;
        return true;
    } 
    
    function stake(uint256 amount) external onlyStrategy(){
        ControllerStorage storage cs = controllerStorage();
        cs.strategyLPTokens[msg.sender].transferFrom(msg.sender,address(this), amount);
        cs.strategyLPTokens[msg.sender].approve(address(cs.strategyGauges[msg.sender]), amount);
        cs.strategyGauges[msg.sender].deposit(amount);  
    }
    
    function unStake() external onlyStrategy(){
        ControllerStorage storage cs = controllerStorage();
        uint256 unstakedAmount = cs.strategyGauges[msg.sender].balanceOf(address(this));
        cs.strategyGauges[msg.sender].withdraw(unstakedAmount);
        cs.strategyLPTokens[msg.sender].transfer(msg.sender, unstakedAmount);
    }

/****OPEN FUNCTIONS****/
 
    function claimCRV() external onlyStrategy() returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        uint256 oldBalance = cs.crvToken.balanceOf(address(this));
        Minter(cs.minter).mint(address(address(cs.strategyGauges[msg.sender])));
        uint256 newBalance = cs.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 crvToLock = crvReceived * cs.crvLockPercent / cs.DENOMINATOR;
        cs.availableCRVToLock = cs.availableCRVToLock + crvToLock;
        uint256 crvToSend = cs.availableCRV[msg.sender] + crvReceived - crvToLock;
        cs.availableCRV[msg.sender] = 0;
        cs.crvToken.transfer(msg.sender, crvToSend);
        return crvReceived - crvToLock;
    }

    function createLock(uint256 _value, uint256 _unlockTime) external{
        ControllerStorage storage cs = controllerStorage();
        require(_value <= cs.availableCRVToLock, 'Insufficient CRV' );
        cs.availableCRVToLock = cs.availableCRVToLock.sub(_value);
        cs.crvToken.approve(address(cs.votingEscrow), _value);
        VotingEscrow(cs.votingEscrow).create_lock(_value, _unlockTime);
    } 
    
    function releaseLock() external{
        ControllerStorage storage cs = controllerStorage();
        uint256 oldBalance = cs.crvToken.balanceOf(address(this));
        VotingEscrow(cs.votingEscrow).withdraw();  
        uint256 newBalance = cs.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 crvToLock = crvReceived * cs.crvLockPercent / cs.DENOMINATOR;
        uint256 crvPerStrategy = (crvReceived - crvToLock)/cs.totalStrategies;
        for(uint8 i = 0 ; i < cs.totalStrategies; i++){
            cs.availableCRV[cs.depositStrategies[i]] = cs.availableCRV[cs.depositStrategies[i]] + crvPerStrategy;
        }
        cs.availableCRVToLock = cs.availableCRVToLock.add(crvToLock);
    }
    
    function increaseLockAmount(uint256 _value) external {
        ControllerStorage storage cs = controllerStorage();
        require(_value <= cs.availableCRVToLock, 'Insufficient CRV' );
        cs.availableCRVToLock = cs.availableCRVToLock.sub(_value);
        cs.crvToken.approve(address(cs.votingEscrow), _value);
        VotingEscrow(cs.votingEscrow).increase_amount(_value);
    }

    function convertToCRV(uint256 amount) internal {
        ControllerStorage storage cs = controllerStorage();
        cs.crvToken.approve(address(cs.uniswapRouter), amount);
        address[] memory path = new address[](3);
        path[0] = address(cs.crvToken);
        path[1] = cs.uniswapRouter.WETH();
        path[2] = address(cs.crvToken);
        
        cs.uniswapRouter.swapExactTokensForTokens(
            amount, 
            uint256(0), 
            path, 
            address(this), 
            block.timestamp + 1800
        );
    }
   
    function claimAndDistributeAdminFees() external returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        uint256 oldBalance = cs.adminFeeToken.balanceOf(address(this));
        FeeDistributor(cs.feeDistributor).claim();
        uint256 newBalance = cs.adminFeeToken.balanceOf(address(this));
        uint256 adminFeeReceived = newBalance - oldBalance;
        oldBalance = cs.crvToken.balanceOf(address(this));
        convertToCRV(adminFeeReceived);
        newBalance = cs.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 unlockedCRV = crvReceived - crvReceived * cs.crvLockPercent / cs.DENOMINATOR;
        uint256 crvPerStrategy = unlockedCRV/cs.totalStrategies;
        for(uint256 i = 0 ; i < cs.totalStrategies; i++){
            cs.availableCRV[cs.depositStrategies[i]] = cs.availableCRV[cs.depositStrategies[i]] + crvPerStrategy;
        }
        cs.availableCRVToLock = cs.availableCRVToLock + crvReceived - unlockedCRV;
        return crvReceived;
    }

}
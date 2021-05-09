// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
import "../storage/ControllerStorage.sol";
import "../libraries/SafeMath.sol";

contract Controller is ControllerStorageV1 {
    
    using SafeMath for uint256;
    
  
/****MODIFIERS****/
    modifier onlyOwner(){
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
        IERC20[] memory _strategyLPToken,
        Minter _minter, 
        IERC20 _crvToken, 
        VotingEscrow _votingEscrow,
        FeeDistributor _feeDistributor,
        UniswapV2Router _uniswapRouter,
        address _controllerOwner,
        uint256 _crvLockPercent,
        IERC20 _adminFeeToken
    ) public{
        ControllerStorage storage cs = controllerStorage();
        require(!cs.initialized, 'Already initialized');
        cs.depositStrategies = _depositStrategies;

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
        cs.adminFeeToken = _adminFeeToken;
        cs.totalStrategies = _depositStrategies.length;
        cs.initialized = true;
    }

/****CONTROLLER OWNER FUNCTIONS****/

    function updateOwner(address newOwner) external onlyOwner() returns(bool){
        ControllerStorage storage cs = controllerStorage();
        cs.controllerOwner = newOwner;
        return true;
    } 

    function addNewStrategy(address _strategy, Gauge _gauge, IERC20 _strategyLPToken) external onlyOwner() returns(bool){
        ControllerStorage storage cs = controllerStorage();
        cs.depositStrategies.push(_strategy);
        cs.strategyGauges[_strategy] = _gauge;
        cs.strategyLPTokens[_strategy] = _strategyLPToken;
        cs.isStratgey[_strategy] = true;
        return true;
    } 

    function updateAdminFeeToken(IERC20 _adminFeeToken) external onlyOwner() returns(bool){
        ControllerStorage storage cs = controllerStorage();
        cs.adminFeeToken = _adminFeeToken;
        return true;
    } 

/****STRATEGY FUNCTIONS****/

    function stake(uint256 amount) external onlyStrategy(){
        ControllerStorage storage cs = controllerStorage();
        cs.strategyLPTokens[msg.sender].transferFrom(msg.sender, address(this), amount);
        cs.strategyLPTokens[msg.sender].approve(address(cs.strategyGauges[msg.sender]), amount);
        cs.strategyGauges[msg.sender].deposit(amount);  
    }
    
    function unstake() external onlyStrategy(){
        ControllerStorage storage cs = controllerStorage();
        uint256 unstakedAmount = cs.strategyGauges[msg.sender].balanceOf(address(this));
        cs.strategyGauges[msg.sender].withdraw(unstakedAmount);
        cs.strategyLPTokens[msg.sender].transfer(msg.sender, unstakedAmount);
    }

    function claimCRV() external onlyStrategy() returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        uint256 oldBalance = cs.crvToken.balanceOf(address(this));
        Minter(cs.minter).mint(address(cs.strategyGauges[msg.sender]));
        uint256 newBalance = cs.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 crvToLock = crvReceived * cs.crvLockPercent / cs.DENOMINATOR;
        cs.availableCRVToLock = cs.availableCRVToLock + crvToLock;
        uint256 crvToSend = crvReceived - crvToLock;
        cs.crvToken.transfer(msg.sender, crvToSend);
        return crvReceived - crvToLock;
    }

/****OPEN FUNCTIONS****/

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
        cs.availableCRVToLock = cs.availableCRVToLock.add(crvReceived);
    }
    
    function increaseLockAmount(uint256 _value) external {
        ControllerStorage storage cs = controllerStorage();
        require(_value <= cs.availableCRVToLock, 'Insufficient CRV' );
        cs.availableCRVToLock = cs.availableCRVToLock.sub(_value);
        cs.crvToken.approve(address(cs.votingEscrow), _value);
        VotingEscrow(cs.votingEscrow).increase_amount(_value);
    }

    function claimAndConverAdminFees() external returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        uint256 oldBalance = cs.adminFeeToken.balanceOf(address(this));
        FeeDistributor(cs.feeDistributor).claim();
        uint256 newBalance = cs.adminFeeToken.balanceOf(address(this));
        uint256 adminFeeReceived = newBalance - oldBalance;
        oldBalance = cs.crvToken.balanceOf(address(this));
        convertToCRV(adminFeeReceived);
        newBalance = cs.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        cs.availableCRVToLock = cs.availableCRVToLock + crvReceived;
        return crvReceived;
    }
    
/***INTERNAL FUNCTION****/

    function convertToCRV(uint256 amount) internal {
        ControllerStorage storage cs = controllerStorage();
        cs.crvToken.approve(address(cs.uniswapRouter), amount);
        address[] memory path = new address[](3);
        path[0] = address(cs.adminFeeToken);
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

}
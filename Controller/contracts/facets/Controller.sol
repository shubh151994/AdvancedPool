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
    
    modifier onlyStrategyOrPool(){
        ControllerStorage storage cs = controllerStorage();
        require(cs.isStratgey[msg.sender] || cs.isPool[msg.sender], "Only strategy or pool can call!!");
        _;
    }

/****CONSTRUCTOR****/
    function initialize(
        address[] memory _depositStrategies,
        address[] memory _pools,
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
        //require(!cs.initialized, 'Already initialized');
        cs.depositStrategies = _depositStrategies;

        for(uint256 i = 0; i < cs.depositStrategies.length; i++){
            cs.strategyGauges[cs.depositStrategies[i]] = _gauges[i];
            cs.strategyLPTokens[cs.depositStrategies[i]] = _strategyLPToken[i];
            cs.isStratgey[cs.depositStrategies[i]] = true;
            cs.isPool[_pools[i]] = true;
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
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        cs.controllerOwner = newOwner;
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
        return true;
    } 

    function addNewStrategy(address _strategy, Gauge _gauge, IERC20 _strategyLPToken) external onlyOwner() returns(bool){
        ControllerStorage storage cs = controllerStorage();
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        cs.depositStrategies.push(_strategy);
        cs.strategyGauges[_strategy] = _gauge;
        cs.strategyLPTokens[_strategy] = _strategyLPToken;
        cs.isStratgey[_strategy] = true;
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
        return true;
    } 

    function updateAdminFeeToken(IERC20 _adminFeeToken) external onlyOwner() returns(bool){
        ControllerStorage storage cs = controllerStorage();
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        cs.adminFeeToken = _adminFeeToken;
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
        return true;
    } 

    function createLock(uint256 _value, uint256 _unlockTime) external onlyOwner() {
        ControllerStorage storage cs = controllerStorage();
        require(_value <= cs.availableCRVToLock, 'Insufficient CRV' );
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        cs.availableCRVToLock = cs.availableCRVToLock.sub(_value);
        cs.crvToken.approve(address(cs.votingEscrow), _value);
        VotingEscrow(cs.votingEscrow).create_lock(_value, _unlockTime);
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
    } 
    
    function releaseLock() external onlyOwner() {
        ControllerStorage storage cs = controllerStorage();
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        uint256 oldBalance = cs.crvToken.balanceOf(address(this));
        VotingEscrow(cs.votingEscrow).withdraw();  
        uint256 newBalance = cs.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        cs.availableCRVToLock = cs.availableCRVToLock.add(crvReceived);
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
    }
    
    function increaseLockAmount(uint256 _value) external onlyOwner() {
        ControllerStorage storage cs = controllerStorage();
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        require(_value <= cs.availableCRVToLock, 'Insufficient CRV' );
        cs.availableCRVToLock = cs.availableCRVToLock.sub(_value);
        cs.crvToken.approve(address(cs.votingEscrow), _value);
        VotingEscrow(cs.votingEscrow).increase_amount(_value);
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
    }

    function increaseUnlockTime(uint256 _value) external onlyOwner() {
        ControllerStorage storage cs = controllerStorage();
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        VotingEscrow(cs.votingEscrow).increase_unlock_time(_value);
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
    }

    function claimAndConvertAdminFees() external onlyOwner() returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        uint256 oldBalance = cs.adminFeeToken.balanceOf(address(this));
        FeeDistributor(cs.feeDistributor).claim();
        uint256 newBalance = cs.adminFeeToken.balanceOf(address(this));
        uint256 adminFeeReceived = newBalance - oldBalance;
        oldBalance = cs.crvToken.balanceOf(address(this));
        convertToCRV(adminFeeReceived);
        newBalance = cs.crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        cs.availableCRVToLock = cs.availableCRVToLock + crvReceived;
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
        return crvReceived;
    }

    function updateLockPercentage(uint256 _newPercent) external onlyOwner() returns(bool){
        ControllerStorage storage cs = controllerStorage();
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].add((gasleft().add(cs.defaultGas)).mul(tx.gasprice));
        cs.crvLockPercent = _newPercent;
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender].sub(gasleft().mul(tx.gasprice)); 
        return true;
    } 
    

/****STRATEGY FUNCTIONS****/

    function stake(uint256 amount) external onlyStrategy(){
        ControllerStorage storage cs = controllerStorage();
        cs.strategyLPTokens[msg.sender].transferFrom(msg.sender, address(this), amount);
        cs.strategyLPTokens[msg.sender].approve(address(cs.strategyGauges[msg.sender]), amount);
        cs.strategyGauges[msg.sender].deposit(amount);  
    }
    
    function unstake() external onlyStrategy() returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        uint256 unstakedAmount = cs.strategyGauges[msg.sender].balanceOf(address(this));
        cs.strategyGauges[msg.sender].withdraw(unstakedAmount);
        cs.strategyLPTokens[msg.sender].transfer(msg.sender, unstakedAmount);
        return unstakedAmount;
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

    function updateGasUsed(uint256 _gasUsed) public onlyStrategyOrPool() {
        ControllerStorage storage cs = controllerStorage();
        cs.claimableGas[msg.sender] = cs.claimableGas[msg.sender] + _gasUsed;
    }

/****OPEN FUNCTIONS****/

    receive() external payable {
        ControllerStorage storage cs = controllerStorage();
        cs.ethReceived[msg.sender] = cs.ethReceived[msg.sender] + msg.value;
    }
    
    function claimGasFee() public{
        ControllerStorage storage cs = controllerStorage();     
        uint256 gasAtStart = (gasleft().add(cs.defaultGas)).mul(tx.gasprice);
        uint256 claimableAmount = cs.claimableGas[msg.sender];
        require(claimableAmount > 0, "Nothing to claim");
        require(address(this).balance >= claimableAmount, "Dont have enough fund, Try later!!");
        cs.claimableGas[msg.sender] = 0;
        msg.sender.transfer(claimableAmount);
        uint256 gasAtEnd = gasleft().mul(tx.gasprice);
        cs.claimableGas[msg.sender] = gasAtStart - gasAtEnd;
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

/****VIEW FUNCTIONS****/

    function defaultGas() public view returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        return cs.defaultGas;
    }

    function availableCRVToLock() public view returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        return cs.availableCRVToLock;
    }

    function gasUsed(address account) public view returns(uint256){
        ControllerStorage storage cs = controllerStorage();
        return cs.claimableGas[account];
    }

}
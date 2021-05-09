// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;

interface  UniswapV2Router  {
    function swapExactTokensForETH(uint, uint, address[] calldata, address, uint) external  returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory);
    function WETH() external pure returns (address); 
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to,uint deadline) external returns (uint[] memory amounts);
}

library SafeMath {
  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);

        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
   
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }
  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
    
        return c;
    }
  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
 
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function transfer(address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface Gauge {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface Minter {
    function mint(address) external;
}

interface FeeDistributor{
    function claim() external;
}

interface VotingEscrow{
    function create_lock(uint256,uint256) external;
    function increase_amount(uint256)  external;
    function withdraw() external;
}

contract Controller {
    
    using SafeMath for uint256;

    bool public initialized;
    
    IERC20 public crvToken;
    IERC20 public adminFeeToken;

    mapping(address => Gauge) public strategyGauges;
    mapping(address => IERC20) public strategyLPTokens;
    mapping(address => bool) public isStratgey;
 
    address[] public depositStrategies;
    
    Minter public minter;
    
    VotingEscrow public votingEscrow;

    FeeDistributor public feeDistributor;
    
    UniswapV2Router public uniswapRouter;
    
    address public controllerOwner;
    
    uint256 public crvLockPercent;
    uint256 public DENOMINATOR;
    uint256 public totalStrategies;
    uint256 public availableCRVToLock;

  
/****MODIFIERS****/
    modifier onlyPoolOnwer(){
        require(controllerOwner == msg.sender, "Only controllerOwner can call!!");
        _;
    }

    modifier onlyStrategy(){
        require(isStratgey[msg.sender], "Only strategy can call!!");
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
        require(!initialized, 'Already initialized');
        depositStrategies = _depositStrategies;
        minter = _minter;
        crvToken = _crvToken;
        votingEscrow = _votingEscrow;
        feeDistributor = _feeDistributor;
        uniswapRouter = _uniswapRouter; 
        controllerOwner = _controllerOwner;
        crvLockPercent = _crvLockPercent;
        DENOMINATOR = 10000;
        adminFeeToken = _adminFeeToken;
        totalStrategies = _depositStrategies.length;
        initialized = true;

        for(uint256 i = 0; i < _depositStrategies.length; i++){
            strategyGauges[depositStrategies[i]] = _gauges[i];
            strategyLPTokens[depositStrategies[i]] = _strategyLPToken[i];
            isStratgey[_depositStrategies[i]] = true;
        }
    }

/****STRATEGY FUNCTION****/

    function stake(uint256 amount) external onlyStrategy(){
        strategyLPTokens[msg.sender].transferFrom(msg.sender, address(this), amount);
        strategyLPTokens[msg.sender].approve(address(strategyGauges[msg.sender]), amount);
        strategyGauges[msg.sender].deposit(amount);  
    }

    function unStake() external onlyStrategy() returns(uint256){
        uint256 unstakedAmount = strategyGauges[msg.sender].balanceOf(address(this));
        strategyGauges[msg.sender].withdraw(unstakedAmount);
        strategyLPTokens[msg.sender].transfer(msg.sender, unstakedAmount);
        return unstakedAmount;
    }

    function claimCRV() external onlyStrategy() returns(uint256){
        uint256 oldBalance = crvToken.balanceOf(address(this));
        Minter(minter).mint(address(strategyGauges[msg.sender]));
        uint256 newBalance = crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        uint256 crvToLock = crvReceived * crvLockPercent / DENOMINATOR;
        availableCRVToLock = availableCRVToLock + crvToLock;
        uint256 crvToSend = crvReceived - crvToLock;
        crvToken.transfer(msg.sender, crvToSend);
        return crvReceived - crvToLock;
    }

/****OPEN FUNCTION****/

    function createLock(uint256 _value, uint256 _unlockTime) external{
        require(_value <= availableCRVToLock, 'Insufficient CRV' );
        availableCRVToLock = availableCRVToLock.sub(_value);
        crvToken.approve(address(votingEscrow), _value);
        VotingEscrow(votingEscrow).create_lock(_value, _unlockTime);
    } 

    function releaseLock() external{
        uint256 oldBalance = crvToken.balanceOf(address(this));
        VotingEscrow(votingEscrow).withdraw();  
        uint256 newBalance = crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        availableCRVToLock = availableCRVToLock.add(crvReceived);
    }

    function increaseLockAmount(uint256 _value) external {
        require(_value <= availableCRVToLock, 'Insufficient CRV' );
        availableCRVToLock = availableCRVToLock.sub(_value);
        crvToken.approve(address(votingEscrow), _value);
        VotingEscrow(votingEscrow).increase_amount(_value);
    }

    function claimAndDistributeAdminFees() external returns(uint256){
        uint256 oldBalance = adminFeeToken.balanceOf(address(this));
        FeeDistributor(feeDistributor).claim();
        uint256 newBalance = adminFeeToken.balanceOf(address(this));
        uint256 adminFeeReceived = newBalance - oldBalance;
        oldBalance = crvToken.balanceOf(address(this));
        convertToCRV(adminFeeReceived);
        newBalance = crvToken.balanceOf(address(this));
        uint256 crvReceived = newBalance - oldBalance;
        availableCRVToLock = availableCRVToLock + crvReceived;
        return crvReceived;
    }

/****INTERNAL FUNCTIONS****/
    
    function convertToCRV(uint256 amount) internal {
        crvToken.approve(address(uniswapRouter), amount);
        address[] memory path = new address[](3);
        path[0] = address(crvToken);
        path[1] = uniswapRouter.WETH();
        path[2] = address(crvToken);
        
        uniswapRouter.swapExactTokensForTokens(
            amount, 
            uint256(0), 
            path, 
            address(this), 
            block.timestamp + 1800
        );
    }
}
    
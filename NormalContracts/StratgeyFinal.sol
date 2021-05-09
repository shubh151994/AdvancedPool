// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.6;
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

interface CurvePool{
    function add_liquidity(uint256[3] calldata, uint256) external;
    function remove_liquidity_imbalance(uint256[3] calldata, uint256) external;
}

interface  UniswapV2Router  {
    function WETH() external pure returns (address); 
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to,uint deadline) external returns (uint[] memory amounts);
}

interface Controller{
    function stake(uint256 amount) external;
    function unStake() external returns(uint256);
    function claimCRV() external returns(uint256);
}

contract TriPoolStrategy {

/****VARIABLES****/
    using SafeMath for uint256;

    IERC20[3] public coins;
    IERC20 public crvToken;
    IERC20 public curvePoolToken;

    CurvePool public curvePool;
    UniswapV2Router uniswapRouter;
    Controller public controller;
    
    address public pool;
    address public contractOwner;

    uint256 public coinIndex; 
    
    bool public initialized;

/****CONSTRUCTOR****/
    function initialize(
        CurvePool _curvePool,
        IERC20 _crvToken, 
        IERC20 _curvePoolToken,
        IERC20[3] memory _coins,
        UniswapV2Router _uniswapRouter,
        address _pool,
        Controller _controller,
        uint256 _coinIndex
    ) public{
        require(!initialized, 'Already initialized');
        curvePool = _curvePool;
        crvToken = _crvToken;
        coins = _coins;
        uniswapRouter = _uniswapRouter; 
        pool = _pool;
        curvePoolToken = _curvePoolToken;
        controller = _controller;
        coinIndex = _coinIndex;
        initialized = true;
        contractOwner = msg.sender;
    }

/****MODIFIERS****/
    modifier onlyPool(){
        require(msg.sender == pool, "Only pool can call!!");
        _;
    }
    modifier onlyOwner(){
        require(msg.sender == contractOwner, "Only contract owner can call!!");
        _;
    }

/****OWNER FUNCTION****/

    function updateOwner(address newOwner) external onlyOwner() returns(bool){
        contractOwner = newOwner;
        return true;
    } 

    function changeCoinIndex(uint256 _coinIndex) external onlyOwner() returns(bool){
        require(_coinIndex < coins.length, 'Invalid Coin Index');
        coinIndex = _coinIndex;
        return true;
    } 

    function changeController(Controller _controller) external onlyOwner() returns(bool){
        require(address(_controller) != address(0), 'Invalid address');
        controller = _controller;
        return true;
    } 

/****POOL FUNCTION****/

    function deposit(uint256 amount) external onlyPool(){
        uint256[3] memory amountArray;
        amountArray[coinIndex] = amount;
        coins[coinIndex].transferFrom(msg.sender, address(this), amount);
        coins[coinIndex].approve(address(curvePool), amount);
        curvePool.add_liquidity(amountArray, 0);
        stakeOnController();
    }

    function withdraw(uint256 amount) external onlyPool(){
        uint256[3] memory amountArray;
        amountArray[coinIndex] = amount;
        uint256 unstakedAmount = unStakeFromController();
        curvePool.remove_liquidity_imbalance(amountArray, unstakedAmount);
        coins[coinIndex].transfer(pool, coins[coinIndex].balanceOf(address(this)));
        stakeOnController();
    }
    
/****INTERNAL FUNCTION****/
    
    function stakeOnController() internal {
        uint256 stakeAmount = curvePoolToken.balanceOf(address(this)) ;
        curvePoolToken.approve(address(controller), stakeAmount);
        controller.stake(stakeAmount);  
    }

    function unStakeFromController() internal returns(uint256){
        uint256 unstakedAmount = controller.unStake();
        return unstakedAmount;
    }

/****OPEN FUNCTIONS****/    
    
    function claimAndConvertCRV() external returns(uint256) {
        controller.claimCRV();
        uint256 claimedAmount = crvToken.balanceOf(address(this));
        require(claimedAmount > 0, "Nothing claimed");
        crvToken.approve(address(uniswapRouter), claimedAmount);
        address[] memory path = new address[](3);
        path[0] = address(crvToken);
        path[1] = uniswapRouter.WETH();
        path[2] = address(coins[coinIndex]);
        
        uniswapRouter.swapExactTokensForTokens(
            claimedAmount, 
            uint256(0), 
            path, 
            address(this), 
            block.timestamp + 1800
        );
        
        uint256 tokenReceived = coins[coinIndex].balanceOf(address(this));
        coins[coinIndex].transfer(pool, tokenReceived);
        return tokenReceived;
    }
}
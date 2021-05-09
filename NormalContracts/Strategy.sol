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
interface Pool{
    function add_liquidity(uint256[3] calldata, uint256) external;
    function remove_liquidity_imbalance(uint256[3] calldata, uint256) external;
    function calc_token_amount(uint256[3] memory, bool) external returns(uint256);
    function remove_liquidity_one_coin(uint256 , int128, uint256) external;
}


interface  UniswapV2Router  {
    function swapExactTokensForETH(uint, uint, address[] calldata, address, uint) external  returns (uint[] memory);
    function getAmountsOut(uint, address[] calldata) external view returns (uint[] memory);
    function WETH() external pure returns (address); 
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to,uint deadline) external returns (uint[] memory amounts);
}

interface Controller{
    function stake(uint256 amount) external;
    function unStake() external returns(uint256);
    function claimCRV() external;
}
contract TriPoolStrategy {
    
    using SafeMath for uint256;

    bool public initialized;

    IERC20[3] public coins;
    IERC20 public crvToken;
    IERC20 public poolToken;

    Pool public poolAddress;
        
    UniswapV2Router uniswapRouter;

    Controller public controller;
    
    address public poolOwner;
    uint256 public coinIndex; 
    
  
/****MODIFIERS****/
    modifier onlyPoolOnwer(){
        require(poolOwner == msg.sender, "Only poolOwner can call!!");
        _;
    }
    
/****CONSTRUCTOR****/
    function initialize(
        Pool _poolAddress,
        IERC20 _crvToken, 
        IERC20 _poolToken,
        IERC20[3] memory _coins,
        UniswapV2Router _uniswapRouter,
        address _poolOwner,
        Controller _controller,
        uint256 _coinIndex
    ) public{
        
        require(!initialized, 'Already initialized');
        poolAddress = _poolAddress;
        crvToken = _crvToken;
        coins = _coins;
        uniswapRouter = _uniswapRouter; 
        poolOwner = _poolOwner;
        poolToken = _poolToken;
        controller = _controller;
        coinIndex = _coinIndex;
        initialized = true;
    }

/****POOLOWNER FUNCTIONS****/

    function updateOwner(address newOwner) external onlyPoolOnwer() returns(bool){
        
        poolOwner = newOwner;
        return true;
    } 

    function changeCoinIndex(uint256 _coinIndex) external onlyPoolOnwer() returns(bool){
        
        require(_coinIndex < coins.length, 'Invalid Coin Index');
        coinIndex = _coinIndex;
        return true;
    } 
    
    function deposit(uint256 amount) external onlyPoolOnwer(){
        
        uint256[3] memory amountArray;
        amountArray[coinIndex] = amount;
        coins[coinIndex].transferFrom(msg.sender, address(this), amount);
        coins[coinIndex].approve(address(poolAddress), amount);
        poolAddress.add_liquidity(amountArray, 0);
       // stakeOnController();
    }
    
    function withdraw(uint256 amount) external onlyPoolOnwer(){
        
        uint256[3] memory amountArray;
        amountArray[coinIndex] = amount;
        uint256 unstakedAmount = unStakeFromController();
        poolAddress.remove_liquidity_imbalance(amountArray, unstakedAmount);
        coins[coinIndex].transfer(poolOwner, coins[coinIndex].balanceOf(address(this)));
        stakeOnController();
    }
    
/****INTERNAL FUNCTIONS****/

    function stakeOnController() internal {
        
        uint256 stakeAmount = poolToken.balanceOf(address(this)) ;
        poolToken.approve(address(controller), stakeAmount);
        controller.stake(stakeAmount);  
    }
    //currently unstaking all
    function unStakeFromController() internal returns(uint256){
        
        uint256 unstakedAmount = controller.unStake();
        return unstakedAmount;
    }

/****OPEN FUNCTIONS****/    
    
    function claimAndConverCRV() external returns(uint256) {
        
        controller.claimCRV();
        uint256 claimedAmount = crvToken.balanceOf(address(this));
        require(claimedAmount > 0, "Nothing to claim");
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
        coins[coinIndex].transfer(poolOwner, tokenReceived);
        return tokenReceived;
    }

}
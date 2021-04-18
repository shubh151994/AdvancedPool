
/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Web3 = require('web3');
const config = require('./../config.js');
const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.rinkeby));
const TX = require('ethereumjs-tx').Transaction;

const privateKey = Buffer.from(config.privateKey.rinkeby,'hex');

const DiamondContractAddress = "0x4008f27fD04f90fb527B92430199Ad649c77D962";
const deployerAddress = config.publicKey.rinkeby;

const CutABI =   [
  {
    "anonymous": false,
    "inputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "facetAddress",
            "type": "address"
          },
          {
            "internalType": "enum IDiamondCut.FacetCutAction",
            "name": "action",
            "type": "uint8"
          },
          {
            "internalType": "bytes4[]",
            "name": "functionSelectors",
            "type": "bytes4[]"
          }
        ],
        "indexed": false,
        "internalType": "struct IDiamondCut.FacetCut[]",
        "name": "_diamondCut",
        "type": "tuple[]"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "_init",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "bytes",
        "name": "_calldata",
        "type": "bytes"
      }
    ],
    "name": "DiamondCut",
    "type": "event"
  },
  {
    "inputs": [
      {
        "components": [
          {
            "internalType": "address",
            "name": "facetAddress",
            "type": "address"
          },
          {
            "internalType": "enum IDiamondCut.FacetCutAction",
            "name": "action",
            "type": "uint8"
          },
          {
            "internalType": "bytes4[]",
            "name": "functionSelectors",
            "type": "bytes4[]"
          }
        ],
        "internalType": "struct IDiamondCut.FacetCut[]",
        "name": "_diamondCut",
        "type": "tuple[]"
      },
      {
        "internalType": "address",
        "name": "_init",
        "type": "address"
      },
      {
        "internalType": "bytes",
        "name": "_calldata",
        "type": "bytes"
      }
    ],
    "name": "diamondCut",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
const AdvancedPoolABI =   [
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "pool",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "coin",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "poolDeposit",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "pool",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "coin",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "poolWithdrawal",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "userDeposits",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "user",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "userWithdrawal",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "contract IERC20[]",
        "name": "_coins",
        "type": "address[]"
      },
      {
        "internalType": "contract IERC20",
        "name": "_poolToken",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_minLiquidity",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_maxLiquidity",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_withdrawFees",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_depositFees",
        "type": "uint256"
      },
      {
        "internalType": "contract DepositStrategy[]",
        "name": "_depositStrategies",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_strategyForCoin",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[][]",
        "name": "_coinsPositionInStrategy",
        "type": "uint256[][]"
      }
    ],
    "name": "initialize",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "stake",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "unStake",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_minLiquidity",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_maxLiquidity",
        "type": "uint256"
      }
    ],
    "name": "updateLiquidityParam",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_depositFees",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_withdrawFees",
        "type": "uint256"
      }
    ],
    "name": "updateFees",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "changeLockStatus",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      }
    ],
    "name": "updateOwner",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "strategyIndex",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "setStrategyRewardCoin",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "addToStrategy",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "removeFromPool",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "amountOfStableCoins",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "calculatePoolTokens",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [],
    "name": "stableCoinPrice",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "amountOfPoolToken",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "calculateStableCoins",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [],
    "name": "poolTokenPrice",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "maxBurnAllowed",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "feesCollected",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "currentLiquidity",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "idealAmount",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "maxLiquidityAllowedInPool",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "amountToDeposit",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "minLiquidityToMaintainInPool",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "coinIndex",
        "type": "uint256"
      }
    ],
    "name": "amountToWithdraw",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  }
]
const AdvancePoolAddr = "0xD438b24FA03e02796Da4BA3edc1A6E00555F045A";

const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2
}

const transact = async (data, value) => {
   //  console.log(data, contractAddress, holderAddress, privateKey, value)
        try {
            var count = await web3.eth.getTransactionCount(deployerAddress);
            var gasPrice = await web3.eth.getGasPrice();
            var txData = {
                nonce: web3.utils.toHex(count),
                gasLimit: web3.utils.toHex(3000000),
                gasPrice: '0x' + gasPrice.toString(16),
                to: DiamondContractAddress,
                from: deployerAddress,
                data: data, 
                value: value
            }
            var transaction = new TX(txData,{chain:'rinkeby', hardfork:'petersburg'});
            transaction.sign(privateKey);
            var serialisedTransaction = transaction.serialize().toString('hex');
    
            var receipt = await web3.eth.sendSignedTransaction('0x' + serialisedTransaction);
            return receipt;
        } catch(e) {
                console.log('in catch')
                throw new Error(e);
    		}
}

function getSelectors (abi) {
   // console.log(abi,'aaa')
    const selectors = abi.reduce((acc, val) => {
    // console.log(val, "valu");
      if (val.type === 'function') {
        acc.push(val.signature)
        return acc
      } else {
        return acc
      }
    }, [])
  console.log(selectors,"selectors");
    return selectors
}
const zeroAddress = '0x0000000000000000000000000000000000000000'

// FUNCTION TO ADD FACET
async function addFacet(){
  try{
  console.log("1111111111")
  const facetCutCall = new web3.eth.Contract(CutABI, DiamondContractAddress);
  const Part1Call = new web3.eth.Contract(AdvancedPoolABI, AdvancePoolAddr)
 
  let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  
  console.log("33333333333333333",selectorspart1)
  const functCall = await facetCutCall.methods
      .diamondCut([ [AdvancePoolAddr, FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0 )
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};


// async function readValue(){
//   try{
//   const EosToEth2 = new web3.eth.Contract(EosToEthPart2ABI, DiamondContractAddress)
//   console.log(EosToEth2.methods, "EosToEth2")
//   const functCall = await EosToEth2.methods.contractParams().call();
//   console.log("444444444444444444444")
//   console.log(functCall,"functCall")
//   } catch(e) {
//       console.log('in catch2')
//       throw new Error(e);
//   }

// };


async function initializeAdvancedPool(){
  try{
  const coins = ["0x66f58Db4aA308EB6C17F5e23dB7a075D65c90577","0x92D97AB672F71e029DfbC18f01E615c3637b1c95","0x0CF6bc00DCeF87983C641BF850fa11Aa3811Cd62"]
  const poolToken = "0xbD7D8A9c7E57B5Aaa842d749Cc1dA9e02693d9d6"
  const minLiq = 1000
  const maxLiq = 3000
  const withFee = 1000
  const depFee = 1000
  const depStrategies = ["0x2aA2d29d3f312F2508aBDa55b40e2805D4312207"]
  const strForCoin = [0,0,0]
  const coinPos = [[0,1,2]]
  
  console.log("1111111111")
  const bridgeCall = new web3.eth.Contract(AdvancedPoolABI, DiamondContractAddress);
  const functCall = await bridgeCall.methods
      .initialize(
        coins, 
        poolToken,
        minLiq, 
        maxLiq,
        withFee,
        depFee,
        depStrategies,
        strForCoin,
        coinPos
      ).encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0)
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};
  
async function withdrawToken(){
  try{
  const id = 5
  const byteData = '0x0000000000000003010000000005f5e1000000000000000000f5951a818cdb8d67843794980af7a5db588fe6acf5951a818cdb8d67843794980af7a5db588fe6ac000000000000000000000000000000000000000000000000'
  
  console.log("1111111111")
  const bridgeCall = new web3.eth.Contract(EosToEthPart1ABI, DiamondContractAddress);
  const functCall = await bridgeCall.methods
      .pushInboundMessage(
        id,
        byteData
      ).encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0)
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

async function sendToken(){
  try{
  
  console.log("1111111111")
  const bridgeCall = new web3.eth.Contract(EosToEthPart1ABI, DiamondContractAddress);
  const functCall = await bridgeCall.methods
      .sendToken(
        "1000000",
        "0"
      ).encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0)
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

initializeAdvancedPool()
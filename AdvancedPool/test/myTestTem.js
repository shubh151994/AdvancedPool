
/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Web3 = require('web3');
const config = require('./../../config.js');
const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.rinkeby));
const TX = require('ethereumjs-tx').Transaction;

const privateKey = Buffer.from(config.privateKey.rinkeby,'hex');

const DiamondContractAddress = "0x4d5A1b515accf195393471dc109470F85c551416";
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
    "stateMutability": "payable",
    "type": "receive",
    "payable": true
  },
  {
    "inputs": [
      {
        "internalType": "contract IERC20",
        "name": "_coin",
        "type": "address"
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
        "internalType": "uint256",
        "name": "_maxWithdrawalAllowed",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "_owner",
        "type": "address"
      },
      {
        "internalType": "contract DepositStrategy",
        "name": "_depositStrategy",
        "type": "address"
      },
      {
        "internalType": "contract UniswapV2Router02",
        "name": "_uniswapRouter",
        "type": "address"
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
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "unstake",
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
    "inputs": [],
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
    "inputs": [],
    "name": "removeFromStrategy",
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
      },
      {
        "internalType": "uint256",
        "name": "_maxWithdrawalAllowed",
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
        "name": "amountOfStableCoins",
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
    "inputs": [],
    "name": "maxWithdrawal",
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
    "inputs": [],
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
    "inputs": [],
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
    "inputs": [],
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
    "inputs": [],
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
    "inputs": [],
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
  },
  {
    "inputs": [],
    "name": "lockStatus",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [],
    "name": "totalDeposit",
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
    "name": "strategyDeposit",
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
    "inputs": [],
    "name": "currentFees",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      },
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
    "name": "claimGasFee",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "convertFeesToETH",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
const AdvancePoolAddr = "0x978ff0A8506F3f73ba3649d6081CC3428705be22";

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

async function initializeAdvancedPool(){
  try{
  const coins = "0x92D97AB672F71e029DfbC18f01E615c3637b1c95"
  const poolToken = "0x8A76eADe0fAf10A33FE63f78C828d583a4f19EdE"
  const minLiq = 1000
  const maxLiq = 3000
  const withFee = 50
  const depFee = 50
  const _maxWithdrawalAllowed = 1000000000
  const owner = config.publicKey.rinkeby
  const depStrategies = "0x0b2cfdd4561df95b20FCBC582a521b02374Db54c"
  const UniswapV2Router02 = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
 
  
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
        _maxWithdrawalAllowed,
        owner,
        depStrategies,
        UniswapV2Router02
      ).encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0)
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

async function addTosTrategy(){
  try{
  
  console.log("1111111111")
  const bridgeCall = new web3.eth.Contract(AdvancedPoolABI, DiamondContractAddress);
  const functCall = await bridgeCall.methods
      .addToStrategy().encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0)
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};
  

addTosTrategy()


/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Web3 = require('web3');
const config = require('./../../config.js');
const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.rinkeby));
const TX = require('ethereumjs-tx').Transaction;

const privateKey = Buffer.from(config.privateKey.rinkeby,'hex');

const DiamondContractAddress = "0xf20149EfEe7a4f709755c96AaDa9b8AFf1e3ca9c";
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
const ControllerAbi =[
  {
    "stateMutability": "payable",
    "type": "receive",
    "payable": true
  },
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "_depositStrategies",
        "type": "address[]"
      },
      {
        "internalType": "address[]",
        "name": "_pools",
        "type": "address[]"
      },
      {
        "internalType": "contract Gauge[]",
        "name": "_gauges",
        "type": "address[]"
      },
      {
        "internalType": "contract IERC20[]",
        "name": "_strategyLPToken",
        "type": "address[]"
      },
      {
        "internalType": "contract Minter",
        "name": "_minter",
        "type": "address"
      },
      {
        "internalType": "contract IERC20",
        "name": "_crvToken",
        "type": "address"
      },
      {
        "internalType": "contract VotingEscrow",
        "name": "_votingEscrow",
        "type": "address"
      },
      {
        "internalType": "contract FeeDistributor",
        "name": "_feeDistributor",
        "type": "address"
      },
      {
        "internalType": "contract UniswapV2Router",
        "name": "_uniswapRouter",
        "type": "address"
      },
      {
        "internalType": "address[]",
        "name": "_owners",
        "type": "address[]"
      },
      {
        "internalType": "uint256",
        "name": "_crvLockPercent",
        "type": "uint256"
      },
      {
        "internalType": "contract IERC20",
        "name": "_adminFeeToken",
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
        "internalType": "address",
        "name": "newOwner",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "newSuperOwner",
        "type": "address"
      }
    ],
    "name": "updateOwners",
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
        "name": "_strategy",
        "type": "address"
      },
      {
        "internalType": "contract Gauge",
        "name": "_gauge",
        "type": "address"
      },
      {
        "internalType": "contract IERC20",
        "name": "_strategyLPToken",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_pool",
        "type": "address"
      }
    ],
    "name": "addNewStrategy",
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
        "internalType": "contract IERC20",
        "name": "_adminFeeToken",
        "type": "address"
      }
    ],
    "name": "updateAdminFeeToken",
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
        "name": "_value",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_unlockTime",
        "type": "uint256"
      }
    ],
    "name": "createLock",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "releaseLock",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_value",
        "type": "uint256"
      }
    ],
    "name": "increaseLockAmount",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "_value",
        "type": "uint256"
      }
    ],
    "name": "increaseUnlockTime",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "claimAndConvertAdminFees",
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
        "name": "_newPercent",
        "type": "uint256"
      }
    ],
    "name": "updateLockPercentage",
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
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "stake",
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
    "name": "unstakeAll",
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
    "name": "claimCRV",
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
        "name": "_gasUsed",
        "type": "uint256"
      },
      {
        "internalType": "address",
        "name": "adminAddress",
        "type": "address"
      }
    ],
    "name": "updateGasUsed",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
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
    "name": "defaultGas",
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
    "name": "availableCRVToLock",
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
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "gasUsed",
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
    "name": "crvLockPercent",
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
const ControllerAddr = "0x030382492f581Eb4fca760db2F89b01E23afCcE4";
const zeroAddress = '0x0000000000000000000000000000000000000000'


const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2
}

const transact = async (data, value) => {
  //  console.log(data, contractAddress, holderAddress, privateKey, value)
       try {
           var count = await web3.eth.getTransactionCount(deployerAddress);
           // var gasPrice = await web3.eth.getGasPrice();
           var txData = {
               nonce: web3.utils.toHex(count),
               gasLimit: web3.utils.toHex(3000000),
               gasPrice: 10000000000,
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

// FUNCTION TO ADD FACET
async function addFacet(){
  try{
  console.log("adding facet")
  const facetCutCall = new web3.eth.Contract(CutABI, DiamondContractAddress);
  const Part1Call = new web3.eth.Contract(ControllerAbi, ControllerAddr)
 
  let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  selectorspart1.push('0x00000000');
  console.log("selectors",selectorspart1)
  const functCall = await facetCutCall.methods.diamondCut([[ControllerAddr, FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
  const receipt = await transact(functCall, 0 )
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

async function initializeController(){
  try{
  const strategires = ["0x64DD59A9CE549C5925befe4DD1c9894c316F7648"]
  const pool = ["0x7ADFF52984c6aAdfC70445E993443387c12eBFB9"]
  const gauges = ["0xF0C904b796a913Ae483E6fd6e0b36dF527849784"];
  const curveStrategyLPTOken = ["0x8AEb59e352F2bCBb9e5D45aeF7265Ede0cae73E5"]
  const minter = "0xAde9c3e4F7E7D97F0aD2f3a68c8E65524C789078"
  const crvToken = "0x34Be66A99E634D9E5ed4E2552Adc5892B0699f14"
  const veCRV = "0xe1187A7aD69Af79d9706E2f118a89e1438225825"
  const feeDistributor = "0x140fCf94762Fe2C64D998F6CD7812Ef3e7877Fb2"
  const uniswap = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
  const controllerOwners = [config.publicKey.rinkeby,config.publicKey.rinkeby]
  const crvLockPercent = "2000"
  const adminFeeToken = "0x8AEb59e352F2bCBb9e5D45aeF7265Ede0cae73E5"
  
  console.log("initializing controller")
  const diamondCall = new web3.eth.Contract(ControllerAbi, DiamondContractAddress);
  const functCall = await diamondCall.methods
      .initialize(
        strategires, 
        pool,
        gauges,
        curveStrategyLPTOken, 
        minter,
        crvToken,
        veCRV,
        feeDistributor,
        uniswap,
        controllerOwners,
        crvLockPercent,
        adminFeeToken
      ).encodeABI();
  const receipt = await transact(functCall, 0)
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

initializeController()
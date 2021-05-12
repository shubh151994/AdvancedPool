
/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Web3 = require('web3');
const config = require('./../../config.js');
const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.rinkeby));
const TX = require('ethereumjs-tx').Transaction;

const privateKey = Buffer.from(config.privateKey.rinkeby,'hex');

const DiamondContractAddress = "0xcD85a2327D8858f091A9204a10f5e815E807D649";
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
const ControllerAbi =   [
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "_depositStrategies",
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
        "internalType": "address",
        "name": "_controllerOwner",
        "type": "address"
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
    "inputs": [],
    "name": "unstake",
    "outputs": [],
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
    "inputs": [],
    "name": "claimAndConverAdminFees",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "",
        "type": "uint256"
      }
    ],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]
const ControllerAddr = "0x2349f4c0063c85230EdE2950C962a83Bf125e643";

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
  const Part1Call = new web3.eth.Contract(ControllerAbi, ControllerAddr)
 
  let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  
  console.log("33333333333333333",selectorspart1)
  const functCall = await facetCutCall.methods
      .diamondCut([[ControllerAddr, FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
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


async function initializeController(){
  try{
  const strategires = ["0x0b2cfdd4561df95b20FCBC582a521b02374Db54c"]
  const gauges = ["0xF0C904b796a913Ae483E6fd6e0b36dF527849784"];
  const strategyLPTOken = ["0x8AEb59e352F2bCBb9e5D45aeF7265Ede0cae73E5"]
  const minter = "0xAde9c3e4F7E7D97F0aD2f3a68c8E65524C789078"
  const crv = "0x34Be66A99E634D9E5ed4E2552Adc5892B0699f14"
  const veCRV = "0xe1187A7aD69Af79d9706E2f118a89e1438225825"
  const feeDistributor = "0x140fCf94762Fe2C64D998F6CD7812Ef3e7877Fb2"
  const uniswap = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
  const controllerOwner = config.publicKey.rinkeby
  const crvLockPercent = "2000"
  const _adminFeeToken = "0x8AEb59e352F2bCBb9e5D45aeF7265Ede0cae73E5"
  
  console.log("1111111111")
  const diamondCall = new web3.eth.Contract(ControllerAbi, DiamondContractAddress);
  const functCall = await diamondCall.methods
      .initialize(
        strategires, 
        gauges,
        strategyLPTOken, 
        minter,
        crv,
        veCRV,
        feeDistributor,
        uniswap,
        controllerOwner,
        crvLockPercent,
        _adminFeeToken
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


async function addFacet2(){
  try{
  console.log("1111111111")
  const facetCutCall = new web3.eth.Contract(CutABI, DiamondContractAddress);
  const Part1Call = new web3.eth.Contract( [
    {
      "inputs": [],
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
    }
  ], "0x3Fa9914A0544123d411e5fBebDC59a4348b6B850")
 
  let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  
  console.log("33333333333333333",selectorspart1)
  const functCall = await facetCutCall.methods
      .diamondCut([["0x3Fa9914A0544123d411e5fBebDC59a4348b6B850", FacetCutAction.Replace, selectorspart1 ]], zeroAddress, '0x').encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0 )
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

addFacet2()
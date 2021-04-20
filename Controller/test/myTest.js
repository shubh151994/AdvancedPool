
/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Web3 = require('web3');
const config = require('./../config.js');
const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.rinkeby));
const TX = require('ethereumjs-tx').Transaction;

const privateKey = Buffer.from(config.privateKey.rinkeby,'hex');

const DiamondContractAddress = "0x2aA2d29d3f312F2508aBDa55b40e2805D4312207";
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
const TriPoolStrategyABI =   [
  {
    "inputs": [
      {
        "internalType": "contract Pool",
        "name": "_poolAddress",
        "type": "address"
      },
      {
        "internalType": "contract Gauge",
        "name": "_gauge",
        "type": "address"
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
        "internalType": "contract IERC20",
        "name": "_poolToken",
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
        "internalType": "contract IERC20[3]",
        "name": "_coins",
        "type": "address[3]"
      },
      {
        "internalType": "contract UniswapV2Router",
        "name": "_uniswapRouter",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_poolOwner",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_crvLockPercent",
        "type": "uint256"
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
        "internalType": "contract IERC20",
        "name": "_rewardCoin",
        "type": "address"
      }
    ],
    "name": "setRewardCoin",
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
        "internalType": "uint256[10]",
        "name": "amounts",
        "type": "uint256[10]"
      }
    ],
    "name": "deposit",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256[10]",
        "name": "amounts",
        "type": "uint256[10]"
      }
    ],
    "name": "withdraw",
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
    "name": "claimAndConvert3CRV",
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
    "name": "convertCRV",
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

const TriPoolStrategyAddr = "0x03b1cc08d707ecAD7A7471Ed1a978dE773ab2B5c";

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
  const Part1Call = new web3.eth.Contract(TriPoolStrategyABI, TriPoolStrategyAddr)
 
  let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  
  console.log("33333333333333333",selectorspart1)
  const functCall = await facetCutCall.methods
      .diamondCut([ [TriPoolStrategyAddr, FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
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


async function initializeTriPoolStrategy(){
  try{
  const poolAddress = "0x2CC463cc7818d6f582a28444c8E9565942110667"
  const gauge = "0x6834a4381Dd06e4a7ea27d8C879E368a879d2104";
  const minter = "0x2c90e72766607c45D2113D0BbE911cd48102fCb5"
  const crv = "0xaDcb0EAe0227bD76Ea914f0744af4AD6e7c1563e"
  const poolToken = "0xc6FefF33f57242451F104d842E3D86Eef81C6E1B"
  const veCRV = "0x2183D62Cf4811081A42E6cE19ef64e10F150BbC8"
  const feeDistributor = "0xE02E339D8bD5958f049c48756d15b6f58211Eee2"
  const coins = ["0x66f58Db4aA308EB6C17F5e23dB7a075D65c90577","0x92D97AB672F71e029DfbC18f01E615c3637b1c95","0x0CF6bc00DCeF87983C641BF850fa11Aa3811Cd62"]
  const uniswap = "0xE02E339D8bD5958f049c48756d15b6f58211Eee2"
  const poolOwner = config.publicKey.rinkeby
  const crvLockPercent = "2000"
  
  console.log("1111111111")
  const diamondCall = new web3.eth.Contract(TriPoolStrategyABI, DiamondContractAddress);
  const functCall = await diamondCall.methods
      .initialize(
        poolAddress, 
        gauge,
        minter, 
        crv,
        poolToken,
        veCRV,
        feeDistributor,
        coins,
        uniswap,
        poolOwner,
        crvLockPercent
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

initializeTriPoolStrategy()
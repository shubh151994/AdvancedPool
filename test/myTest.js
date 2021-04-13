
/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Web3 = require('web3');
const config = require('./../config.js');
const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.ropsten));
const TX = require('ethereumjs-tx').Transaction;

const privateKey = Buffer.from(config.privateKey.ropsten,'hex');

const DiamondContractAddress = "0x50Ad2135d67fcE105475Fa40F0f31FF1a1717952";
const deployerAddress = config.publicKey.ropsten;

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
const EosToEthPart1ABI =   [
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "bytes",
        "name": "reason",
        "type": "bytes"
      }
    ],
    "name": "Failure",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "address",
        "name": "recipient",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "bytes",
        "name": "reason",
        "type": "bytes"
      }
    ],
    "name": "Receipt",
    "type": "event"
  },
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "address",
        "name": "recipient",
        "type": "address"
      },
      {
        "indexed": false,
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "indexed": false,
        "internalType": "bytes",
        "name": "reason",
        "type": "bytes"
      }
    ],
    "name": "Refund",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      },
      {
        "internalType": "bytes",
        "name": "_message",
        "type": "bytes"
      }
    ],
    "name": "pushInboundMessage",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "stateMutability": "payable",
    "type": "receive",
    "payable": true
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      }
    ],
    "name": "sendToken",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "claimGas",
    "outputs": [
      {
        "internalType": "bool",
        "name": "",
        "type": "bool"
      }
    ],
    "stateMutability": "payable",
    "type": "function",
    "payable": true
  }
]

const EosToEthPart2ABI =  [
  {
    "anonymous": false,
    "inputs": [
      {
        "indexed": false,
        "internalType": "bytes",
        "name": "reason",
        "type": "bytes"
      }
    ],
    "name": "Failure",
    "type": "event"
  },
  {
    "inputs": [
      {
        "internalType": "address[]",
        "name": "_owners",
        "type": "address[]"
      },
      {
        "internalType": "uint8[2]",
        "name": "thresholds",
        "type": "uint8[2]"
      },
      {
        "internalType": "address[]",
        "name": "_token_contracts",
        "type": "address[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_EOS_precision",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_ethereum_precision",
        "type": "uint256[]"
      },
      {
        "internalType": "address",
        "name": "_uniswapRouter",
        "type": "address"
      },
      {
        "internalType": "address",
        "name": "_ethToEosBridge",
        "type": "address"
      },
      {
        "internalType": "uint256[]",
        "name": "_max_mint_period_amount",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_max_mint_period",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256[]",
        "name": "_max_mint_allowed",
        "type": "uint256[]"
      },
      {
        "internalType": "uint256",
        "name": "_min_eth_required",
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
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      }
    ],
    "name": "tokenConfigs",
    "outputs": [
      {
        "components": [
          {
            "internalType": "uint256",
            "name": "max_mint_allowed",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "max_mint_period_amount",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "max_mint_period",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "EOS_precision",
            "type": "uint256"
          },
          {
            "internalType": "uint256",
            "name": "ethereum_precision",
            "type": "uint256"
          }
        ],
        "internalType": "struct BridgeStorageV1.Config",
        "name": "tokenConfig",
        "type": "tuple"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [],
    "name": "contractParams",
    "outputs": [
      {
        "internalType": "uint256[6]",
        "name": "counters",
        "type": "uint256[6]"
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
    "name": "isOwner",
    "outputs": [
      {
        "internalType": "bool",
        "name": "result",
        "type": "bool"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [],
    "name": "isLocked",
    "outputs": [
      {
        "internalType": "bool",
        "name": "result",
        "type": "bool"
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
        "name": "tokenId",
        "type": "uint256"
      }
    ],
    "name": "currentWithdrawalAmount",
    "outputs": [
      {
        "internalType": "uint256[2]",
        "name": "result",
        "type": "uint256[2]"
      }
    ],
    "stateMutability": "view",
    "type": "function",
    "constant": true
  },
  {
    "inputs": [],
    "name": "contractOwner",
    "outputs": [
      {
        "internalType": "address",
        "name": "result",
        "type": "address"
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
        "name": "_token_address",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_max_mint_period_amount",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_max_mint_period",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_max_mint_allowed",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_EOS_precision",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "_ethereum_precision",
        "type": "uint256"
      }
    ],
    "name": "addNewToken",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint64",
        "name": "batch_id",
        "type": "uint64"
      }
    ],
    "name": "getBatch",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "id",
        "type": "uint256"
      },
      {
        "internalType": "bytes",
        "name": "data",
        "type": "bytes"
      },
      {
        "internalType": "uint256",
        "name": "block_num",
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
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "tokenId",
        "type": "uint256"
      }
    ],
    "name": "approvePoolBalance",
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
        "internalType": "address payable",
        "name": "account",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      }
    ],
    "name": "sendEther",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "changeLockByOwner",
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
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "address",
        "name": "account",
        "type": "address"
      }
    ],
    "name": "dspGasUsed",
    "outputs": [
      {
        "internalType": "uint256",
        "name": "result",
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
        "internalType": "address[]",
        "name": "_owners",
        "type": "address[]"
      },
      {
        "internalType": "uint256",
        "name": "required",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "required_secure",
        "type": "uint256"
      }
    ],
    "name": "modifyConsensus",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  }
]

const EosToEthPart1Addr = "0x76013d346fe69f4B69EA9d90735f627aa64A3524";
const EosToEthPart2Addr = "0xba83840849d04352352E7480cacb854743207E32";

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
            var transaction = new TX(txData,{chain:'ropsten', hardfork:'petersburg'});
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
  const Part1Call = new web3.eth.Contract(EosToEthPart1ABI, EosToEthPart1Addr)
  const Part2Call = new web3.eth.Contract(EosToEthPart2ABI, EosToEthPart2Addr)
 
  let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  let selectorspart2 = getSelectors(Part2Call._jsonInterface);
  

   console.log("33333333333333333",selectorspart1,"ddd",selectorspart2)
  const functCall = await facetCutCall.methods
      .diamondCut([ [EosToEthPart1Addr, FacetCutAction.Add, selectorspart1 ] ,[EosToEthPart1Addr, FacetCutAction.Add, selectorspart2 ]], zeroAddress, '0x').encodeABI();
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


async function initializeTokenpeg(){
  try{
  const owners = [config.publicKey.ropsten,"0x14944Cf5Ff68161F7d047938Dc2ec4B18BA54e59","0x676956B7E476bc51d2676A48a5E3F81742fe8fC5"]
  const thresholds = [1,1];
  const token_contract = ["0x2c90e72766607c45D2113D0BbE911cd48102fCb5"]
  const _EOS_precision = [4]
  const _eth_pre = [4]
  const _uniswapRouter = "0x7a250d5630b4cf539739df2c5dacb4c659f2488d"
  const ethToEosBridge = "0xAf11176d5D03d8587CDaF884c2f800AaE82C9aD2"
  const _max_mint_period_amount = ["500000000"]
  const _max_mint_period = [2]
  const _max_mint_allowed = ["100000000"]
  const _min_eth_required = "1000000000000000000"
  
  console.log("1111111111")
  const bridgeCall = new web3.eth.Contract(EosToEthPart2ABI, DiamondContractAddress);
  const functCall = await bridgeCall.methods
      .initialize(
        owners, 
        thresholds,
        token_contract, 
        _EOS_precision,
        _eth_pre,
        _uniswapRouter,
        ethToEosBridge,
        _max_mint_period_amount,
        _max_mint_period,
        _max_mint_allowed,
        _min_eth_required
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

sendToken()
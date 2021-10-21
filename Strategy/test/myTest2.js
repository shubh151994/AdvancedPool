
/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Web3 = require('web3');
const config = require('../../config.js');
const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.rinkeby));
const TX = require('ethereumjs-tx').Transaction;

const privateKey = Buffer.from(config.privateKey.rinkeby,'hex');

const DiamondContractAddress = "0x8A8BE79d217EdF91d4939184312F8997598D2d56";
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
const StrategyABI = [
  {
    "inputs": [
      {
        "internalType": "contract CurvePool",
        "name": "_curvePool",
        "type": "address"
      },
      {
        "internalType": "contract IERC20",
        "name": "_curvePoolToken",
        "type": "address"
      },
      {
        "internalType": "contract IERC20",
        "name": "_crvToken",
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
        "name": "_pool",
        "type": "address"
      },
      {
        "internalType": "contract Controller",
        "name": "_controller",
        "type": "address"
      },
      {
        "internalType": "uint256",
        "name": "_coinIndex",
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
        "name": "amount",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "minMintAmount",
        "type": "uint256"
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
        "internalType": "uint256",
        "name": "amount",
        "type": "uint256"
      },
      {
        "internalType": "uint256",
        "name": "maxBurnAmount",
        "type": "uint256"
      }
    ],
    "name": "withdraw",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {
        "internalType": "uint256",
        "name": "minAmount",
        "type": "uint256"
      }
    ],
    "name": "withdrawAll",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "claimAndConvertCRV",
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

const StrategyAddr = "0x9009D0A5D8E73B62080EB0C16C60C4b0EC0a3Fc9";
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
async function addStakedAmount(){
  try{
  console.log("adding facet")
  const abi =[
    {
      "inputs": [],
      "name": "depositedAmount",
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
      "name": "curveLPTokenPrice",
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
  const addr = "0x242Efa5a0c06871D9c86746Ab4A4e93Caafc3495"
  const facetCutCall = new web3.eth.Contract(CutABI, DiamondContractAddress);
  const Part1Call = new web3.eth.Contract(abi, addr)
 
  let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  console.log("selectors",selectorspart1)
  const functCall = await facetCutCall.methods.diamondCut([[addr, FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
  const receipt = await transact(functCall, 0 )
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

async function initializeStrategy(){
  try{
  const ironBank = "0x486270838d9d09377bc01a3cc5a97f9a776ad87a"
  const ironBankToken = "0x8AEb59e352F2bCBb9e5D45aeF7265Ede0cae73E5"
  const crvToken = "0x34Be66A99E634D9E5ed4E2552Adc5892B0699f14"
  const coins = ["0x66f58Db4aA308EB6C17F5e23dB7a075D65c90577","0x92D97AB672F71e029DfbC18f01E615c3637b1c95","0x0CF6bc00DCeF87983C641BF850fa11Aa3811Cd62"]
  const uniswap = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
  const pool = "0x222bE15ED0840A52361AFE945F0e110535f2FbE7"
  const controller = "0xf20149EfEe7a4f709755c96AaDa9b8AFf1e3ca9c"
  const coinIndex = 1
  
  console.log("initializing strategy")
  const diamondCall = new web3.eth.Contract(StrategyABI, DiamondContractAddress);
  const functCall = await diamondCall.methods
      .initialize(
        ironBank, 
        ironBankToken,
        crvToken,
        coins,
        uniswap,
        pool,
        controller,
        coinIndex
      ).encodeABI();
  const receipt = await transact(functCall, 0)
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};


async function addFacet(){
  try{
  console.log("1111111111")
  const facetCutCall = new web3.eth.Contract(CutABI, DiamondContractAddress);
  const Part1Call = new web3.eth.Contract(StrategyABI, StrategyAddr)
 
  let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  
  console.log("33333333333333333",selectorspart1)
  const functCall = await facetCutCall.methods
      .diamondCut([ [StrategyAddr, FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0 )
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

addStakedAmount()
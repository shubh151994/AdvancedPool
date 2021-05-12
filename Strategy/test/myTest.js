
/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Web3 = require('web3');
const config = require('./../../config.js');
const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.rinkeby));
const TX = require('ethereumjs-tx').Transaction;

const privateKey = Buffer.from(config.privateKey.rinkeby,'hex');

const DiamondContractAddress = "0x0b2cfdd4561df95b20FCBC582a521b02374Db54c";
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
const TriPoolStrategyABI = [
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
      }
    ],
    "name": "withdraw",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [],
    "name": "claimAndConverCRV",
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

const TriPoolStrategyAddr = "0x5d0fbEEe100608D3A5743D7045B6cDFCa88b3fb8";

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
      .diamondCut([ [TriPoolStrategyAddr, FacetCutAction.Replace, selectorspart1 ]], zeroAddress, '0x').encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0 )
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

async function initializeTriPoolStrategy(){
  try{
  const crvPool = "0xE00ee2D77fDdC63438BEF441153f58c249E12adF"
  const crvPoolToken = "0x8AEb59e352F2bCBb9e5D45aeF7265Ede0cae73E5"
  const crv = "0x34Be66A99E634D9E5ed4E2552Adc5892B0699f14"
  const coins = ["0x66f58Db4aA308EB6C17F5e23dB7a075D65c90577","0x92D97AB672F71e029DfbC18f01E615c3637b1c95","0x0CF6bc00DCeF87983C641BF850fa11Aa3811Cd62"]
  const uniswap = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
  const pool = "0x4d5A1b515accf195393471dc109470F85c551416"
  const controller = "0xcD85a2327D8858f091A9204a10f5e815E807D649"
  const coinIndex = 1
  
  console.log("1111111111")
  const diamondCall = new web3.eth.Contract(TriPoolStrategyABI, DiamondContractAddress);
  const functCall = await diamondCall.methods
      .initialize(
        crvPool, 
        crvPoolToken,
        crv,
        coins,
        uniswap,
        pool,
        controller,
        coinIndex
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
  const Part1Call = new web3.eth.Contract([
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
      "name": "initialize2",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ], "0x021115E654CA7c0De33c9e3A2bd033E5E1503e30")
 
  let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  
  console.log("33333333333333333",selectorspart1)
  const functCall = await facetCutCall.methods
      .diamondCut([ ["0x021115E654CA7c0De33c9e3A2bd033E5E1503e30", FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
      console.log("444444444444444444444")
  const receipt = await transact(functCall, 0 )
  console.log(receipt)
  } catch(e) {
      console.log('in catch2')
      throw new Error(e);
  }

};

addFacet()
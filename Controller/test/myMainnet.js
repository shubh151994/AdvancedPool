
/* eslint-disable prefer-const */
/* global contract artifacts web3 before it assert */

const Web3 = require('web3');
const config = require('../../config.js');
const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.mainnet));
const TX = require('ethereumjs-tx').Transaction;

const privateKey = Buffer.from(config.privateKey.mainnet,'hex');

const DiamondContractAddress = "0x3530b6ee53ed128c871612B59340f1192457e834";
const deployerAddress = config.publicKey.mainnet;

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
const ControllerAddr = "0xBb22D318e43AA978469850F88d7255E2e7a2d9EF";
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
               gasPrice: 15000000000,
               to: DiamondContractAddress,
               from: deployerAddress,
               data: data, 
               value: value
           }
           var transaction = new TX(txData,{chain:'mainnet', hardfork:'petersburg'});
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

// // FUNCTION TO ADD FACET
// async function addFacet(){
//   try{
//   console.log("adding facet")
//   const facetCutCall = new web3.eth.Contract(CutABI, DiamondContractAddress);
//   const Part1Call = new web3.eth.Contract(ControllerAbi, ControllerAddr)
 
//   let selectorspart1 = getSelectors(Part1Call._jsonInterface);
//   selectorspart1.push('0x00000000');
//   console.log("selectors",selectorspart1)
//   const functCall = await facetCutCall.methods.diamondCut([[ControllerAddr, FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
//   const receipt = await transact(functCall, 0 )
//   console.log(receipt)
//   } catch(e) {
//       console.log('in catch2')
//       throw new Error(e);
//   }

// };

async function initializeController(){
  try{
  const strategires = ["0xF63BcdBB1CB19010774f261d986633FB8096416D"]
  const pool = ["0xb8c3Bd6392F61Ad3278aEed7dC93c6cF7d807aB7"]
  const gauges = ["0xF5194c3325202F456c95c1Cf0cA36f8475C1949F"];
  const curveStrategyLPTOken = ["0x5282a4eF67D9C33135340fB3289cc1711c13638C"]
  const minter = "0xd061D61a4d941c39E5453435B6345Dc261C2fcE0"
  const crvToken = "0xD533a949740bb3306d119CC777fa900bA034cd52"
  const veCRV = "0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2"
  const feeDistributor = "0xA464e6DCda8AC41e03616F95f4BC98a13b8922Dc"
  const uniswap = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
  const controllerOwners = ['0x4a1eA4E24D2bbb48bEB5AA0F3d47fa4c3D5714F6','0xc9C9399E18190b7536e1aED60ba1D8318c3f3DE6']
  const crvLockPercent = "5000"
  const adminFeeToken = "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490"
  
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
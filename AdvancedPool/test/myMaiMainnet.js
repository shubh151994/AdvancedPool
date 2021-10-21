
// /* eslint-disable prefer-const */
// /* global contract artifacts web3 before it assert */

// const Web3 = require('web3');
// const config = require('../../config.js');
// const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.mainnet));
// const TX = require('ethereumjs-tx').Transaction;

// const privateKey = Buffer.from(config.privateKey.mainnet,'hex');

// const DiamondContractAddress = "0xE3a6c116BeE3aA23431dBE35d9182338cA4e6bfc";
// const deployerAddress = config.publicKey.mainnet;

// const CutABI =   [
//   {
//     "anonymous": false,
//     "inputs": [
//       {
//         "components": [
//           {
//             "internalType": "address",
//             "name": "facetAddress",
//             "type": "address"
//           },
//           {
//             "internalType": "enum IDiamondCut.FacetCutAction",
//             "name": "action",
//             "type": "uint8"
//           },
//           {
//             "internalType": "bytes4[]",
//             "name": "functionSelectors",
//             "type": "bytes4[]"
//           }
//         ],
//         "indexed": false,
//         "internalType": "struct IDiamondCut.FacetCut[]",
//         "name": "_diamondCut",
//         "type": "tuple[]"
//       },
//       {
//         "indexed": false,
//         "internalType": "address",
//         "name": "_init",
//         "type": "address"
//       },
//       {
//         "indexed": false,
//         "internalType": "bytes",
//         "name": "_calldata",
//         "type": "bytes"
//       }
//     ],
//     "name": "DiamondCut",
//     "type": "event"
//   },
//   {
//     "inputs": [
//       {
//         "components": [
//           {
//             "internalType": "address",
//             "name": "facetAddress",
//             "type": "address"
//           },
//           {
//             "internalType": "enum IDiamondCut.FacetCutAction",
//             "name": "action",
//             "type": "uint8"
//           },
//           {
//             "internalType": "bytes4[]",
//             "name": "functionSelectors",
//             "type": "bytes4[]"
//           }
//         ],
//         "internalType": "struct IDiamondCut.FacetCut[]",
//         "name": "_diamondCut",
//         "type": "tuple[]"
//       },
//       {
//         "internalType": "address",
//         "name": "_init",
//         "type": "address"
//       },
//       {
//         "internalType": "bytes",
//         "name": "_calldata",
//         "type": "bytes"
//       }
//     ],
//     "name": "diamondCut",
//     "outputs": [],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   }
// ]
// const AdvancedPoolABI =  [
//   {
//     "anonymous": false,
//     "inputs": [
//       {
//         "indexed": false,
//         "internalType": "address",
//         "name": "user",
//         "type": "address"
//       },
//       {
//         "indexed": false,
//         "internalType": "address",
//         "name": "pool",
//         "type": "address"
//       },
//       {
//         "indexed": false,
//         "internalType": "uint256",
//         "name": "amount",
//         "type": "uint256"
//       }
//     ],
//     "name": "poolDeposit",
//     "type": "event"
//   },
//   {
//     "anonymous": false,
//     "inputs": [
//       {
//         "indexed": false,
//         "internalType": "address",
//         "name": "user",
//         "type": "address"
//       },
//       {
//         "indexed": false,
//         "internalType": "address",
//         "name": "pool",
//         "type": "address"
//       },
//       {
//         "indexed": false,
//         "internalType": "uint256",
//         "name": "amount",
//         "type": "uint256"
//       }
//     ],
//     "name": "poolWithdrawal",
//     "type": "event"
//   },
//   {
//     "anonymous": false,
//     "inputs": [
//       {
//         "indexed": false,
//         "internalType": "address",
//         "name": "user",
//         "type": "address"
//       },
//       {
//         "indexed": false,
//         "internalType": "uint256",
//         "name": "amount",
//         "type": "uint256"
//       }
//     ],
//     "name": "userDeposits",
//     "type": "event"
//   },
//   {
//     "anonymous": false,
//     "inputs": [
//       {
//         "indexed": false,
//         "internalType": "address",
//         "name": "user",
//         "type": "address"
//       },
//       {
//         "indexed": false,
//         "internalType": "uint256",
//         "name": "amount",
//         "type": "uint256"
//       }
//     ],
//     "name": "userWithdrawal",
//     "type": "event"
//   },
//   {
//     "stateMutability": "payable",
//     "type": "receive",
//     "payable": true
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "contract IERC20",
//         "name": "_coin",
//         "type": "address"
//       },
//       {
//         "internalType": "contract IERC20",
//         "name": "_poolToken",
//         "type": "address"
//       },
//       {
//         "internalType": "uint256",
//         "name": "_minLiquidity",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "_maxLiquidity",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "_withdrawFees",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "_depositFees",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "_maxWithdrawalAllowed",
//         "type": "uint256"
//       },
//       {
//         "internalType": "address[]",
//         "name": "_owners",
//         "type": "address[]"
//       },
//       {
//         "internalType": "contract DepositStrategy",
//         "name": "_depositStrategy",
//         "type": "address"
//       },
//       {
//         "internalType": "contract UniswapV2Router02",
//         "name": "_uniswapRouter",
//         "type": "address"
//       },
//       {
//         "internalType": "contract Controller",
//         "name": "_controller",
//         "type": "address"
//       }
//     ],
//     "name": "initialize",
//     "outputs": [],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "uint256",
//         "name": "amount",
//         "type": "uint256"
//       }
//     ],
//     "name": "stake",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "uint256",
//         "name": "amount",
//         "type": "uint256"
//       }
//     ],
//     "name": "unstake",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "uint256",
//         "name": "minMintAmount",
//         "type": "uint256"
//       }
//     ],
//     "name": "addToStrategy",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "uint256",
//         "name": "maxBurnAmount",
//         "type": "uint256"
//       }
//     ],
//     "name": "removeFromStrategy",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "uint256",
//         "name": "minAmount",
//         "type": "uint256"
//       }
//     ],
//     "name": "removeAllFromStrategy",
//     "outputs": [],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "uint256",
//         "name": "_minLiquidity",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "_maxLiquidity",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "_maxWithdrawalAllowed",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "maxBurnOrMinMint",
//         "type": "uint256"
//       }
//     ],
//     "name": "updateLiquidityParam",
//     "outputs": [
//       {
//         "internalType": "bool",
//         "name": "",
//         "type": "bool"
//       }
//     ],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "uint256",
//         "name": "_depositFees",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "_withdrawFees",
//         "type": "uint256"
//       }
//     ],
//     "name": "updateFees",
//     "outputs": [
//       {
//         "internalType": "bool",
//         "name": "",
//         "type": "bool"
//       }
//     ],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [],
//     "name": "changeLockStatus",
//     "outputs": [
//       {
//         "internalType": "bool",
//         "name": "",
//         "type": "bool"
//       }
//     ],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "address",
//         "name": "newOwner",
//         "type": "address"
//       },
//       {
//         "internalType": "address",
//         "name": "newSuperOwner",
//         "type": "address"
//       }
//     ],
//     "name": "updateOwners",
//     "outputs": [
//       {
//         "internalType": "bool",
//         "name": "",
//         "type": "bool"
//       }
//     ],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [],
//     "name": "getYield",
//     "outputs": [],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "contract DepositStrategy",
//         "name": "_newStrategy",
//         "type": "address"
//       }
//     ],
//     "name": "updateStrategy",
//     "outputs": [],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [],
//     "name": "convertFeesToETH",
//     "outputs": [],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "uint256",
//         "name": "amountOfStableCoins",
//         "type": "uint256"
//       }
//     ],
//     "name": "calculatePoolTokens",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "stableCoinPrice",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [
//       {
//         "internalType": "uint256",
//         "name": "amountOfPoolToken",
//         "type": "uint256"
//       }
//     ],
//     "name": "calculateStableCoins",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "poolTokenPrice",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "maxWithdrawal",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "currentLiquidity",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "idealAmount",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "maxLiquidityAllowedInPool",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "amountToDeposit",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "minLiquidityToMaintainInPool",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "amountToWithdraw",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "lockStatus",
//     "outputs": [
//       {
//         "internalType": "bool",
//         "name": "",
//         "type": "bool"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "totalDeposit",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "strategyDeposit",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "feesCollected",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "currentFees",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "currentLiquidityParams",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       },
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   },
//   {
//     "inputs": [],
//     "name": "owners",
//     "outputs": [
//       {
//         "internalType": "address",
//         "name": "",
//         "type": "address"
//       },
//       {
//         "internalType": "address",
//         "name": "",
//         "type": "address"
//       }
//     ],
//     "stateMutability": "view",
//     "type": "function",
//     "constant": true
//   }
// ]
// const AdvancePoolAddr = "0x5f3D9Ca3663Ac5eef94bF881d1A591A2995957bD";
// const zeroAddress = '0x0000000000000000000000000000000000000000'

// const FacetCutAction = {
//   Add: 0,
//   Replace: 1,
//   Remove: 2
// }

// const transact = async (data, value) => {
//    //  console.log(data, contractAddress, holderAddress, privateKey, value)
//         try {
//             var count = await web3.eth.getTransactionCount(deployerAddress);
//             // var gasPrice = await web3.eth.getGasPrice();
//             var txData = {
//                 nonce: web3.utils.toHex(count),
//                 gasLimit: web3.utils.toHex(3000000),
//                 gasPrice: 16000000000,
//                 to: DiamondContractAddress,
//                 from: deployerAddress,
//                 data: data, 
//                 value: value
//             }
//             var transaction = new TX(txData,{chain:'mainnet', hardfork:'petersburg'});
//             transaction.sign(privateKey);
//             var serialisedTransaction = transaction.serialize().toString('hex');
    
//             var receipt = await web3.eth.sendSignedTransaction('0x' + serialisedTransaction);
//             return receipt;
//         } catch(e) {
//                 console.log('in catch')
//                 throw new Error(e);
//     		}
// }

// function getSelectors (abi) {
//    // console.log(abi,'aaa')
//     const selectors = abi.reduce((acc, val) => {
//     // console.log(val, "valu");
//       if (val.type === 'function') {
//         acc.push(val.signature)
//         return acc
//       } else {
//         return acc
//       }
//     }, [])
//   console.log(selectors,"selectors");
//     return selectors
// }

// // FUNCTION TO ADD FACET
// // async function addFacet(){
// //   try{
// //   console.log("entry to add facet")
// //   const facetCutCall = new web3.eth.Contract(CutABI, DiamondContractAddress);
// //   const Part1Call = new web3.eth.Contract(AdvancedPoolABI, AdvancePoolAddr)
// //   let selectorspart1 = getSelectors(Part1Call._jsonInterface);
// //   selectorspart1.push('0x00000000');
// //   console.log("selectors",selectorspart1)
// //   const functCall = await facetCutCall.methods
// //       .diamondCut([ [AdvancePoolAddr, FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
// //   const receipt = await transact(functCall, 0 )
// //   console.log(receipt)
// //   } catch(e) {
// //       console.log('in catch2')
// //       throw new Error(e);
// //   }

// // };

// async function initializeAdvancedPool(){
//   try{
//   const coin = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
//   const poolToken = "0xf2ed604e0ac3a52b81eea7327f2196ec9474bf29"
//   const minLiq = 1000
//   const maxLiq = 3000
//   const withFee = 30
//   const depFee = 10
//   const maxWithdrawalAllowed = "100000000000"
//   const owners = ["0x4a1eA4E24D2bbb48bEB5AA0F3d47fa4c3D5714F6","0xc9C9399E18190b7536e1aED60ba1D8318c3f3DE6"]
//   const depStrategies = "0xf321962e27B22BDF0d34b5BdbC016ACba1166810"
//   const UniswapV2Router02 = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
//   const controller = "0x3530b6ee53ed128c871612B59340f1192457e834"
  
//   console.log("initializing advanced pool")
//   const bridgeCall = new web3.eth.Contract(AdvancedPoolABI, DiamondContractAddress);
//   const functCall = await bridgeCall.methods
//       .initialize(
//         coin, 
//         poolToken,
//         minLiq, 
//         maxLiq,
//         withFee,
//         depFee,
//         maxWithdrawalAllowed,
//         owners,
//         depStrategies,
//         UniswapV2Router02,
//         controller
//       ).encodeABI();
//   const receipt = await transact(functCall, 0)
//   console.log(receipt)
//   } catch(e) {
//       console.log('in catch2')
//       throw new Error(e);
//   }

// };


// // async function addFacet2(){
// //     try{
// //     console.log("entry to add facet")
// //     const facetCutCall = new web3.eth.Contract(CutABI, DiamondContractAddress);
// //     const functCall = await facetCutCall.methods
// //         .diamondCut([["0xcfd6b5f2b5e8cbd0549b6b9c05f85a2033b6790c",1,['0xa694fc3a','0x2e17de78','0x7039206b','0x4b366863','0x4076245f','0xfc0a497e','0xdaccaf63','0xc3c9f52b','0x5b404bad','0x8a98cdd4','0xe4255342','0x8c0ff5b7','0x46caf2ae','0x077622a2','0xb4ad5e08','0xfe135c0e','0x7260cc76','0x269fa128','0xf6153ccd','0x31dd132e']]], zeroAddress, '0x').encodeABI();
// //     const receipt = await transact(functCall, 0 )
// //     console.log(receipt)
// //     } catch(e) {
// //         console.log('in catch2')
// //         throw new Error(e);
// //     }
// //   }


// initializeAdvancedPool()
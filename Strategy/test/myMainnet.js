
// /* eslint-disable prefer-const */
// /* global contract artifacts web3 before it assert */

// const Web3 = require('web3');
// const config = require('../../config.js');
// const web3 = new Web3(new Web3.providers.HttpProvider(config.nodeURL.mainnet));
// const TX = require('ethereumjs-tx').Transaction;

// const privateKey = Buffer.from(config.privateKey.mainnet,'hex');

// const DiamondContractAddress = "0xF63BcdBB1CB19010774f261d986633FB8096416D";
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
// const StrategyABI = [
//   {
//     "inputs": [
//       {
//         "internalType": "contract CurvePool",
//         "name": "_curvePool",
//         "type": "address"
//       },
//       {
//         "internalType": "contract IERC20",
//         "name": "_curvePoolToken",
//         "type": "address"
//       },
//       {
//         "internalType": "contract IERC20",
//         "name": "_crvToken",
//         "type": "address"
//       },
//       {
//         "internalType": "contract IERC20[3]",
//         "name": "_coins",
//         "type": "address[3]"
//       },
//       {
//         "internalType": "contract UniswapV2Router",
//         "name": "_uniswapRouter",
//         "type": "address"
//       },
//       {
//         "internalType": "address",
//         "name": "_pool",
//         "type": "address"
//       },
//       {
//         "internalType": "contract Controller",
//         "name": "_controller",
//         "type": "address"
//       },
//       {
//         "internalType": "uint256",
//         "name": "_coinIndex",
//         "type": "uint256"
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
//       },
//       {
//         "internalType": "uint256",
//         "name": "minMintAmount",
//         "type": "uint256"
//       }
//     ],
//     "name": "deposit",
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
//       },
//       {
//         "internalType": "uint256",
//         "name": "maxBurnAmount",
//         "type": "uint256"
//       }
//     ],
//     "name": "withdraw",
//     "outputs": [],
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
//     "name": "withdrawAll",
//     "outputs": [],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   },
//   {
//     "inputs": [],
//     "name": "claimAndConvertCRV",
//     "outputs": [
//       {
//         "internalType": "uint256",
//         "name": "",
//         "type": "uint256"
//       }
//     ],
//     "stateMutability": "nonpayable",
//     "type": "function"
//   }
// ]

// const StrategyAddr = "0xeE9A98b8Fe67A5049892bE495EFdba5cf8c3266A";
// const zeroAddress = '0x0000000000000000000000000000000000000000'

// const FacetCutAction = {
//   Add: 0,
//   Replace: 1,
//   Remove: 2
// }

// const transact = async (data, value) => {
//   //  console.log(data, contractAddress, holderAddress, privateKey, value)
//        try {
//            var count = await web3.eth.getTransactionCount(deployerAddress);
//            // var gasPrice = await web3.eth.getGasPrice();
//            var txData = {
//                nonce: web3.utils.toHex(count),
//                gasLimit: web3.utils.toHex(3000000),
//                gasPrice: 15000000000,
//                to: DiamondContractAddress,
//                from: deployerAddress,
//                data: data, 
//                value: value
//            }
//            var transaction = new TX(txData,{chain:'mainnet', hardfork:'petersburg'});
//            transaction.sign(privateKey);
//            var serialisedTransaction = transaction.serialize().toString('hex');
   
//            var receipt = await web3.eth.sendSignedTransaction('0x' + serialisedTransaction);
//            return receipt;
//        } catch(e) {
//                console.log('in catch')
//                throw new Error(e);
//        }
// }

// function getSelectors (abi) {
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

// // // FUNCTION TO ADD FACET
// // async function addFacet(){
// //   try{
// //   console.log("adding facet")
// //   const facetCutCall = new web3.eth.Contract(CutABI, DiamondContractAddress);
// //   const Part1Call = new web3.eth.Contract(StrategyABI, StrategyAddr)
 
// //   let selectorspart1 = getSelectors(Part1Call._jsonInterface);
  
// //   console.log("selectors",selectorspart1)
// //   const functCall = await facetCutCall.methods.diamondCut([ [StrategyAddr, FacetCutAction.Add, selectorspart1 ]], zeroAddress, '0x').encodeABI();
// //   const receipt = await transact(functCall, 0 )
// //   console.log(receipt)
// //   } catch(e) {
// //       console.log('in catch2')
// //       throw new Error(e);
// //   }

// // };

// async function initializeStrategy(){
//   try{
//   const ironBank = "0x2dded6Da1BF5DBdF597C45fcFaa3194e53EcfeAF"
//   const ironBankToken = "0x5282a4eF67D9C33135340fB3289cc1711c13638C"
//   const crvToken = "0xD533a949740bb3306d119CC777fa900bA034cd52"
//   const coins = ["0x6B175474E89094C44Da98b954EedeAC495271d0F","0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48","0xdAC17F958D2ee523a2206206994597C13D831ec7"]
//   const uniswap = "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D"
//   const pool = "0xb8c3Bd6392F61Ad3278aEed7dC93c6cF7d807aB7"
//   const controller = "0x3530b6ee53ed128c871612B59340f1192457e834"
//   const coinIndex = 0
  
//   console.log("initializing strategy")
//   const diamondCall = new web3.eth.Contract(StrategyABI, DiamondContractAddress);
//   const functCall = await diamondCall.methods
//       .initialize(
//         ironBank, 
//         ironBankToken,
//         crvToken,
//         coins,
//         uniswap,
//         pool,
//         controller,
//         coinIndex
//       ).encodeABI();
//   const receipt = await transact(functCall, 0)
//   console.log(receipt)
//   } catch(e) {
//       console.log('in catch2')
//       throw new Error(e);
//   }

// };

// initializeStrategy()
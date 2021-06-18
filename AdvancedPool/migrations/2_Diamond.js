/* eslint-disable prefer-const */
/* global artifacts */

const config = require("./../../config.js");
const Diamond = artifacts.require('Diamond')
const DiamondCutFacet = artifacts.require('DiamondCutFacet')
const DiamondLoupeFacet = artifacts.require('DiamondLoupeFacet')
const OwnershipFacet = artifacts.require('OwnershipFacet')
const AdvancedPool = artifacts.require('AdvancedPool')


const FacetCutAction = {
  Add: 0,
  Replace: 1,
  Remove: 2
}
function getSelectors (contract) {
  const selectors = contract.abi.reduce((acc, val) => {
    if (val.type === 'function') {
      acc.push(val.signature)
      return acc
    } else {
      return acc
    }
  }, [])
  return selectors
}

// module.exports = function (deployer, network, accounts) {
//   console.log(accounts[0],"accounts");

//   // deployer.deploy(AdvancedPool)
//   deployer.deploy(DiamondCutFacet)
//   deployer.deploy(DiamondLoupeFacet)
//   deployer.deploy(OwnershipFacet).then(() => {
//     const diamondCut = [
//       [DiamondCutFacet.address, FacetCutAction.Add, getSelectors(DiamondCutFacet)],
//       [DiamondLoupeFacet.address, FacetCutAction.Add, getSelectors(DiamondLoupeFacet)],
//       [OwnershipFacet.address, FacetCutAction.Add, getSelectors(OwnershipFacet)]
//     ]
//     return deployer.deploy(Diamond, diamondCut, [config.publicKey.mainnet])
//   })
// }

module.exports = function (deployer, network, accounts) {
  console.log(accounts[0],"accounts");
  deployer.deploy(AdvancedPool).then(() => {
    console.log(AdvancedPool.address)
  })
}

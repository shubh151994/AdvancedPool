const HDWalletProvider = require('truffle-hdwallet-provider');
const config = require('./../config.js')
module.exports = {

  networks: {

    ropsten: {
      networkCheckTimeout: 1000000,
      provider: () => new HDWalletProvider(config.mnemomics, config.nodeURL.ropsten, 0,2),
      from: config.publicKey.ropsten,
      network_id: config.networkId.ropsten,       // Ropsten's id
      gasPrice:  1e11,
      gas: 5500000,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true  ,   // Skip dry run before migrations? (default: false for public nets )
    },
    rinkeby: {
      networkCheckTimeout: 1000000,
      provider: () => new HDWalletProvider(config.mnemomics, config.nodeURL.rinkeby, 0,2),
      from: config.publicKey.rinkeby,
      network_id: config.networkId.rinkeby,       // Ropsten's id
      gasPrice:  82000000000,
      gas: 980674,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true  ,   // Skip dry run before migrations? (default: false for public nets )
    },
    mainnet: {
      networkCheckTimeout: 1000000,
      provider: () => new HDWalletProvider(config.mnemomics, config.nodeURL.mainnet, 0,6),
      from: config.publicKey.mainnet,
      network_id: config.networkId.mainnet,       // Ropsten's id
      gasPrice:  82000000000,
      gas: 980674,        // Ropsten has a lower block limit than mainnet
      confirmations: 2,    // # of confs to wait between deployments. (default: 0)
      timeoutBlocks: 200,  // # of blocks before a deployment times out  (minimum/default: 50)
      skipDryRun: true  ,   // Skip dry run before migrations? (default: false for public nets )
    },
   
  },

  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: "EZHQPM7ETCHP6IZQVQKKT6M9ITTBYS1GNQ"
  },
  mocha: {
  },

  compilers: {
    solc: {
      version: "0.7.6",    // Fetch exact version from solc-bin (default: truffle's version)
     
    }
  }
};

require('dotenv-flow').config();
const HDWalletProvider = require("@truffle/hdwallet-provider");
var Web3 = require('web3');

module.exports = {
  compilers: {
    solc: {
      version: '0.6.12',    // Fetch exact version from solc-bin (default: truffle's version)
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
          enabled: true,
          runs: 200
        },
        evmVersion: "istanbul"
      }
    },
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  },
  networks: {
    boba_mainnet: {
      provider: () => new HDWalletProvider(process.env.PRIVATE_KEY, `https://mainnet.boba.network`),
      network_id: 288,
      timeoutBlocks: 200
    },
    boba_rinkeby: {
      provider: () => new HDWalletProvider(process.env.PRIVATE_KEY, `https://rinkeby.boba.network`),
      network_id: 28,
      timeoutBlocks: 200
    },
    rinkeby: {
      provider: () => new HDWalletProvider(process.env.PRIVATE_KEY, "https://rinkeby.infura.io/v3/" + process.env.INFURA_API_KEY),
      network_id: 4,
      timeoutBlocks: 200
    }
  },
};

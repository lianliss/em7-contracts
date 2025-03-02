require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require('hardhat-ignore-warnings');
require("hardhat-contract-sizer");

const accounts = require('../accounts');
const account = accounts.emSeven;

const networks = {
  localhost: {
    url: "http://127.0.0.1:8545"
  },
  skaletest: {
    url: "https://testnet.skalenodes.com/v1/lanky-ill-funny-testnet",
    chainId: 37084624,
    gasPrice: 10000000000,
    accounts: [account.privateKey]
  },
};

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      viaIR: false,
      optimizer: {
        enabled: true,
        runs: 1
      },
      evmVersion: 'cancun',
    }
  },
  networks: networks,
  etherscan: {
    enabled: true,
    apiKey: accounts.arbitrum,
    customChains: [
      {
        network: "skaletest",
        chainId: 37084624,
        urls: {
          apiURL: "https://testnet.skalenodes.com/v1/lanky-ill-funny-testnet/api",
          browserURL: "https://lanky-ill-funny-testnet.explorer.testnet.skalenodes.com"
        }
      },
    ]
  }
};

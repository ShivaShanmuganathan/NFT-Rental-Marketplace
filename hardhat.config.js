
require("@nomiclabs/hardhat-waffle")
require('solidity-coverage')
require("hardhat-gas-reporter");

const fs = require('fs')

const privateKey = fs.readFileSync(".secret").toString().trim() || "01234567890123456789"

module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      chainId: 1337
    },
    // ropsten: {
    //   url: process.env.INFURA_KEY,
    //   accounts: [process.env.PRIVATE_KEY]
    // },
    mumbai: {
      url:'https://rpc-mumbai.maticvigil.com/v1/a1bc762a38f412f3af976f545cd134df77c63626', 
      accounts: [privateKey]
    },

    // mumbai: {
    //   url: "https://rpc-mumbai.maticvigil.com",
    //   accounts: [privateKey]
    // }
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
}
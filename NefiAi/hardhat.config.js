require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-ethers");

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    bscMainnet: {
      url: "https://bsc-dataseed.bnbchain.org",
      chainId: 56,
      accounts: [""], //  private key
    },
  },
  etherscan: {
    apiKey: "", // Hardcoded bsc  API key
  },
};


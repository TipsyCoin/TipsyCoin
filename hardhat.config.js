require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
require("hardhat-gas-reporter");

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

module.exports = {
    defaultNetwork: "hardhat",
    networks: {
        hardhat: {
            name: "hardhat",
            chain: "local",
            saveAddresses: false,
            verify: false,
            testnet: true,
        },
        mainnet: {
            name: "mainnet",
            chain: "eth",
            saveAddresses: true,
            verify: true,
            testnet: false,
            url: `https://eth-mainnet.alchemyapi.io/v2/l8-pVxP2kLvg8TLqkoQzTqo3ijWFbirq`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },
        rinkeby: {
            name: "rinkeby",
            chain: "eth",
            saveAddresses: true,
            verify: true,
            testnet: true,
            url: `https://eth-rinkeby.alchemyapi.io/v2/6v2Nm-M7dbhIrNscatqeuSPi4zICoykq`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },
        ropsten: {
            name: "ropsten",
            chain: "eth",
            saveAddresses: true,
            verify: true,
            testnet: true,
            url: `https://eth-ropsten.alchemyapi.io/v2/6v2Nm-M7dbhIrNscatqeuSPi4zICoykq`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },

        goerli: {
            name: "goerli",
            chain: "eth",
            saveAddresses: true,
            verify: true,
            testnet: true,
            url: `https://eth-goerli.alchemyapi.io/v2/6v2Nm-M7dbhIrNscatqeuSPi4zICoykq`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },
        kovan: {
            name: "kovan",
            chain: "eth",
            saveAddresses: true,
            verify: true,
            testnet: true,
            url: `https://eth-kovan.alchemyapi.io/v2/6v2Nm-M7dbhIrNscatqeuSPi4zICoykq`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },
        // binance smart chain
        bsc: {
            name: "bsc",
            chain: "bsc",
            saveAddresses: true,
            verify: true,
            testnet: false,
            url: `https://bsc-dataseed.binance.org/`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },
        bscTestnet: {
            name: "bscTestnet",
            chain: "bsc",
            saveAddresses: true,
            verify: true,
            testnet: true,
            url: `https://data-seed-prebsc-1-s1.binance.org:8545/`,
            accounts: [process.env.AC019_PRIVATE_KEY],
            gas: 21000000,
            gasPrice: 12000000000,
        },
        // fantom mainnet
        opera: {
            name: "opera",
            chain: "ftm",
            saveAddresses: true,
            verify: true,
            testnet: false,
            url: `https://rpc.fantom.network`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },
        ftmTestnet: {
            name: "ftmTestnet",
            chain: "ftm",
            saveAddresses: true,
            verify: true,
            testnet: true,
            url: `https://rpc.testnet.fantom.network`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },

        // polygon
        polygon: {
            name: "polygon",
            chain: "matic",
            saveAddresses: true,
            verify: true,
            testnet: false,
            url: `https://polygon-mainnet.g.alchemy.com/v2/6v2Nm-M7dbhIrNscatqeuSPi4zICoykq`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },
        polygonMumbai: {
            name: "polygonMumbai",
            chain: "matic",
            saveAddresses: true,
            verify: true,
            testnet: true,
            url: `https://polygon-mumbai.g.alchemy.com/v2/6v2Nm-M7dbhIrNscatqeuSPi4zICoykq`,
            accounts: [process.env.AC019_PRIVATE_KEY],
        },
    },
    etherscan: {
        // Your API key for Etherscan
        // Obtain one at https://etherscan.io/
        apiKey: {
            mainnet: process.env.ETHERSCAN_API_KEY,
            ftmTestnet: process.env.FTMSCAN_API_KEY,
            rinkeby: process.env.ETHERSCAN_API_KEY,
            kovan: process.env.ETHERSCAN_API_KEY,
            bsc: process.env.BSCSCAN_API_KEY,
            bscTestnet: process.env.BSCSCAN_API_KEY,
        },
    },
    solidity: {
        version: "0.8.11",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    gasReporter: {
        currency: "USD",
        token: "ETH",
        gasPrice: 120,
        coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    },
};

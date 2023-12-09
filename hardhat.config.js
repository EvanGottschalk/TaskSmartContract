/**
* @type import('hardhat/config').HardhatUserConfig
*/
require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
const { ACCOUNT_1 } = process.env;
module.exports = {
   solidity: "0.8.1",
   defaultNetwork: "goerli",
   networks: {
      hardhat: {},
      goerli: {
         url: "https://ethereum-goerli.publicnode.com",
         accounts: [`0x${ACCOUNT_1}`]
      }
   },
}
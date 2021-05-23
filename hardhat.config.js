require("@nomiclabs/hardhat-ethers");
require('dotenv').config();

task("hashedMove", "Generates a hashed move")
  .addParam("type", "Type of the move: [1-3] - rock, paper and scissors respectively.")
  .setAction(async ({ type: inmoveType }, { ethers }) => {
  const { id: keccak256, solidityKeccak256: soliditySha3 } = ethers.utils
    
  const salt = keccak256("4rk0zt1m9");
  const move = Number(inmoveType);
  const hashedMove = soliditySha3(['uint8', 'bytes32'], [move, salt]);
  
  console.log(hashedMove);

});

task("deploy", "Deploy the contract")
  .setAction(async (taskArgs, hre) => {
  
  const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
  const rockPaperScissors = await RockPaperScissors.deploy();

  console.log("RockPaperScissors deployed to:", rockPaperScissors.address);
});


/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.0',
    settings: {
      optimizer: {
        enabled: true,
        runs: 800, // assuming we want to lower user gas costs instead of deployment costs.
      },
    },
  },
  networks: {
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_ID}`,
      accounts: [process.env.PRIVATE_KEY]
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
};


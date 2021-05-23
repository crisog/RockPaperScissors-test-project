// const { expect } = require("chai");

describe("RockPaperScissors", function() {
  it("Testing hardhat logging", async function() {
    const RockPaperScissors = await ethers.getContractFactory("RockPaperScissors");
    const rockPaperScissors = await RockPaperScissors.deploy();
    
    await rockPaperScissors.deployed();
  });
});

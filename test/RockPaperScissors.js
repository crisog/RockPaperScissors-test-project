const { ethers } = require('hardhat');
const { waffle } = require('hardhat');
const { deployContract } = waffle;
const provider = waffle.provider;
const { expect } = require('chai');

const RockPaperScissorsJSON = require('../artifacts/contracts/RockPaperScissors.sol/RockPaperScissors.json');

describe('RockPaperScissors contract', function () {
  const [deployer, player1, player2] = provider.getWallets();

  const roundId = 1;
  const wagerAmount = 200;

  let rockPaperScissorsContract;

  beforeEach(async () => {
    rockPaperScissorsContract = await deployContract(
      deployer,
      RockPaperScissorsJSON
    );
  });

  it('Should create a round and emit a RoundCreated event', async function () {
    await expect(rockPaperScissorsContract.create(roundId, wagerAmount))
      .to.emit(rockPaperScissorsContract, 'RoundCreated')
      .withArgs(roundId, wagerAmount);
  });

  it('Should create a round and emit a PlayerJoined event', async function () {
    await expect(rockPaperScissorsContract.create(roundId, wagerAmount))
      .to.emit(rockPaperScissorsContract, 'PlayerJoined')
      .withArgs(roundId, deployer.address);
  });
});

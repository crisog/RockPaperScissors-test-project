const { ethers } = require('hardhat');
const { waffle } = require('hardhat');
const { expect } = require('chai');

describe('RockPaperScissors contract', function () {
  const roundId = 1;
  const wagerAmount = ethers.utils.parseEther('200');

  let rockPaperScissorsContract, ERC20Contract;
  let player1, player2;

  beforeEach(async () => {
    [player1, player2] = await ethers.getSigners();

    const RockPaperScissorsFactory = await ethers.getContractFactory(
      'RockPaperScissors'
    );
    const ERC20Factory = await ethers.getContractFactory('BasicToken');
    ERC20Contract = await ERC20Factory.deploy();

    ERC20Contract.connect(player1).mint(wagerAmount);
    ERC20Contract.connect(player2).mint(wagerAmount);

    rockPaperScissorsContract = await RockPaperScissorsFactory.deploy(
      ERC20Contract.address
    );

    ERC20Contract.connect(player1).approve(
      rockPaperScissorsContract.address,
      wagerAmount
    );
    ERC20Contract.connect(player1).approve(
      rockPaperScissorsContract.address,
      wagerAmount
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
      .withArgs(roundId, player1.address);
  });

  it('Should fail on attempt to join a non-existent round', async function () {
    await expect(
      rockPaperScissorsContract.connect(player2).join(roundId)
    ).to.be.revertedWith('ERROR_ROUND_DOES_NOT_EXIST');
  });
});

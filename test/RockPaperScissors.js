const { ethers } = require('hardhat');
const { waffle } = require('hardhat');
const { deployMockContract } = waffle;
const { expect } = require('chai');

const IERC20 = require('../artifacts/contracts/interfaces/IERC20.sol/IERC20.json');

describe('RockPaperScissors contract', function () {
  const roundId = 1;
  const wagerAmount = ethers.utils.parseEther('200');

  let rockPaperScissorsContract, mockERC20;
  let player1, player2;

  beforeEach(async () => {
    [player1, player2] = await ethers.getSigners();

    const RockPaperScissorsFactory = await ethers.getContractFactory(
      'RockPaperScissors'
    );
    mockERC20 = await deployMockContract(player1, IERC20.abi);
    rockPaperScissorsContract = await RockPaperScissorsFactory.deploy(
      mockERC20.address
    );
  });

  it('Should create a round and emit a RoundCreated event', async function () {
    await mockERC20.mock.balanceOf.returns(ethers.utils.parseEther('200'));
    await expect(rockPaperScissorsContract.create(roundId, wagerAmount))
      .to.emit(rockPaperScissorsContract, 'RoundCreated')
      .withArgs(roundId, wagerAmount);
  });

  it('Should create a round and emit a PlayerJoined event', async function () {
    await mockERC20.mock.balanceOf.returns(ethers.utils.parseEther('200'));
    await expect(rockPaperScissorsContract.create(roundId, wagerAmount))
      .to.emit(rockPaperScissorsContract, 'PlayerJoined')
      .withArgs(roundId, player1.address);
  });

  it('Should fail on attempt to join a non-existent round', async function () {
    await expect(rockPaperScissorsContract.join(roundId)).to.be.revertedWith(
      'ERROR_ROUND_DOES_NOT_EXIST'
    );
  });

  it('Should succeed on attempt to join an existent round', async function () {
    await mockERC20.mock.balanceOf.returns(ethers.utils.parseEther('200'));
    await expect(rockPaperScissorsContract.create(roundId, wagerAmount))
      .to.emit(rockPaperScissorsContract, 'RoundCreated')
      .withArgs(roundId, wagerAmount);

    await expect(rockPaperScissorsContract.connect(player1).join(roundId))
      .to.emit(rockPaperScissorsContract, 'PlayerJoined')
      .withArgs(roundId, player2.address);
  });
});

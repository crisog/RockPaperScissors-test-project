// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

 /**
  * @title RockPaperScissors
  * @dev 2-person simulation of the classic game of rock, paper, scissors using ERC20
  */
contract RockPaperScissors {

    string private constant ERROR_ROUND_DOES_NOT_EXIST = "ERROR_ROUND_DOES_NOT_EXIST";
    string private constant ERROR_ROUND_ALREADY_EXISTS = "ERROR_ROUND_ALREADY_EXISTS";

    uint8 internal constant ROUND_INITIALIZED = uint8(1);
    
    struct CastedMove {
        bytes32 committed;                         // Hash of the move casted by the player
        uint8 revealed;                              // Revealed move submitted by the player
    }
    
    struct Round {
        uint8 initialized;
        uint8 winningMove;                       //  Winner move of a round instance
        mapping (address => CastedMove) moves;        // Mapping of players addresses to their casted moves
    }

    // Round records indexed by their ID
    mapping (uint256 => Round) internal roundRecords;

    event RoundCreated(uint256 indexed roundId, uint256 wagerAmount);

    /**
    * @dev Internal function to check if a round instance was already created
    * @param _round Round instance to be checked
    * @return True if the given round instance was already created, false otherwise
    */
    function _existsRound(Round storage _round) internal view returns (bool) {
        return _round.initialized != ROUND_INITIALIZED;
    }

    /**
    * @notice Create a new round instance with ID #`_roundId` and `_wagerAmount` wagered amount
    * @param _roundId ID of the new round instance to be created
    * @param _wagerAmount Wagered amount of tokens for the new round instance to be created
    */
    function create(uint256 _roundId, uint256 _wagerAmount) external {

        Round storage round = roundRecords[_roundId];
        require(!_existsRound(round), ERROR_ROUND_ALREADY_EXISTS);

        round.initialized = ROUND_INITIALIZED;
        emit RoundCreated(_roundId, _wagerAmount);
    }

}
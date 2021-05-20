// SPDX-License-Identifier: Unlicense

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity ^0.8.0;

 /**
  * @title RockPaperScissors
  * @dev 2-person simulation of the classic game of rock, paper, scissors using ERC20
  */
contract RockPaperScissors {

    string private constant ERROR_ROUND_DOES_NOT_EXIST = "ERROR_ROUND_DOES_NOT_EXIST";
    string private constant ERROR_ROUND_ALREADY_EXISTS = "ERROR_ROUND_ALREADY_EXISTS";
    string private constant ERROR_MOVE_ALREADY_COMMITTED = "ERROR_MOVE_ALREADY_COMMITTED";
    string private constant ERROR_NOT_ENOUGH_TOKENS = "ERROR_NOT_ENOUGH_TOKENS";
    string private constant ERROR_MOVE_ALREADY_REVEALED = "ERROR_MOVE_ALREADY_REVEALED";
    string private constant ERROR_COMMITTED_MOVE_REFUSED = "ERROR_COMMITTED_MOVE_REFUSED";
    string private constant ERROR_INVALID_HASHING_SALT = "ERROR_INVALID_HASHING_SALT";
    string private constant ERROR_INVALID_COMMITED_MOVE = "ERROR_INVALID_COMMITED_MOVE";

    uint internal constant REVEALED_MOVE_MISSING = uint8(0);
    uint8 internal constant ROUND_INITIALIZED = uint8(1);
    uint8 internal constant REVEALED_MOVE_REFUSED = uint8(2);
    // Rock, Paper and Scissors (3)
    uint8 internal constant MAX_POSSIBLE_MOVES = uint8(2);
    IERC20 constant internal WETH_ADDRESS = IERC20(0xc778417E063141139Fce010982780140Aa0cD5Ab);
    
    struct CastedMove {
        bytes32 committed;                         // Hash of the move casted by the player
        uint8 revealed;                              // Revealed move submitted by the player
    }
    
    struct Round {
        uint8 initialized;
        uint8 winningMove;                   
        uint8 maxAllowedMoves; 
        uint256 wageredTokensAmount;
        mapping (address => CastedMove) moves;      // Mapping of players addresses to their casted move
    }

    // Round records indexed by their ID
    mapping (uint256 => Round) internal roundRecords;

    event RoundCreated(uint256 indexed roundId, uint256 wagerAmount);
    event MoveCommitted(uint256 indexed roundId, address indexed player, bytes32 commitment);
    event MoveRevealed(uint256 indexed roundId, address indexed player, uint8 outcome, address revealer);

    /**
    * @dev Ensure a certain round exists
    * @param _roundId Identification number of the round to be checked
    */
    modifier roundExists(uint256 _roundId) {
        Round storage round = roundRecords[_roundId];
        require(_existsRound(round), ERROR_ROUND_DOES_NOT_EXIST);
        _;
    }

    /**
    * @dev Internal function to check if a round instance was already created
    * @param _round Round instance to be checked
    * @return True if the given round instance was already created, false otherwise
    */
    function _existsRound(Round storage _round) internal view returns (bool) {
        return _round.initialized != ROUND_INITIALIZED;
    }

    /**
    * @dev Internal function to tell whether a certain commited move is valid for a given round instance or not. 
    * @notice This function assumes the given round exists.
    * @param _round Round instance to check the commited move of
    * @param _committedMove commited move to check if valid or not
    * @return True if the given commited move is valid for the requested round instance, false otherwise.
    */
    function _isValidCommittedMove(Round storage _round, uint8 _committedMove) internal view returns (bool) {
        return _committedMove >= REVEALED_MOVE_REFUSED && _committedMove <= _round.maxAllowedMoves;
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
        round.maxAllowedMoves = MAX_POSSIBLE_MOVES;
        emit RoundCreated(_roundId, _wagerAmount);
    }

    /**
    * @notice Commit a move for round #`_roundId`
    * @param _roundId ID of the round instance to commit a move to
    * @param _commitment Hashed committed move to be stored for future reveal
    */
    function commit(uint256 _roundId, bytes32 _commitment) external roundExists(_roundId) {
        CastedMove storage castedMove = roundRecords[_roundId].moves[msg.sender];
        require(castedMove.committed == bytes32(0), ERROR_MOVE_ALREADY_COMMITTED);
        _ensurePlayerCanCommit(_roundId, msg.sender);

        castedMove.committed = _commitment;
        emit MoveCommitted(_roundId, msg.sender, _commitment);
    }

    /**
    * @dev Internal function to ensure a player can commit a move
    * @param _roundId ID of the round instance to be checked
    * @param _player Address of the player willing to commit a move
    */
    function _ensurePlayerCanCommit(uint256 _roundId, address _player) internal view {
        Round storage round = roundRecords[_roundId];
        require(WETH_ADDRESS.balanceOf(_player) >= round.wageredTokensAmount, ERROR_NOT_ENOUGH_TOKENS);
    }

    /**
    * @notice Reveal `_committedMove` round of `_player` for round #`_roundId`
    * @param _roundId ID of the round instance to reveal a move of
    * @param _player Address of the player to reveal a move for
    * @param _committedMove Committed move revealed by the player
    * @param _salt Salt to decrypt and validate the committed move of the player
    */
    function reveal(uint256 _roundId, address _player, uint8 _committedMove, bytes32 _salt) external roundExists(_roundId) {
        Round storage round = roundRecords[_roundId];
        CastedMove storage castedMove = round.moves[_player];
        _checkValidSalt(castedMove, _committedMove, _salt);
        require(_isValidCommittedMove(round, _committedMove), ERROR_INVALID_COMMITED_MOVE);

        castedMove.revealed = _committedMove;
        emit MoveRevealed(_roundId, _player, _committedMove, msg.sender);
    }

     /**
    * @dev Get the winner of a round instance. If the winner is missing, that means no one played in
    *      the given round instance, it will be considered refused.
    * @param _roundId ID of the round instance querying the winning outcome of
    * @return Winner of the given round instance or refused in case it's missing
    */
    function getWinningMove(uint256 _roundId) external view roundExists(_roundId) returns (uint8) {
        Round storage round = roundRecords[_roundId];
        uint8 winningMove = round.winningMove;
        return winningMove == REVEALED_MOVE_MISSING ? OUTCOME_REFUSED : winningOutcome;
    }

    /**
    * @dev Hash a move using a given salt
    * @param _commitedMove Committed move to be hashed
    * @param _salt Encryption salt
    * @return Hashed move
    */
    function hashMove(uint8 _commitedMove, bytes32 _salt) external pure returns (bytes32) {
        return _hashMove(_commitedMove, _salt);
    }

    /**
    * @dev Internal function to hash a round commited move using a given salt
    * @param _commitedMove Committed move to be hashed
    * @param _salt Encryption salt
    * @return Hashed outcome
    */
    function _hashMove(uint8 _commitedMove, bytes32 _salt) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_commitedMove, _salt));
    }

    /**
    * @dev Internal function to check if a move can be revealed for the given commited move and salt
    * @param _castMove Casted move to be revealed
    * @param _commitedMove Move thas has to be proved
    * @param _salt Salt to decrypt and validate the provided move for a casted move
    */
    function _checkValidSalt(CastedMove storage _castMove, uint8 _commitedMove, bytes32 _salt) internal view {
        require(_castMove.revealed == REVEALED_MOVE_MISSING, ERROR_MOVE_ALREADY_REVEALED);
        require(_castMove.committed == _hashMove(_commitedMove, _salt), ERROR_INVALID_HASHING_SALT);
    }

}
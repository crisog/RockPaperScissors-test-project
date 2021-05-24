// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract BasicToken is ERC20 {
  constructor() ERC20('Slingshot', 'SLT') {}

  function mint(uint256 _amount) public {
    _mint(msg.sender, _amount);
  }
}

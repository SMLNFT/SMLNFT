//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20/ERC20.sol";

contract SMLToken is ERC20 {

    uint256 private maxSupply = 100000000 * 10 ** 10;

	constructor() ERC20("SML Token","SML", 10, maxSupply) {
	    _mint(msg.sender, maxSupply);
	}
	
}
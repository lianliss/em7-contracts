// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title EmSeven simple ERC20 token;
/// @notice Used for income distribution and voting;
contract EmSeven is ERC20 {

    constructor() ERC20("EmSeven", "EM7") {
        /// Mint 10 billion to initial holder
        _mint(msg.sender, 10_000_000_000 * 10**18);
    }

}

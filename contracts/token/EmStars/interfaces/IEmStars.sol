// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IEmStarsExternal} from "./IEmStarsExternal.sol";

/// Lockup data structure for lockups getter
struct Lockup {
    uint256 untilTimestamp;
    uint256 amount;
}

interface IEmStars is IEmStarsExternal {

    /// @dev Emitted when total supply lockups unlocked
    event CommonLockupsUnlocked(uint256 amount, uint256 totalSupply);

    /// @dev Emitted when holders lockups unlocked
    event LockupsUnlocked(address indexed holder, uint256 amount, uint256 balance);

    /// @dev Emitted when locked tokens minted for a certain period
    event LockupMinted(address indexed holder, uint256 indexed date, uint256 amount);

    /// @dev Emmited when unlocked income sent to income distributor contract
    event IncomeSent(address indexed spender, uint256 amount);

    /// @dev Emitted when locked income appointed under income distributor contract
    event IncomeLocked(address indexed spender, uint256 amount);

    /// @dev Emitted when referral income sent to refer's parent
    event RefIncomeSent(address indexed spender, address indexed refer, address indexed holder, uint256 amount);

    /// @dev Emitted when referral locked income sent to refer's parent
    event RefIncomeLocked(address indexed spender, address indexed refer, address indexed holder, uint256 amount);

    /// @dev Emitted when tokens spent
    event Spent(address indexed holder, address indexed caller, uint256 amount);

    /// @dev Emitted when locked tokens refunded
    event Refunded(address indexed holder, uint256 amount, uint256 refunded, bool blocked);

    /// @dev Emitted whet minter lockup set
    event MinterLockupTimeSet(address indexed minter, uint256 time);

    /// @dev Emitted when income distributor contract address set
    event IncomeDistributorSet(address incomeAddress);
    
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEmStarsExternal {
    
    /// Exchanger methods
    function mint(address holder, uint256 amount) external;
    function burn(address holder, uint256 amount) external;

    /// External spenders method
    function spend(address holder, uint256 amount) external;
    function spendUnlocked(address holder, uint256 amount) external;
    function earliestUnlockTime(address holder, uint256 requiredAmount) external view returns (uint256 unlockTimestamp);

    /// Backend minter methods
    function mintLockup(address holder, uint256 amount) external;
    function refundLockup(address holder, uint256 amount, uint256 date) external;
    
}
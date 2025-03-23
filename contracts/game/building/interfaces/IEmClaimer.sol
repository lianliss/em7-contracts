// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEmClaimer {

    function claim(uint256 buildingIndex) external;
    function claimFor(address user, uint256 buildingIndex) external;

}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IEmClaimer {

    event Claimed(address indexed user, uint256 indexed buildingIndex, address indexed resource, uint256 amount);

    function claim(uint256 buildingIndex) external;
    function claimFor(address user, uint256 buildingIndex) external;

}
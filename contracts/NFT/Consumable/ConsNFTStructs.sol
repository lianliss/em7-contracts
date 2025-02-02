// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct ItemType {
    uint256 typeId;
    uint256 collectionId;
    uint8 rarity;
    uint256 charges;
    address contractAddress;
    string method;
    bytes params;
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct NFTTokenType {
    uint256 typeId;
    string tokenURI;
    string name;
    bool transferable;
    bool tradable;
}
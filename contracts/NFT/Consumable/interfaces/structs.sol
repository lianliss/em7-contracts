// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Collection} from "../../Equipment/interfaces/structs.sol";

struct ConsumableType {
    uint256 typeId;
    uint256 collectionId;
    string title;
    string tokenURI;
    uint8 rarity;
    uint256 charges;
    address contractAddress;
    string method;
    bytes params;
    uint256 count;
    bool transferable;
    bool useCoords;
}

struct ConsumableItem {
    uint256 tokenId;
    uint256 typeId;
    uint256 charges;
}
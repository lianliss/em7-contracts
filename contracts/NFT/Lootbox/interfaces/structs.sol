// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Collection} from "../../Equipment/interfaces/structs.sol";

struct Drop {
    uint256 chanceRatio;
    address nftAddress;
    uint256[] typeId;
}

struct LootboxType {
    uint256 typeId;
    uint256 collectionId;
    string title;
    string tokenURI;
    uint8 rarity;
    uint256 count;
    uint256 transferableAfter;
    Drop[] drop;
}

struct LootboxItem {
    uint256 tokenId;
    uint256 typeId;
    uint256 transferableAfter;
}
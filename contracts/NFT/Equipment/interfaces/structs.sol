// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct ResourceMod {
    address resource;
    uint256 mod;
    bool isVolume;
}

struct UserMod {
    uint256 paramIndex;
    uint256 mod;
}

struct EquipmentType {
    uint256 typeId;
    uint256 collectionId;
    uint256 slotId;
    uint256 transferableAfter;
    uint256 count;
    string tokenURI;
    string name;
    UserMod[] userMods;
    ResourceMod[] buildingMods;
    ResourceMod[] borderingMods;
}

struct Item {
    uint256 tokenId;
    uint256 typeId;
    uint256 transferableAfter;
    bool locked;
}

struct Collection {
    uint256 collectionId;
    string title;
}
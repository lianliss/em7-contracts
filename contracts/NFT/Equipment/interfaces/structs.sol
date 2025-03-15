// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct ResourceMod {
    address resource;
    uint256 mod;
    bool isVolume;
}

struct ParamMod {
    uint256 paramIndex;
    uint256 mod;
}

struct EquipmentType {
    uint256 typeId;
    uint256 collectionId;
    uint256 transferableAfter;
    uint256 count;
    string tokenURI;
    string name;
    ParamMod[] userMods;
    ResourceMod[] buildingMods;
    ResourceMod[] borderingMods;
}

struct Item {
    uint256 tokenId;
    uint256 typeId;
    bool locked;
}

struct Collection {
    uint256 collectionId;
    string title;
}
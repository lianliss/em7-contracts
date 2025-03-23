//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import {ResourceProgression, Progression} from "../../lib/structs.sol";

struct BuildRequirements {
    ResourceProgression[] resources;
    Progression.Params time;
    uint256[] levelTech;
}

struct BuildingType {
    uint256 typeId;
    address functionality;
    string title;
    uint256 minLevel;
    uint256 maxLevel;
    uint256 countLimit;
    bool disabled;
    uint8 size;
    uint256[] slots;
    BuildRequirements construction;
}

struct Building {
    uint256 index;
    uint256 typeId;
    uint256 level;
    uint256 constructedAt;
}

struct MineType {
    uint256 typeId;
    address resource;
    Progression.Params output;
    Progression.Params volume;
    Progression.Params pipes;
}

struct Mine {
    uint256 index;
    uint256 typeId;
    uint256 claimedAt;
    uint256 output;
    uint256 volume;
    address[] consumers;
}

struct Recipe {
    uint8 recipeId;
    uint256 typeId;
    ResourceProgression[] input;
    ResourceProgression[] output;
    Progression.Params[] volume;
}

struct InputPipe {
    uint256 buildingIndex;
    uint8 pipeIndex;
    address functionality;
}
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

struct InputPipe {
    uint256 buildingIndex;
    uint8 pipeIndex;
    address functionality;
}
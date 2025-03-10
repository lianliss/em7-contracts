// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ResourceProgression, Progression} from "../../structs.sol";

struct BuildRequirements {
    ResourceProgression[] resources;
    Progression.ProgressionParams time;
    uint256 userLevel;
}

struct BuildingType {
    uint256 typeId;
    address functionality;
    string title;
    uint256 minLevel;
    uint256 maxLevel;
    bool disabled;
    uint256[] slots;
    BuildRequirements construction;
}

interface IEmBuilding {

    event BuildingTypeSet(uint256 indexed typeId, address indexed functionality, string title, uint256 minLevel, uint256 maxLevel);
    event BuildingTypeSlotsSet(uint256 indexed typeId, uint256[] slots);
    event BuildingRequirementsSet(uint256 indexed typeId, BuildRequirements requirements);
    event BuildingTypeDisabled(uint256 indexed typeId);
    event BuildingTypeEnabled(uint256 indexed typeId);

}
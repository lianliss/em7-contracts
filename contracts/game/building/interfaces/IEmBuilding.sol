// SPDX-License-Identifier: MIT
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

interface IEmBuilding {

    error TechNotResearched(uint256 techIndex);
    error BuildingTypeCountLimit(uint256 limit);
    error SlotOccupiedError(address tokenAddress, uint256 tokenId);

    event ReturnDeviderSet(uint256 devider);
    event BuildingTypeSet(uint256 indexed typeId, address indexed functionality, string title, uint256 minLevel, uint256 maxLevel);
    event BuildingTypeSlotsSet(uint256 indexed typeId, uint256[] slots);
    event BuildingRequirementsSet(uint256 indexed typeId, BuildRequirements requirements);
    event BuildingTypeDisabled(uint256 indexed typeId);
    event BuildingTypeEnabled(uint256 indexed typeId);

    event BuildingPlaced(address indexed user, Building building);
    event BuildingUpgraded(address indexed user, Building building);
    event BuildingRemoved(address indexed user, uint256 buildingIndex);

    event ItemEquiped(address indexed user, address tokenAddress, uint256 tokenId, uint256 buildingIndex, uint256 slotId);
    event ItemUnequiped(address indexed user, address tokenAddress, uint256 tokenId, uint256 buildingIndex, uint256 slotId);

    function getTypes(uint256 offset, uint256 limit) external view returns (BuildingType[] memory, uint256 count);
    function getBuildings(address user, uint256 offset, uint256 limit) external view returns (Building[] memory, uint256 count);
    function build(uint256 typeId, uint256 x, uint256 y) external;
    function upgrade(uint256 buildingIndex) external;
    function remove(uint256 buildingIndex) external;

    function setReturnDevider(uint256 devider) external;
    function addType(
        string calldata title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel
    ) external;
    function updateType(
        uint256 typeId,
        string calldata title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel
    ) external;
    function setTypeSlots(uint256 typeId, uint256[] calldata slots) external;
    function setBuildingRequirements(uint256 typeId, BuildRequirements calldata requirements) external;
    function disableType(uint256 typeId) external;
    function enableType(uint256 typeId) external;
    function buildFor(bytes calldata input) external;

    function equip(address tokenAddress, uint256 tokenId, uint256 buildingIndex, uint256 slotId) external;
    function unequip(uint256 buildingIndex, uint256 slotId) external;
    function getSpeedMod(address user, uint256 buildingIndex, address resource) external view returns (uint256);
    function getVolumeMod(address user, uint256 buildingIndex, address resource) external view returns (uint256);


}
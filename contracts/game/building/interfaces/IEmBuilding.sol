// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ResourceProgression, Progression} from "../../lib/structs.sol";
import {IEmBuildingEvents} from "./IEmBuildingEvents.sol";
import {BuildRequirements, BuildingType, Building} from "./structs.sol";

interface IEmBuilding is IEmBuildingEvents {

    function getTypes(uint256 offset, uint256 limit) external view returns (BuildingType[] memory, uint256 count);
    function getBuildings(address user, uint256 offset, uint256 limit) external view returns (Building[] memory, uint256 count);
    function getBuilding(address user, uint256 buildingIndex) external view returns (Building memory);
    function getBuildingFunctionality(address user, uint256 buildingIndex) external view returns (address);
    function build(uint256 typeId, uint256 x, uint256 y) external;
    function upgrade(uint256 buildingIndex) external;
    function remove(uint256 buildingIndex) external;

    function buildFor(bytes calldata input) external;

    function equip(address tokenAddress, uint256 tokenId, uint256 buildingIndex, uint256 slotId) external;
    function unequip(uint256 buildingIndex, uint256 slotId) external;
    function getSpeedMod(address user, uint256 buildingIndex, address resource) external view returns (uint256);
    function getVolumeMod(address user, uint256 buildingIndex, address resource) external view returns (uint256);


}
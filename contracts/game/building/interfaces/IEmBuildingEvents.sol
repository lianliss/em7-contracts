//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import {BuildRequirements, Building} from "./structs.sol";
import {IEmErrors} from "../../errors.sol";

interface IEmBuildingEvents is IEmErrors {

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

}
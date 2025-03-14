// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Coords} from "../../lib/coords.sol";
import {Progression} from "../../../utils/Progression.sol";
import {Object} from "./structs.sol";

interface IEmMapExternal {

    event ObjectSet(address indexed user, uint256 x, uint256 y, uint8 size, uint256 buildingIndex);
    event ObjectRemoved(address indexed user, uint256 x, uint256 y, uint8 size, uint256 buildingIndex);

    function setObject(address user, uint256 x, uint256 y, uint8 size, uint256 buildingIndex) external;
    function removeObject(address user, uint256 buildingIndex) external;

    function getTileBuilding(address user, uint256 x, uint256 y) external view returns (uint256);
    function getBuildingObject(address user, uint256 buildingIndex) external view returns (Object memory);
    function getBorderingBuildings(address user, uint256 buildingIndex) external view returns (uint256[] memory);

}
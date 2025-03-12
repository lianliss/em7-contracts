// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Coords} from "../../lib/coords.sol";
import {Progression} from "../../../utils/Progression.sol";

struct Object {
    Coords.Point origin;
    uint8 size;
    uint256 buildingIndex;
}

interface IEmMap {

    error AreaAlreadyClaimed(uint256 x, uint256 y);
    error PositionIsOccupied(uint256 x, uint256 y, uint8 size);

    event AreaClaimed(address indexed user, uint256 x, uint256 y);
    event AreaPaid(address indexed user, uint256 x, uint256 y, address token, uint256 price);
    event ObjectSet(address indexed user, uint256 x, uint256 y, uint8 size, uint256 buildingIndex);
    event ObjectRemoved(address indexed user, uint256 x, uint256 y, uint8 size, uint256 buildingIndex);
    event ClaimPriceSet(Progression.ProgressionParams params);
    event ClaimStarsPriceSet(Progression.ProgressionParams params);

    function setClaimPrice(Progression.ProgressionParams calldata params) external;
    function setClaimStarsPrice(Progression.ProgressionParams calldata params) external;

    function setObject(address user, uint256 x, uint256 y, uint8 size, uint256 buildingIndex) external;
    function removeObject(address user, uint256 buildingIndex) external;

    function claimArea(uint256 x, uint256 y) external;
    function claimAreaStars(uint256 x, uint256 y) external;
    function claimFor(address user, uint256 x, uint256 y) external;
    function getClaimedAreasLength(address user) external view returns (uint256);
    function getClaimedAreas(address user, uint256 offset, uint256 limit) external view returns (Coords.Point[] memory);

    function getBuildingObject(address user, uint256 buildingIndex) external view returns (Object memory);
    function getObjectsLength(address user) external view returns (uint256);
    function getObjects(address user, uint256 offset, uint256 limit) external view returns (Object[] memory);

    function getTileObject(address user, uint256 x, uint256 y) external view returns (Object memory);
    function getTileBuilding(address user, uint256 x, uint256 y) external view returns (uint256);
    function getBorderingBuildings(address user, uint256 buildingIndex) external view returns (uint256[] memory);

}
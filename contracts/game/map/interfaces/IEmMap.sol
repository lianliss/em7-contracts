// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Coords} from "../../lib/coords.sol";
import {Progression} from "../../../utils/Progression.sol";
import {Object} from "./struct.sol";
import {IEmMapExternal} from "./IEmMapExternal.sol";

interface IEmMap is IEmMapExternal {

    error AreaAlreadyClaimed(uint256 x, uint256 y);
    error PositionIsOccupied(uint256 x, uint256 y, uint8 size);

    event AreaClaimed(address indexed user, uint256 x, uint256 y);
    event AreaPaid(address indexed user, uint256 x, uint256 y, address token, uint256 price);
    event ClaimPriceSet(Progression.Params params);
    event ClaimStarsPriceSet(Progression.Params params);

    function setClaimPrice(Progression.Params calldata params) external;
    function setClaimStarsPrice(Progression.Params calldata params) external;

    function claimArea(uint256 x, uint256 y) external;
    function claimAreaStars(uint256 x, uint256 y) external;
    function claimFor(address user, uint256 x, uint256 y) external;
    function getClaimedAreas(address user, uint256 offset, uint256 limit) external view returns (Coords.Point[] memory, uint256 count);
    function getObjects(address user, uint256 offset, uint256 limit) external view returns (Object[] memory, uint256 count);
    function getTileObject(address user, uint256 x, uint256 y) external view returns (Object memory);

}
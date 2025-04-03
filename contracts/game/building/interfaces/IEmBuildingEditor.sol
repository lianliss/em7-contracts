//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import {BuildRequirements} from "./IEmBuilding.sol";
import {IEmBuildingEvents} from "./IEmBuildingEvents.sol";

interface IEmBuildingEditor is IEmBuildingEvents {

    function setReturnDevider(uint256 devider) external;
    function addType(
        string calldata title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel,
        uint256 countLimit,
        uint8 size
    ) external;
    function updateType(
        uint256 typeId,
        string calldata title,
        address functionalityAddress,
        uint256 minLevel,
        uint256 maxLevel,
        uint256 countLimit,
        uint8 size
    ) external;
    function setTypeSlots(uint256 typeId, uint256[] calldata slots) external;
    function setBuildingRequirements(uint256 typeId, BuildRequirements calldata requirements) external;
    function disableType(uint256 typeId) external;
    function enableType(uint256 typeId) external;

}
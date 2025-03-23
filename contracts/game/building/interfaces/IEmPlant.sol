// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ResourceProgression} from "../../lib/structs.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmClaimer} from "./IEmClaimer.sol";
import {IEmPlantEvents} from "./IEmPlantEvents.sol";
import {IEmPipe} from "./IEmPipe.sol";
import {Recipe} from "./structs.sol";

interface IEmPlant is IEmClaimer, IEmPipe, IEmPlantEvents {

    function getRecipes(uint256 offset, uint256 limit) external view returns (Recipe[][] memory, uint256 count);
    function connectSource(uint256 buildingIndex, uint8 inputIndex, uint256 sourceBuildingIndex, uint8 sourcePipeId) external;
    function disconnectSource(uint256 buildingIndex, uint8 sourceIndex) external;

}
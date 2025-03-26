// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ResourceProgression} from "../../lib/structs.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmPlant, Recipe} from "../interfaces/IEmPlant.sol";
import {IEmResource} from "../../../token/EmResource/interfaces/IEmResource.sol";
import {EmPipe, IEmPipe, Building} from "./EmPipe.sol";
import {InputPipe, Consumer, Plant} from "../interfaces/structs.sol";
import {PERCENT_PRECISION} from "../../../core/const.sol";
import {EmPlantContext} from "../context/EmPlantContext.sol";
import {EmPlantInternal} from "../functionality/EmPlantInternal.sol";

/// @dev Require add to EmResFactory whitelist;
/// @dev Require functionality buildings CONSUMER_ROLE;
contract EmPlant is EmPipe, EmPlantContext, EmPlantInternal, IEmPlant {

    using EnumerableSet for EnumerableSet.UintSet;
    using Progression for Progression.Params;

    constructor(address buildingAddress, address techAddress) EmPipe(buildingAddress, techAddress) {
        _grantRole(CLAIMER_ROLE, _msgSender());
    }

    function getPipeOutput(address user, uint256 buildingIndex, uint8 pipeIndex) external view returns (Consumer memory consumer, address resource, uint256 amountPerSecond) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        _requireConstructed(building);
        _requirePipeExists(building, pipeIndex);
        Recipe storage recipe = _getRecipe(user, building);
        return (_consumers[user][buildingIndex][pipeIndex], recipe.output[uint256(pipeIndex)].resource, _getOutput(user, building, uint256(pipeIndex)));
    }

    function getRecipes(uint256 offset, uint256 limit) public view returns (Recipe[][] memory, uint256 count) {
        count = _types.length();
        if (offset >= count || limit == 0) return (new Recipe[][](0), count);
        uint256 length = count - offset;
        if (limit < length) length = limit;
        Recipe[][] memory data = new Recipe[][](length);
        for (uint256 i; i < length; i++) {
            data[i] = _recipes[_types.at(offset + i)];
        }
        return (data, count);
    }

    function getPlant(address user, uint256 buildingIndex) public view returns (Plant memory) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        Recipe storage recipe = _getRecipe(user, building);
        InputPipe[] memory sources = new InputPipe[](recipe.input.length);
        for (uint8 i; i < uint8(recipe.input.length); i++) {
            sources[i] = _inputs[user][buildingIndex][i];
        }
        return Plant(
            buildingIndex,
            building.typeId,
            _claimedAt[user][buildingIndex],
            recipe.recipeId,
            _getRawOutput(user, building),
            _getRawVolume(user, building),
            sources,
            getConsumers(user, buildingIndex)
        );
    }


    /// Write methods

    function claim(uint256 buildingIndex) public {
        address user = _msgSender();
        Building memory building = _building.getBuilding(user, buildingIndex);
        _claim(user, building);
    }

    function connectSource(uint256 buildingIndex, uint8 inputIndex, uint256 sourceBuildingIndex, uint8 sourcePipeId) public {
        address user = _msgSender();
        Building memory building = _building.getBuilding(user, buildingIndex);
        Recipe storage recipe = _getRecipe(user, building);
        _disconnectSource(user, building, inputIndex);
        IEmPipe pipe = IEmPipe(_building.getBuildingFunctionality(user, buildingIndex));
        /// Chect incoming resource type
        (, address resource,) = pipe.getPipeOutput(user, sourceBuildingIndex, sourcePipeId);
        require(resource == recipe.input[inputIndex].resource, "Wrong source resource");
        /// Connect pipe
        pipe.lockPipe(user, sourceBuildingIndex, sourcePipeId, buildingIndex);
        _inputs[user][building.index][inputIndex].buildingIndex = sourceBuildingIndex;
        _inputs[user][building.index][inputIndex].pipeIndex = sourcePipeId;
        _inputs[user][building.index][inputIndex].functionality = address(pipe);
        emit SourceConnected(user, buildingIndex, inputIndex, address(pipe), sourceBuildingIndex, sourcePipeId);
    }

    function disconnectSource(uint256 buildingIndex, uint8 sourceIndex) public {
        address user = _msgSender();
        Building memory building = _building.getBuilding(user, buildingIndex);
        _disconnectSource(user, building, sourceIndex);
    }


    /// External methods

    function claimFor(address user, uint256 buildingIndex) external onlyRole(CLAIMER_ROLE) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        _claim(user, building);
    }

    function lockPipe(address user, uint256 buildingIndex, uint8 pipeIndex, uint256 consumerIndex) public override(EmPipe, IEmPipe) onlyRole(CONSUMER_ROLE) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        _claim(user, building);
        _requireInputsConnected(user, building);
        super.lockPipe(user, buildingIndex, pipeIndex, consumerIndex);
    }

    function unlockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) public override(EmPipe, IEmPipe) onlyRole(CONSUMER_ROLE) {
        super.unlockPipe(user, buildingIndex, pipeIndex);
        _claimedAt[user][buildingIndex] = block.timestamp;
    }


    /// Internal methods

    function _requireInputsConnected(address user, Building memory building) internal view {
        Recipe storage recipe = _getRecipe(user, building);
        for (uint8 i; i < recipe.input.length; i++) {
            if (_inputs[user][building.index][i].functionality == address(0)) {
                revert("All input connectors required");
            }
        }
    }
    

    function _disconnectSource(address user, Building memory building, uint8 sourceIndex) internal {
        InputPipe storage pipe = _inputs[user][building.index][sourceIndex];
        if (pipe.functionality == address(0)) return;
        IEmPipe(pipe.functionality).unlockPipe(user, pipe.buildingIndex, pipe.pipeIndex);
        delete _inputs[user][building.index][sourceIndex];
        emit SourceDisconnected(user, building.index, sourceIndex);
    }

}
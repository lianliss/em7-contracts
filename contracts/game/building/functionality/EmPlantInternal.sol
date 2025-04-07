//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ResourceProgression} from "../../lib/structs.sol";
import {Progression} from "../../../utils/Progression.sol";
import {Recipe, Building} from "../interfaces/structs.sol";
import {IEmResource} from "../../../token/EmResource/interfaces/IEmResource.sol";
import {InputPipe} from "../interfaces/structs.sol";
import {PERCENT_PRECISION} from "../../../core/const.sol";
import {EmPlantContext} from "../context/EmPlantContext.sol";
import {EmPipeContext} from "../context/EmPipeContext.sol";
import {IEmPlantEvents} from "../interfaces/IEmPlantEvents.sol";
import {IEmPipe} from "../interfaces/IEmPipe.sol";
import {EmPipeInternal} from "./EmPipeInternal.sol";
import {Errors} from "../../errors.sol";

abstract contract EmPlantInternal is EmPipeContext, EmPlantContext, IEmPlantEvents {

    using EnumerableSet for EnumerableSet.UintSet;
    using Progression for Progression.Params;

    function _requireTypeExists(uint256 typeId) internal view {
        require(_types.contains(typeId), "Type is not exists");
    }

    function _requireRecipeExists(uint256 typeId, uint256 recipeId) internal view {
        require(recipeId < _recipes[typeId].length, "Recipe is not exists");
    }

    function _requirePlantNoConsumers(address user, Building memory building) internal view virtual {
        uint8 pipes = _getPlantPipes(building);
        for (uint8 i; i < pipes; i++) {
            if (_consumers[user][building.index][i].functionality != address(0)) {
                revert Errors.HaveConsumersError(i, _consumers[user][building.index][i].functionality, _consumers[user][building.index][i].buildingIndex);
            }
        }
    }

    function _getPlantPipes(Building memory building) internal view virtual returns (uint8) {
        uint256 realPipes = _pipes[building.typeId].get(building.level);
        return realPipes <= type(uint8).max
            ? uint8(realPipes)
            : type(uint8).max;
    }

    function _getClaimedAt(address user, Building memory building) internal view returns (uint256) {
        uint256 claimedAt = _claimedAt[user][building.index];
        return claimedAt > building.constructedAt
            ? claimedAt
            : building.constructedAt;
    }

    function _getRecipe(address user, Building memory building) internal view returns (Recipe storage) {
        return _recipes[building.typeId][uint256(_recipe[user][building.index])];
    }

    function _getRawOutput(address user, Building memory building) internal view returns (uint256[] memory) {
        Recipe storage recipe = _getRecipe(user, building);
        uint256[] memory speed = new uint256[](recipe.output.length);
        for (uint256 i; i < speed.length; i++) {
            uint256 mod = _building.getSpeedMod(user, building.index, recipe.output[i].resource);
            speed[i] = recipe.output[i].amount.get(building.level) * mod / PERCENT_PRECISION;
        }
        return speed;
    }

    function _getRawVolume(address user, Building memory building) internal view returns (uint256[] memory) {
        Recipe storage recipe = _getRecipe(user, building);
        uint256[] memory volume = new uint256[](recipe.output.length);
        for (uint256 i; i < volume.length; i++) {
            uint256 mod = _building.getVolumeMod(user, building.index, recipe.output[i].resource);
            volume[i] = recipe.volume[i].get(building.level) * mod / PERCENT_PRECISION;
        }
        return volume;
    }

    function _getMined(address user, Building memory building) internal view returns (uint256[] memory, uint256[] memory) {
        Recipe storage recipe = _getRecipe(user, building);
        uint256 time = block.timestamp - _getClaimedAt(user, building);
        uint256 efficiency = PERCENT_PRECISION;
        /// Loop for all inputs
        for (uint256 i; i < recipe.input.length; i++) {
            InputPipe storage pipe = _inputs[user][building.index][uint8(i)];
            if (pipe.buildingIndex > 0) {
                /// Decrease effeciency based on input pipe
                uint256 ability = recipe.input[uint256(i)].amount.get(building.level);
                (,,uint256 realInput) = IEmPipe(pipe.functionality)
                    .getPipeOutput(user, pipe.buildingIndex, pipe.pipeIndex);
                uint256 rate = realInput * PERCENT_PRECISION / ability;
                if (rate < efficiency) {
                    efficiency = rate;
                }
            } else {
                /// Decrease time based on residual ingredients
                if (i >= _ingredients[user][building.index].length) {
                    time = 0;
                    continue;
                }
                uint256 amount = recipe.input[i].amount.get(building.level) * time;
                if (amount > _ingredients[user][building.index][i]) {
                    uint256 rate = _ingredients[user][building.index][i] * PERCENT_PRECISION / amount;
                    time = time * rate / PERCENT_PRECISION;
                }
            }
        }
        /// Get output
        uint256[] memory mined = _getRawOutput(user, building);
        uint256[] memory volume = _getRawVolume(user, building);
        for (uint256 i; i < mined.length; i++) {
            mined[i] *= time;
            mined[i] = mined[i] * efficiency / PERCENT_PRECISION;
            if (mined[i] > volume[i]) {
                mined[i] = volume[i];
            }
        }
        /// Get spent ingredients
        uint256[] memory spent = new uint256[](recipe.input.length);
        uint256 speed = recipe.output[0].amount.get(building.level);
        for (uint256 i; i < recipe.input.length; i++) {
            uint256 rate = recipe.input[i].amount.get(building.level) * PERCENT_PRECISION / speed;
            spent[i] = mined[0] * rate / PERCENT_PRECISION;
        }
        return (mined, spent);
    }

    function _claim(address user, Building memory building) internal {
        _requirePlantNoConsumers(user, building);
        (uint256[] memory mined, uint256[] memory spent) = _getMined(user, building);
        Recipe storage recipe = _getRecipe(user, building);
        /// Spend ingredients
        for (uint256 i; i < recipe.input.length; i++) {
            if (_inputs[user][building.index][uint8(i)].buildingIndex > 0
                || i >= _ingredients[user][building.index].length) {
                continue;
            }
            {
                uint256 have = _ingredients[user][building.index][i];
                if (spent[i] > have) {
                    spent[i] = have;
                }
            }
            _ingredients[user][building.index][i] -= spent[i];
            IEmResource(recipe.input[i].resource).burn(address(this), spent[i]);
            uint8 recipeId = _recipe[user][building.index];
            emit IngredientSpent(user, building.index, recipeId, recipe.input[i].resource, spent[i], _ingredients[user][building.index][i]);
        }
        /// Mint output
        _claimedAt[user][building.index] = block.timestamp;
        for (uint256 i; i < mined.length; i++) {
            IEmResource(recipe.output[i].resource).mint(user, mined[i]);
            emit Claimed(user, building.index, recipe.output[i].resource, mined[i]);
        }
    }

    function _getOutput(address user, Building memory building, uint256 pipeIndex) internal view returns (uint256) {
        Recipe storage recipe = _getRecipe(user, building);
        uint256 mod = _building.getSpeedMod(user, building.index, recipe.output[pipeIndex].resource);
        /// Get input pipes efficiency
        uint256 efficiency = PERCENT_PRECISION;
        for (uint8 i; i < recipe.input.length; i++) {
            uint256 ability = recipe.input[uint256(i)].amount.get(building.level);
            InputPipe storage pipe = _inputs[user][building.index][i];
            (,,uint256 realInput) = IEmPipe(pipe.functionality)
                .getPipeOutput(user, pipe.buildingIndex, pipe.pipeIndex);
            uint256 rate = realInput * PERCENT_PRECISION / ability;
            if (rate < efficiency) {
                efficiency = rate;
            }
        }
        return recipe.output[pipeIndex].amount.get(building.level)
            * mod / PERCENT_PRECISION
            * efficiency / PERCENT_PRECISION;
    }

}
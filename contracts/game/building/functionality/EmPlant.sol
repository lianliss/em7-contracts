// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ResourceProgression} from "../../lib/structs.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmPlant, Recipe} from "../interfaces/IEmPlant.sol";
import {IEmResource} from "../../../token/EmResource/interfaces/IEmResource.sol";
import {EmPipe, IEmPipe, Building} from "../context/EmPipe.sol";
import {InputPipe} from "../interfaces/structs.sol";
import {PERCENT_PRECISION} from "../../../core/const.sol";

/// @dev Require add to EmResFactory whitelist;
/// @dev Require functionality buildings CONSUMER_ROLE;
contract EmPlant is EmPipe, IEmPlant {

    using EnumerableSet for EnumerableSet.UintSet;
    using Progression for Progression.Params;

    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    EnumerableSet.UintSet internal _types;
    mapping (uint256 typeId => Recipe[] typeRecipes) internal _recipes;
    mapping (address user => mapping(uint256 buildingIndex => uint8 recipeId)) internal _recipe;
    mapping (address user => mapping(uint256 buildingIndex => uint256[] amount)) internal _ingredients;
    mapping (address user => mapping(uint256 buildingIndex => mapping(uint8 sourceId => InputPipe pipe))) internal _inputs;
    mapping (address user => mapping(uint256 buildingIndex => uint256 timestamp)) internal _claimedAt;

    constructor(address buildingAddress, address techAddress) EmPipe(buildingAddress, techAddress) {
        _grantRole(CLAIMER_ROLE, _msgSender());
    }

    function getPipeOutput(address user, uint256 buildingIndex, uint8 pipeIndex) external view returns (address consumer, address resource, uint256 amountPerSecond) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        _requireConstructed(building);
        _requirePipeExists(building, pipeIndex);
        Recipe storage recipe = _getRecipe(user, building);
        return (_consumers[user][buildingIndex][pipeIndex], recipe.output.resource, _getOutput(user, building));
    }


    /// Write methods

    function claim(uint256 buildingIndex) public {
        address user = _msgSender();
        Building memory building = _building.getBuilding(user, buildingIndex);
        _claim(user, building);
    }

    function chooseRecipe(uint256 buildingIndex, uint8 recipeId) public {
        address user = _msgSender();
        require(recipeId != _recipe[user][buildingIndex], "The same recipe chosen");
        Building memory building = _building.getBuilding(user, buildingIndex);
        _requireRecipeExists(building.typeId, recipeId);
        _claim(user, building);
        _releaseIngredients(user, building);
        _recipe[user][buildingIndex] = recipeId;
        emit RecipeChosen(user, buildingIndex, recipeId);
    }

    function fillIngredients(uint256 buildingIndex, uint256[] calldata amounts) public {
        address user = _msgSender();
        Building memory building = _building.getBuilding(user, buildingIndex);
        _fillIngredients(user, building, amounts);
    }

    function releaseIngredients(uint256 buildingIndex) public {
        address user = _msgSender();
        Building memory building = _building.getBuilding(user, buildingIndex);
        _releaseIngredients(user, building);
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
        pipe.lockPipe(user, sourceBuildingIndex, sourcePipeId);
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


    /// Admin methods

    function addRecipe(uint256 typeId, Recipe calldata recipe) public onlyRole(EDITOR_ROLE) {
        _types.add(typeId);
        _recipes[typeId].push(recipe);
        emit RecipeAdded(typeId, recipe);
    }

    function removeType(uint256 typeId) public onlyRole(EDITOR_ROLE) {
        _requireTypeExists(typeId);
        _types.remove(typeId);
        delete _recipes[typeId];
        emit RecipesRemoved(typeId);
    }


    /// External methods

    function claimFor(address user, uint256 buildingIndex) external onlyRole(CLAIMER_ROLE) {
        Building memory building = _building.getBuilding(user, buildingIndex);
        _claim(user, building);
    }

    function lockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) public override onlyRole(CONSUMER_ROLE) {
        _claim(user, _building.getBuilding(user, buildingIndex));
        super.lockPipe(user, buildingIndex, pipeIndex);
    }

    function unlockPipe(address user, uint256 buildingIndex, uint8 pipeIndex) public override onlyRole(CONSUMER_ROLE) {
        super.unlockPipe(user, buildingIndex, pipeIndex);
        _claimedAt[user][buildingIndex] = block.timestamp;
    }


    /// Internal methods

    function _requireTypeExists(uint256 typeId) internal view {
        require(_types.contains(typeId), "Type is not exists");
    }

    function _requireRecipeExists(uint256 typeId, uint256 recipeId) internal view {
        require(recipeId < _recipes[typeId].length, "Recipe is not exists");
    }

    function _requireInputsConnected(address user, Building memory building) internal view {
        Recipe storage recipe = _getRecipe(user, building);
        for (uint8 i; i < recipe.input.length; i++) {
            if (_inputs[user][building.index][i].functionality == address(0)) {
                revert("All input connectors required");
            }
        }
    }

    function _getRecipe(address user, Building memory building) internal view returns (Recipe storage) {
        return _recipes[building.typeId][uint256(_recipe[user][building.index])];
    }

    function _getClaimedAt(address user, Building memory building) internal view returns (uint256) {
        uint256 claimedAt = _claimedAt[user][building.index];
        return claimedAt > building.constructedAt
            ? claimedAt
            : building.constructedAt;
    }

    function _getOutput(address user, Building memory building) internal view returns (uint256) {
        Recipe storage recipe = _getRecipe(user, building);
        uint256 mod = _building.getSpeedMod(user, building.index, recipe.output.resource);
        /// Get input pipes efficiency
        uint256 efficiency = PERCENT_PRECISION;
        for (uint8 i; i < recipe.input.length; i++) {
            uint256 ability = recipe.input[uint256(i)].amount.get(building.level) * mod / PERCENT_PRECISION;
            InputPipe storage pipe = _inputs[user][building.index][i];
            (,,uint256 realInput) = IEmPipe(pipe.functionality)
                .getPipeOutput(user, pipe.buildingIndex, pipe.pipeIndex);
            uint256 rate = realInput * PERCENT_PRECISION / ability;
            if (rate < efficiency) {
                efficiency = rate;
            }
        }
        return recipe.output.amount.get(building.level)
            * mod / PERCENT_PRECISION
            * efficiency / PERCENT_PRECISION;
    }

    function _getRawOutput(address user, Building memory building) internal view returns (uint256) {
        Recipe storage recipe = _getRecipe(user, building);
        uint256 mod = _building.getSpeedMod(user, building.index, recipe.output.resource);
        return recipe.output.amount.get(building.level) * mod / PERCENT_PRECISION;
    }

    function _getRawVolume(address user, Building memory building) internal view returns (uint256) {
        Recipe storage recipe = _getRecipe(user, building);
        uint256 mod = _building.getVolumeMod(user, building.index, recipe.output.resource);
        return recipe.volume.get(building.level) * mod / PERCENT_PRECISION;
    }

    function _getIngredientsVolume(address user, Building memory building, Recipe memory recipe) internal view returns (uint256[] memory) {
        uint256[] memory volume = new uint256[](recipe.input.length);
        uint256 time = _getRawVolume(user, building) / _getRawOutput(user, building);
        for (uint256 i; i < volume.length; i++) {
            volume[i] = recipe.input[i].amount.get(building.level) * time;
        }
        return volume;
    }

    function _getInputSpeed(address user, Building memory building, Recipe memory recipe) internal view returns (uint256[] memory) {
        uint256[] memory speed = new uint256[](recipe.input.length);
        for (uint8 i; i < speed.length; i++) {
            InputPipe memory pipe = _inputs[user][building.index][i];
            (,, uint256 amount) = IEmPipe(pipe.functionality).getPipeOutput(user, pipe.buildingIndex, pipe.pipeIndex);
            speed[uint256(i)] = amount;
        }
        return speed;
    }

    function _getMined(address user, Building memory building) internal view returns (uint256, uint256[] memory) {
        Recipe storage recipe = _getRecipe(user, building);
        uint256 time = block.timestamp - _getClaimedAt(user, building);
        /// Decrease time based on residual ingredients
        for (uint256 i; i < recipe.input.length; i++) {
            uint256 amount = recipe.input[i].amount.get(building.level) * time;
            if (amount > _ingredients[user][building.index][i]) {
                uint256 rate = _ingredients[user][building.index][i] * PERCENT_PRECISION / amount;
                time = time * rate / PERCENT_PRECISION;
            }
        }
        /// Get output
        uint256 mined = _getRawOutput(user, building) * time;
        uint256 volume = _getRawVolume(user, building);
        if (mined > volume) {
            mined = volume;
        }
        /// Get spent ingredients
        uint256[] memory spent = new uint256[](recipe.input.length);
        uint256 speed = recipe.output.amount.get(building.level);
        for (uint256 i; i < recipe.input.length; i++) {
            uint256 rate = recipe.input[i].amount.get(building.level) * PERCENT_PRECISION / speed;
            spent[i] = mined * rate / PERCENT_PRECISION;
        }
        return (mined, spent);
    }

    function _claim(address user, Building memory building) internal {
        _requireNoConsumers(user, building);
        (uint256 mined, uint256[] memory spent) = _getMined(user, building);
        Recipe storage recipe = _getRecipe(user, building);
        /// Spend ingredients
        for (uint256 i; i < recipe.input.length; i++) {
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
        IEmResource(recipe.output.resource).mint(user, mined);
        _claimedAt[user][building.index] = block.timestamp;
        emit Claimed(user, building.index, recipe.output.resource, mined);
    }

    function _fillIngredients(address user, Building memory building, uint256[] memory amounts) internal {
        _claim(user, building);
        Recipe storage recipe = _getRecipe(user, building);
        uint256[] memory volume = _getIngredientsVolume(user, building, recipe);
        for (uint256 i; i < recipe.input.length; i++) {
            if (_ingredients[user][building.index][i] < volume[i]) {
                uint256 amount;
                IEmResource resource;
                {
                    uint256 space = volume[i] - _ingredients[user][building.index][i];
                    amount = space > amounts[i]
                        ? amounts[i]
                        : space;
                    resource = IEmResource(recipe.input[i].resource);
                    uint256 balance = resource.balanceOf(user);
                    if (balance < amount) {
                        amount = balance;
                    }
                }
                if (amount > 0) {
                    resource.transferFrom(user, address(this), amount);
                    _ingredients[user][building.index][i] += amount;
                    uint256 currentAmount = _ingredients[user][building.index][i];
                    emit IngredientFilled(user, building.index, _recipe[user][building.index], address(resource), amount, currentAmount);
                }
            }
        }
    }

    function _releaseIngredients(address user, Building memory building) internal {
        _claim(user, building);
        Recipe storage recipe = _getRecipe(user, building);
        for (uint256 i; i < recipe.input.length; i++) {
            uint256 amount = _ingredients[user][building.index][i];
            if (amount > 0) {
                IEmResource(recipe.input[i].resource).transferFrom(address(this), user, amount);
            }
        }
        delete _ingredients[user][building.index];
        emit IngredientsReleased(user, building.index);
    }

    function _disconnectSource(address user, Building memory building, uint8 sourceIndex) internal {
        InputPipe storage pipe = _inputs[user][building.index][sourceIndex];
        if (pipe.functionality == address(0)) return;
        IEmPipe(pipe.functionality).unlockPipe(user, pipe.buildingIndex, pipe.pipeIndex);
        delete _inputs[user][building.index][sourceIndex];
        emit SourceDisconnected(user, building.index, sourceIndex);
    }

}
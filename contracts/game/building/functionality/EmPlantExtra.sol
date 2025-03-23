//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {ResourceProgression} from "../../lib/structs.sol";
import {Progression} from "../../../utils/Progression.sol";
import {Recipe} from "../interfaces/structs.sol";
import {IEmResource} from "../../../token/EmResource/interfaces/IEmResource.sol";
import {EmPipe, Building} from "./EmPipe.sol";
import {PERCENT_PRECISION} from "../../../core/const.sol";
import {EmPlantContext} from "../context/EmPlantContext.sol";
import {EmPipeContext} from "../context/EmPipeContext.sol";
import {ProxyImplementation} from "../../../Proxy/ProxyImplementation.sol";
import {IEmPlantExtra} from "../interfaces/IEmPlantExtra.sol";
import {EmPlantInternal} from "../functionality/EmPlantInternal.sol";
import {Errors} from "../../errors.sol";

contract EmPlantExtra is EmPipeContext, EmPlantContext, ProxyImplementation, EmPlantInternal, IEmPlantExtra {

    using EnumerableSet for EnumerableSet.UintSet;
    using Progression for Progression.Params;

    constructor(
        address plantAddress
    ) ProxyImplementation(plantAddress) {
        _grantRole(CLAIMER_ROLE, _msgSender());
    }

    function _chooseRecipe(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xChooseRecipe(bytes)", encoded);
        if (isProxy) {
            (
                address user,
                uint256 buildingIndex,
                uint8 recipeId
            ) = abi.decode(encoded, (address, uint256, uint8));
            require(recipeId != _recipe[user][buildingIndex], "The same recipe chosen");
            Building memory building = _building.getBuilding(user, buildingIndex);
            _requireRecipeExists(building.typeId, recipeId);
            _claim(user, building);
            _releaseIngredients(user, building);
            _recipe[user][buildingIndex] = recipeId;
            emit RecipeChosen(user, buildingIndex, recipeId);
        }
    }
    /// @notice Proxy entrance
    function xChooseRecipe(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _chooseRecipe(encoded);
    }
    /// @notice Switches the building recipe;
    /// @param buildingIndex User building identificator;
    /// @param recipeId Recipe index;
    /// @dev It makes claim and releases residual ingredients first;
    /// @dev Require all pipes disconnected;
    function chooseRecipe(uint256 buildingIndex, uint8 recipeId) public {
        address user = _msgSender();
        _chooseRecipe(abi.encode(user, buildingIndex, recipeId));
    }


    function _fillIngredients(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xFillIngredients(bytes)", encoded);
        if (isProxy) {
            (
                address user,
                uint256 buildingIndex,
                uint256[] memory amounts
            ) = abi.decode(encoded, (address, uint256, uint256[]));
            Building memory building = _building.getBuilding(user, buildingIndex);
            _fillIngredients(user, building, amounts);
        }
    }
    /// @notice Proxy entrance
    function xFillIngredients(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _fillIngredients(encoded);
    }
    /// @notice Fills the plant with the ingredients;
    /// @param buildingIndex User building identificator;
    /// @param amounts Array of amounts of resources described in the recipe;
    function fillIngredients(uint256 buildingIndex, uint256[] calldata amounts) public {
        address user = _msgSender();
        _fillIngredients(abi.encode(user, buildingIndex, amounts));
    }


    function _releaseIngredients(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xReleaseIngredients(bytes)", encoded);
        if (isProxy) {
            (
                address user,
                uint256 buildingIndex
            ) = abi.decode(encoded, (address, uint256));
            Building memory building = _building.getBuilding(user, buildingIndex);
            _releaseIngredients(user, building);
        }
    }
    /// @notice Proxy entrance
    function xReleaseIngredients(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _fillIngredients(encoded);
    }
    /// @notice Returns ingredients from the plant;
    /// @param buildingIndex User building identificator;
    function releaseIngredients(uint256 buildingIndex) public {
        address user = _msgSender();
        _fillIngredients(abi.encode(user, buildingIndex));
    }


    /// Admin methods

    function _addRecipe(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xAddRecipe(bytes)", encoded);
        if (isProxy) {
            (
                uint256 typeId,
                ResourceProgression[] memory input,
                ResourceProgression[] memory output,
                Progression.Params[] memory volume
            ) = abi.decode(encoded, (
                uint256,
                ResourceProgression[],
                ResourceProgression[],
                Progression.Params[]
            ));
            require(output.length == volume.length, "Output and Volume lengths mismatch");
            _types.add(typeId);
            uint8 recipeId = uint8(_recipes[typeId].length);
            _recipes[typeId].push();
            _recipes[typeId][recipeId].recipeId = recipeId;
            _recipes[typeId][recipeId].typeId = typeId;
            for (uint256 i; i < input.length; i++) {
                _recipes[typeId][recipeId].input.push(input[i]);
            }
            for (uint256 i; i < output.length; i++) {
                _recipes[typeId][recipeId].output.push(output[i]);
                _recipes[typeId][recipeId].volume.push(volume[i]);
            }
            emit RecipeAdded(typeId, _recipes[typeId][recipeId]);
        }
    }
    /// @notice Proxy entrance
    function xAddRecipe(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _addRecipe(encoded);
    }
    /// @notice Add new recipe to the type;
    /// @param typeId Building type index;
    /// @param input Ingredients resources with progression;
    /// @param output Output resources with progression;
    /// @param volume Output resources storage size;
    /// @dev Require role EDITOR_ROLE
    function addRecipe(
        uint256 typeId,
        ResourceProgression[] memory input,
        ResourceProgression[] memory output,
        Progression.Params[] memory volume
    ) public onlyRole(EDITOR_ROLE) {
        _addRecipe(abi.encode(typeId, input, output, volume));
    }


    function _removeType(bytes memory encoded) internal {
        (bool isProxy,) = routedDelegate("xRemoveType(bytes)", encoded);
        if (isProxy) {
            (
                uint256 typeId
            ) = abi.decode(encoded, (
                uint256
            ));
            _requireTypeExists(typeId);
            _types.remove(typeId);
            delete _recipes[typeId];
            emit RecipesRemoved(typeId);
        }
    }
    /// @notice Proxy entrance
    function xRemoveType(bytes memory encoded) public onlyRole(PROXY_ROLE) {
        _removeType(encoded);
    }
    /// @notice Removes plant type with it's recipes;
    /// @param typeId Building type index;
    /// @dev Require role EDITOR_ROLE
    function removeType(
        uint256 typeId
    ) public onlyRole(EDITOR_ROLE) {
        _removeType(abi.encode(typeId));
    }


    /// Internal methods

    function _requireSourcesDisconnected(address user, Building memory building) internal view {
        Recipe storage recipe = _getRecipe(user, building);
        for (uint8 i; i < uint8(recipe.input.length); i++) {
            if (_inputs[user][building.index][i].functionality != address(0)) {
                revert Errors.HaveSourcesError(i, _inputs[user][building.index][i].functionality);
            }
        }
    }

    function _getIngredientsVolume(address user, Building memory building, Recipe memory recipe) internal view returns (uint256[] memory) {
        uint256[] memory inVolume = new uint256[](recipe.input.length);
        uint256[] memory volume = _getRawVolume(user, building);
        uint256[] memory speed = _getRawOutput(user, building);
        uint256 time = volume[0] / speed[0];
        for (uint256 i; i < volume.length; i++) {
            uint256 currentTime = volume[i] / speed[i];
            if (currentTime > time) {
                time = currentTime;
            }
        }
        for (uint256 i; i < inVolume.length; i++) {
            inVolume[i] = recipe.input[i].amount.get(building.level) * time;
        }
        return inVolume;
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

}
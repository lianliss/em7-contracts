// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ResourceProgression} from "../../lib/structs.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmClaimer} from "./IEmClaimer.sol";

struct Recipe {
    ResourceProgression[] input;
    ResourceProgression output;
    Progression.Params volume;
}

interface IEmPlant is IEmClaimer {

    event RecipeAdded(uint256 indexed typeId, Recipe recipe);
    event RecipesRemoved(uint256 indexed typeId);
    event RecipeChosen(address indexed user, uint256 indexed buildingIndex, uint8 indexed recipeId);
    event IngredientFilled(address indexed user, uint256 indexed buildingIndex, uint8 indexed recipeId, address resource, uint256 amount, uint256 currentAmount);
    event IngredientSpent(address indexed user, uint256 indexed buildingIndex, uint8 indexed recipeId, address resource, uint256 amount, uint256 currentAmount);
    event IngredientsReleased(address indexed user, uint256 indexed buildingIndex);
    event SourceDisconnected(address indexed user, uint256 indexed buildingIndex, uint8 sourceIndex);
    event SourceConnected(address indexed user, uint256 indexed buildingIndex, uint8 sourceIndex, address sourceAddress, uint256 sourceBuildingIndex, uint8 sourcePipeId);

}
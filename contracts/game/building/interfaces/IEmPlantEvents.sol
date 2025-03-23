//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.24;

import {Recipe} from "./structs.sol";

interface IEmPlantEvents {
    
    event Claimed(address indexed user, uint256 indexed buildingIndex, address indexed resource, uint256 amount);
    event RecipeAdded(uint256 indexed typeId, Recipe recipe);
    event RecipesRemoved(uint256 indexed typeId);
    event RecipeChosen(address indexed user, uint256 indexed buildingIndex, uint8 indexed recipeId);
    event IngredientFilled(address indexed user, uint256 indexed buildingIndex, uint8 indexed recipeId, address resource, uint256 amount, uint256 currentAmount);
    event IngredientSpent(address indexed user, uint256 indexed buildingIndex, uint8 indexed recipeId, address resource, uint256 amount, uint256 currentAmount);
    event IngredientsReleased(address indexed user, uint256 indexed buildingIndex);
    event SourceDisconnected(address indexed user, uint256 indexed buildingIndex, uint8 sourceIndex);
    event SourceConnected(address indexed user, uint256 indexed buildingIndex, uint8 sourceIndex, address sourceAddress, uint256 sourceBuildingIndex, uint8 sourcePipeId);

}
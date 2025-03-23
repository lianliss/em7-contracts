// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Progression} from "../../../utils/Progression.sol";
import {Recipe} from "../interfaces/structs.sol";
import {EmPipeContext} from "./EmPipeContext.sol";
import {InputPipe} from "../interfaces/structs.sol";

/// @dev Require add to EmResFactory whitelist;
/// @dev Require functionality buildings CONSUMER_ROLE;
abstract contract EmPlantContext is EmPipeContext {

    using EnumerableSet for EnumerableSet.UintSet;
    using Progression for Progression.Params;

    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    EnumerableSet.UintSet internal _types;
    mapping (uint256 typeId => Recipe[] typeRecipes) internal _recipes;
    mapping (address user => mapping(uint256 buildingIndex => uint8 recipeId)) internal _recipe;
    mapping (address user => mapping(uint256 buildingIndex => uint256[] amount)) internal _ingredients;
    mapping (address user => mapping(uint256 buildingIndex => mapping(uint8 sourceId => InputPipe pipe))) internal _inputs;
    mapping (address user => mapping(uint256 buildingIndex => uint256 timestamp)) internal _claimedAt;

}
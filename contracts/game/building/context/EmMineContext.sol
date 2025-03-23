// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Progression} from "../../../utils/Progression.sol";
import {EmPipeContext} from "./EmPipeContext.sol";

contract EmMineContext is EmPipeContext {

    using EnumerableSet for EnumerableSet.UintSet;
    using Progression for Progression.Params;

    bytes32 public constant CLAIMER_ROLE = keccak256("CLAIMER_ROLE");

    EnumerableSet.UintSet internal _types;
    mapping (uint256 typeId => address resource) internal _resource;
    mapping (uint256 typeId => Progression.Params amountPerSecond) internal _output;
    mapping (uint256 typeId => Progression.Params volume) internal _volume;
    mapping (address user => mapping(uint256 buildingIndex => uint256 timestamp)) internal _claimedAt;

}
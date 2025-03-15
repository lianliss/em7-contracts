// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Range} from "../lib/structs.sol";
import {PERCENT_PRECISION} from "../../core/const.sol";

library Modificator {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Mod {
        EnumerableSet.Bytes32Set sources;
        mapping (bytes32 source => uint256 value) values;
    }

    function add(Mod storage stored, bytes32 sourceId, uint256 value) internal {
        stored.sources.add(sourceId);
        stored.values[sourceId] = value;
    }

    function remove(Mod storage stored, bytes32 sourceId) internal {
        stored.sources.remove(sourceId);
    }

    function at(Mod storage stored, bytes32 sourceId) internal view returns (uint256) {
        if (stored.sources.contains(sourceId)) {
            return stored.values[sourceId];
        } else {
            return PERCENT_PRECISION;
        }
    }

    function get(Mod storage mod) internal view returns (uint256 value) {
        value = PERCENT_PRECISION;
        for (uint256 i; i < mod.sources.length(); i++) {
            value = value * mod.values[mod.sources.at(i)] / PERCENT_PRECISION;
        }
    }

    function get(Mod storage mod, Range.Values memory limits) internal view returns (uint256 value) {
        value = get(mod);
        if (limits.min > 0 && value < limits.min) {
            value = limits.min;
        } else if (limits.max > 0 && value > limits.max) {
            value = limits.max;
        }
    }

}
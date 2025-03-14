// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Range} from "../../lib/structs.sol";
import {PERCENT_PRECISION} from "../../../core/const.sol";

struct Slot {
    uint256 slotIndex;
    string title;
    uint256 minLevel;
    bool disabled;
    bool independent;
}

struct Parameter {
    uint256 paramId;
    string title;
    Range.Values limits;
}

library Modificator {

    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Mod {
        EnumerableSet.Bytes32Set sources;
        mapping (bytes32 source => uint256 value) values;
    }

    function get(Mod storage mod) internal view returns (uint256 value) {
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
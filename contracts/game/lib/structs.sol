// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Progression} from "../../utils/Progression.sol";

struct ResourceProgression {
    address resource;
    Progression.Params amount;
}

library Range {

    struct Values {
        uint256 min;
        uint256 max;
    }

    function range(Values memory values) internal pure returns (uint256) {
        return values.max >= values.min
            ? values.max - values.min
            : values.min - values.max;
    }

    function inRange(Values memory values, uint256 value) internal pure returns (bool) {
        return value >= values.min && value <= values.max;
    }

}
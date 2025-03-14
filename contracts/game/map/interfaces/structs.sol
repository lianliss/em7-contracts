// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Coords} from "../../lib/coords.sol";

struct Object {
    Coords.Point origin;
    uint8 size;
    uint256 buildingIndex;
}
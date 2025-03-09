// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Progression} from "../utils/Progression.sol";

struct ResourceProgression {
    address resource;
    Progression.ProgressionParams amount;
}
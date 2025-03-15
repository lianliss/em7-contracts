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

struct ParameterMod {
    uint256 paramId;
    string title;
    uint256 value;
}

struct Item {
    address tokenAddress;
    uint256 tokenId;
}
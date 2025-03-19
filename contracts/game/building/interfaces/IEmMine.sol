// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ResourceProgression} from "../../lib/structs.sol";

interface IEmMine {

    event TypeParamsSet(uint256 indexed typeId, address indexed resource, ResourceProgression speed, ResourceProgression volume);
    event Claimed(address indexed user, uint256 indexed buildingIndex, address indexed resource, uint256 amount);

}
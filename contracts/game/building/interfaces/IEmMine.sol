// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ResourceProgression} from "../../lib/structs.sol";
import {Mine, MineType} from "./structs.sol";
import {Progression} from "../../../utils/Progression.sol";
import {IEmClaimer} from "./IEmClaimer.sol";

interface IEmMine is IEmClaimer {

    event Claimed(address indexed user, uint256 indexed buildingIndex, address indexed resource, uint256 amount);
    event TypeParamsSet(uint256 indexed typeId, address indexed resource, Progression.Params speed, Progression.Params volume, Progression.Params pipes);
    event TypeRemoved(uint256 indexed typeId);

    function getTypes(uint256 offset, uint256 limit) external view returns (MineType[] memory, uint256 count);
    function getType(uint256 typeId) external view returns (MineType memory data);
    function getMine(address user, uint256 buildingIndex) external view returns (Mine memory mine);
    function getMines(address user, uint256[] calldata buildingIndex) external view returns (Mine[] memory);
    function claim(uint256 buildingIndex) external;

    function setTypeParams(uint256 typeId, address resourceAddress, Progression.Params memory output, Progression.Params memory volume, Progression.Params memory pipes) external;
    function removeType(uint256 typeId) external;

}
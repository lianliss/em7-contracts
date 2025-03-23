// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EmPipeContext} from "../context/EmPipeContext.sol";
import {Progression} from "../../../utils/Progression.sol";
import {Building} from "../interfaces/structs.sol";
import {Errors} from "../../errors.sol";

/// @notice Pipe internal methods;
/// @dev Use in building functionality contract;
abstract contract EmPipeInternal is EmPipeContext {

    using Progression for Progression.Params;

    function _requireConstructed(Building memory building) internal view virtual {
        require(building.constructedAt <= block.timestamp, "Building is not constructed");
    }

    function _requirePipeExists(Building memory building, uint8 pipeIndex) internal view virtual {
        require(pipeIndex < _getPipes(building), "Pipe is not reachable");
    }

    function _requireNoConsumers(address user, Building memory building) internal view virtual {
        uint8 pipes = _getPipes(building);
        for (uint8 i; i < pipes; i++) {
            if (_consumers[user][building.index][i] != address(0)) {
                revert Errors.HaveConsumersError(i, _consumers[user][building.index][i]);
            }
        }
    }

    function _getPipes(Building memory building) internal view virtual returns (uint8) {
        uint256 realPipes = _pipes[building.typeId].get(building.level);
        return realPipes <= type(uint8).max
            ? uint8(realPipes)
            : type(uint8).max;
    }

    function _getConsumers(address user, Building memory building) internal view virtual returns (address[] memory) {
        uint8 pipes = _getPipes(building);
        address[] memory consumers = new address[](pipes);
        for (uint8 i; i < pipes; i++) {
            consumers[i] = _consumers[user][building.index][i];
        }
        return consumers;
    }

}
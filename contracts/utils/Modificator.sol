// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

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
            return 0;
        }
    }

    function get(Mod storage stored) internal view returns (uint256) {
        uint256 sum;
        uint256 length = stored.sources.length();
        for (uint256 i; i < length; i++) {
            sum += stored.values[stored.sources.at(i)];
        }
        return sum;
    }

}
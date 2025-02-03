// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MemoryQueue} from "./MemoryQueue.sol";

library OrderedArrays {
    using MemoryQueue for MemoryQueue.Queue;

    function mergeAsc(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory) {
        MemoryQueue.Queue memory q;
        uint256 ai;
        uint256 bi;

        while (ai < a.length || bi < b.length) {
            if (bi >= b.length || a[ai] < b[bi] ) {
                q.push(a[ai++]);
            } else if (ai >= a.length || a[ai] > b[bi]) {
                q.push(b[bi++]);
            } else {
                q.push(a[ai++]);
                bi++;
            }
        }
        return q.values();
    }

    function merge(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory) {
        return mergeAsc(a, b);
    }

    function mergeDesc(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory) {
        MemoryQueue.Queue memory q;
        uint256 ai;
        uint256 bi;

        while (ai < a.length || bi < b.length) {
            if (bi >= b.length || a[ai] > b[bi] ) {
                q.push(a[ai++]);
            } else if (ai >= a.length || a[ai] < b[bi]) {
                q.push(b[bi++]);
            } else {
                q.push(a[ai++]);
                bi++;
            }
        }
        return q.values();
    }

}
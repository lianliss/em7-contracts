// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {OrderedArrays, MemoryQueue} from "./utils/sequence/OrderedArrays.sol";
import {StorageQueue} from "./utils/sequence/StorageQueue.sol";

contract Test {
    using StorageQueue for StorageQueue.Queue;
    using MemoryQueue for MemoryQueue.Queue;

    StorageQueue.Queue public s;

    function test() public pure returns(uint256[] memory resultQ) {
        uint256[] memory a = new uint256[](2);
        a[0] = 7;
        a[1] = 3;

        uint256[] memory b = new uint256[](4);
        b[0] = 8;
        b[1] = 4;
        b[2] = 2;
        b[3] = 1;
        
        return (OrderedArrays.mergeDesc(b,b));
    }

    function testQ(uint256[] calldata values) public pure returns (uint256[] memory) {
        MemoryQueue.Queue memory q;
        for (uint256 i; i < values.length; i++) {
            q.push(values[i]);
        }
        return q.toArray();
    }

    function pushS(uint256 value) public {
        s.push(value);
    }

    function testS(uint256[] calldata values) public {
        MemoryQueue.Queue memory q;
        for (uint256 i; i < values.length; i++) {
            q.push(values[i]);
        }
        s._buffer = q._buffer;
    }

    function getS() public view returns (uint256[] memory) {
        return s.toArray();
    }

}
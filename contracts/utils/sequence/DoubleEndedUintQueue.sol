// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DoubleEndedQueue} from "@openzeppelin/contracts/utils/structs/DoubleEndedQueue.sol";

library DoubleEndedUintQueue {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;

    struct UintQueue {
        DoubleEndedQueue.Bytes32Deque _inner;
    }

    function pushBack(UintQueue storage deque, uint256 value) internal {
        deque._inner.pushBack(bytes32(value));
    }

    function popBack(UintQueue storage deque) internal returns (uint256 value) {
        return uint256(deque._inner.popBack());
    }

    function pushFront(UintQueue storage deque, uint256 value) internal {
        deque._inner.pushFront(bytes32(value));
    }

    function popFront(UintQueue storage deque) internal returns (uint256 value) {
        return uint256(deque._inner.popFront());
    }

    function front(UintQueue storage deque) internal view returns (uint256 value) {
        return uint256(deque._inner.front());
    }

    function back(UintQueue storage deque) internal view returns (uint256 value) {
        return uint256(deque._inner.back());
    }

    function at(UintQueue storage deque, uint256 index) internal view returns (uint256 value) {
        return uint256(deque._inner.at(index));
    }

    function clear(UintQueue storage deque) internal {
        deque._inner.clear();
    }

    function length(UintQueue storage deque) internal view returns (uint256) {
        return deque._inner.length();
    }

    function empty(UintQueue storage deque) internal view returns (bool) {
        return deque._inner.empty();
    }

}
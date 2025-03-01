// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Panic} from "@openzeppelin/contracts/utils/Panic.sol";

library StorageQueue {

    struct Queue {
        bytes _buffer;
    }

    uint256 constant DEFAULT_SIZE = 32;

    function _slice(bytes memory buffer, uint256 start, uint256 end) internal pure returns (bytes memory) {
        // sanitize
        uint256 bytesLength = buffer.length;
        end = end < bytesLength ? end : bytesLength;
        start = start < end ? start : end;

        // allocate and copy
        bytes memory result = new bytes(end - start);
        assembly ("memory-safe") {
            mcopy(add(result, 0x20), add(buffer, add(start, 0x20)), sub(end, start))
        }

        return result;
    }

    function pushFirst(Queue storage q, uint256 value) internal {
        q._buffer = bytes.concat(abi.encode(value), q._buffer);
    }

    function pushLast(Queue storage q, uint256 value) internal {
        q._buffer = bytes.concat(q._buffer, abi.encode(value));
    }

    function push(Queue storage q, uint256 value) internal {
        pushLast(q, value);
    }

    function popFirst(Queue storage q) internal returns (uint256 value) {
        if (length(q) == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);
        value = uint256(bytes32(q._buffer));
        q._buffer = _slice(q._buffer, 32, q._buffer.length);
    }

    function popLast(Queue storage q) internal returns (uint256 value) {
        if (length(q) == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);
        value = uint256(bytes32(_slice(q._buffer, q._buffer.length - DEFAULT_SIZE, q._buffer.length)));
        q._buffer = _slice(q._buffer, 0, q._buffer.length - DEFAULT_SIZE);
    }

    function insert(Queue storage q, uint256 index, uint256 value) internal {
        if (index > length(q)) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);
        q._buffer = bytes.concat(
            _slice(q._buffer, 0, index * DEFAULT_SIZE),
            abi.encode(value),
            _slice(q._buffer, index * DEFAULT_SIZE, q._buffer.length)
        );
    }

    function clear(Queue storage q) internal {
        delete q._buffer;
    }

    function pop(Queue storage q, uint256 index) internal returns (uint256 value) {
        if (length(q) == 0) Panic.panic(Panic.EMPTY_ARRAY_POP);
        value = at(q, index);
        q._buffer = bytes.concat(
            _slice(q._buffer, 0, index * DEFAULT_SIZE),
            _slice(q._buffer, (index + 1) * DEFAULT_SIZE, q._buffer.length)
        );
    }

    function pop(Queue storage q) internal returns (uint256 value) {
        return pop(q, length(q) - 1);
    }

    function at(Queue storage q, uint256 index) internal view returns (uint256 value) {
        if (index >= length(q)) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);
        value = uint256(bytes32(_slice(q._buffer, index * DEFAULT_SIZE, (index + 1) * DEFAULT_SIZE)));
    }

    function first(Queue storage q) internal view returns (uint256 value) {
        if (length(q) == 0) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);
        return at(q, 0);
    }

    function last(Queue storage q) internal view returns (uint256 value) {
        if (length(q) == 0) Panic.panic(Panic.ARRAY_OUT_OF_BOUNDS);
        return at(q, length(q) - 1);
    }

    function length(Queue storage q) internal view returns (uint256) {
        return q._buffer.length / DEFAULT_SIZE;
    }

    function values(Queue storage q) internal view returns (uint256[] memory) {
        bytes memory b = bytes.concat(
            abi.encode(0x20, q._buffer.length / DEFAULT_SIZE),
            q._buffer
        );
        (uint256[] memory array) = abi.decode(b, (uint256[]));
        return array;
    }

    function toArray(Queue storage q) internal view returns (uint256[] memory) {
        return values(q);
    }

    function fromArray(Queue storage q, uint256[] memory array) internal {
        bytes memory encoded = abi.encode(array);
        q._buffer = _slice(encoded, 64, encoded.length);
    }

}
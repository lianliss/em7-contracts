// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library Coords {

    uint256 constant AREA_SIZE = 4;

    struct Point {
        uint256 x;
        uint256 y;
    }

    function area(Point memory point) internal pure returns (Point memory) {
        return Point(
            point.x / AREA_SIZE * AREA_SIZE,
            point.y / AREA_SIZE * AREA_SIZE
        );
    }

    function hash(Point memory point) internal pure returns (bytes32) {
        return keccak256(abi.encode(point.x, point.y));
    }

}
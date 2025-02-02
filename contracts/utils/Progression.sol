// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


library Progression {

    struct ProgressionParams {
        uint256 base;
        uint8 geometric;
        uint256 step;
    }

    function get(ProgressionParams storage params, uint256 level) external view returns (uint256) {
        return params.base
            * uint256(params.geometric)**level
            + params.step * level;
    }

}
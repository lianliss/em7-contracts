// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

struct ReferralPercents {
    address parentAddress;
    uint256 percents;
}

interface IEmReferralPercents {

    function getReferralPercents(address childAddress) external view returns (ReferralPercents[] memory);

}
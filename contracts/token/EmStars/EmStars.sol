// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IEmAuth} from "../../core/auth/interfaces/IEmAuth.sol";
import {DoubleEndedUintQueue} from "../../utils/DoubleEndedUintQueue.sol";
import {IEmStars} from "./interfaces/IEmStars.sol";
import {IEmReferralPercents, ReferralPercents} from "../../core/referral/interfaces/IEmReferralPercents.sol";
import {IIncomeDistributor} from "../../core/income/interfaces/IIncomeDistributor.sol";

contract EmStars is ERC20, AccessControl, IEmStars {

    using DoubleEndedUintQueue for DoubleEndedUintQueue.UintQueue;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IEmAuth private _auth;
    IEmReferralPercents private _ref;
    IIncomeDistributor private _income;

    mapping (address holder => DoubleEndedUintQueue.UintQueue date) private _lockDate;
    mapping (address holder => mapping (uint256 date => uint256 value)) private _lockValue;

    DoubleEndedUintQueue.UintQueue private _commonLockDate;
    mapping (uint256 date => uint256 value) private _commonLockValue;

    constructor() ERC20("EmStars", "EMSTR") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

}
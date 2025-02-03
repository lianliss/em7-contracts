// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IEmAuth} from "../../core/auth/interfaces/IEmAuth.sol";
import {MemoryQueue} from "../../utils/sequence/MemoryQueue.sol";
import {StorageQueue} from "../../utils/sequence/StorageQueue.sol";
import {IEmStars} from "./interfaces/IEmStars.sol";
import {IEmReferralPercents, ReferralPercents} from "../../core/referral/interfaces/IEmReferralPercents.sol";
import {IIncomeDistributor} from "../../core/income/interfaces/IIncomeDistributor.sol";

contract EmStars is ERC20, AccessControl, IEmStars {

    using MemoryQueue for MemoryQueue.Queue;
    using StorageQueue for StorageQueue.Queue;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// Auth contract for users ban
    IEmAuth private _auth;
    /// Referral tree getter
    IEmReferralPercents private _ref;
    /// Income distribution
    IIncomeDistributor private _income;

    /// Standart ERC20 variables for overriding
    mapping(address account => uint256) private _balances;
    mapping(address account => mapping(address spender => uint256)) private _allowances;
    uint256 private _totalSupply;

    /// Holders lockups and it's dates
    mapping (address holder => StorageQueue.Queue date) private _lockupDate;
    mapping (address holder => mapping (uint256 date => uint256 value)) private _lockupValue;

    /// Total supply lockups and it's dates
    StorageQueue.Queue private _commonLockupDate;
    mapping (uint256 date => uint256 value) private _commonLockupValue;

    /// Lockup time for mint refundable funds
    uint256 private _lockupTime = 21 days;
    /// Minimum lockup date size for rounding and indexing
    uint256 private constant LOCKUP_UNIT = 1 days;

    constructor() ERC20("EmStars", "EMSTR") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
    }

    event CommonLockupsUnlocked(uint256 amount, uint256 totalSupply);
    event LockupsUnlocked(address indexed holder, uint256 amount, uint256 balance);
    event LockupMinted(address indexed holder, uint256 indexed date, uint256 amount);

    /// @notice Unlocks ready common lockups and increases total supply
    function _unlockCommon() internal {
        uint256 unlocks;
        while (_commonLockupDate.length() > 0) {
            uint256 date = _commonLockupDate.first();
            if (date >= block.timestamp) {
                _commonLockupDate.popFirst();
                unlocks += _commonLockupValue[date];
                delete _commonLockupValue[date];
            } else {
                break;
            }
        }
        if (unlocks > 0) {
            _totalSupply += unlocks;
            emit CommonLockupsUnlocked(unlocks, _totalSupply);
        }
    }

    /// @notice Unlocks ready lockups and increases holder balance
    /// @param holder Lockups owner
    function _unlock(address holder) internal {
        uint256 unlocks;
        while (_lockupDate[holder].length() > 0) {
            uint256 date = _lockupDate[holder].first();
            if (date >= block.timestamp) {
                _lockupDate[holder].popFirst();
                unlocks += _lockupValue[holder][date];
                delete _lockupValue[holder][date];
            } else {
                break;
            }
        }
        if (unlocks > 0) {
            _balances[holder] += unlocks;
            emit LockupsUnlocked(holder, unlocks, _balances[holder]);
        }
    }

    /// @notice Unlock ready lockups of IncomeDistributor contract and call spread function
    /// @dev Locked balance of IncomeDistributor is stored on it's address as usual holder.
    function _unlockIncome() internal {
        address incomeAddress = address(_income);
        _unlock(incomeAddress);
        if (_balances[incomeAddress] > 0) {
            /// Allow to spend
            _allowances[incomeAddress][incomeAddress] = _balances[incomeAddress];
            _income.spreadFrom(incomeAddress, _balances[incomeAddress]);
        }
    }

    /// @notice Returns next lockup date based on block timestamp
    /// @return Rounded lockup date
    function _getLockupDate() internal view returns (uint256) {
        return block.timestamp / LOCKUP_UNIT * LOCKUP_UNIT + _lockupTime;
    }

    /// @notice Mint a new lockup or increase exists one
    /// @param holder Lockups owner
    /// @param amount Amount to mint
    function _mintLockup(address holder, uint256 amount) internal {
        /// Unlock previous ready lockups
        _unlockCommon();
        _unlock(holder);

        uint256 date = _getLockupDate();
        if (date > _lockupDate[holder].last()) {
            /// Add new date mark if it's not exists
            _lockupDate[holder].push(date);
        }
        _lockupValue[holder][date] += amount;
        emit Transfer(address(0), holder, amount);
        emit LockupMinted(holder, date, amount);
    }

    /// @notice Returns holder lockups sum
    /// @param holder Lockups owner
    /// @return amount Lockups sum
    function _getLockups(address holder) internal view returns (uint256 amount) {
        for (uint256 i; i < _lockupDate[holder].length(); i++) {
            amount += _lockupValue[holder][_lockupDate[holder].at(i)];
        }
    }

    /// @notice Try to spend amount from holder lockups
    /// @param holder Lockups owner
    /// @param amount Amount to spend
    /// @return Lockup dates queue
    /// @return Lockup values queue
    /// @return Remaining payment
    function _spendLockups(address holder, uint256 amount)
    internal
    returns (uint256[] memory, uint256[] memory, uint256) {
        MemoryQueue.Queue memory dates;
        MemoryQueue.Queue memory values;

        while (amount > 0 || _lockupDate[holder].length() > 0) {
            /// Current values
            uint256 date = _lockupDate[holder].first();
            uint256 value = _lockupValue[holder][date];

            if (value <= amount) {
                /// Spend full amount of this lockup and remove it
                amount -= value;
                _lockupDate[holder].popFirst();
                delete _lockupValue[holder][date];
                /// Add to result queues
                dates.push(date);
                values.push(value);
            } else {
                /// Spend a part of this lockup
                _lockupValue[holder][date] -= amount;
                /// Add to result queues
                dates.push(date);
                values.push(amount);
                /// Clear amount and stop the loop
                amount = 0;
                break;
            }
        }
        return (dates.toArray(), values.toArray(), amount);
    }

}
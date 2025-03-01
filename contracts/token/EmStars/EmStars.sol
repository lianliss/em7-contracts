// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IEmAuth} from "../../core/auth/interfaces/IEmAuth.sol";
import {MemoryQueue} from "../../utils/sequence/MemoryQueue.sol";
import {StorageQueue} from "../../utils/sequence/StorageQueue.sol";
import {OrderedArrays} from "../../utils/sequence/OrderedArrays.sol";
import {IEmStars, Lockup} from "./interfaces/IEmStars.sol";
import {IEmReferralPercents, ReferralPercents} from "../../core/referral/interfaces/IEmReferralPercents.sol";
import {IIncomeDistributor} from "../../core/income/interfaces/IIncomeDistributor.sol";
import {PERCENT_PRECISION} from "../../core/const.sol";

contract EmStars is ERC20, AccessControl, IEmStars {

    using MemoryQueue for MemoryQueue.Queue;
    using StorageQueue for StorageQueue.Queue;
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");

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

    /// Holder's lockups and it's dates
    mapping (address holder => StorageQueue.Queue date) private _lockupDate;
    mapping (address holder => mapping (uint256 date => uint256 value)) private _lockupValue;
    /// Holders's spents 
    mapping (address holder => mapping (uint256 date => uint256 value)) private _Spent;
    mapping (address holder => uint256 value) private _holderSpentTotal;

    /// Total supply lockups and it's dates
    StorageQueue.Queue private _commonLockupDate;
    mapping (uint256 date => uint256 value) private _commonLockupValue;

    /// Lockup time for mint refundable funds
    uint256 private immutable DEFAULT_LOCKUP_TIME;
    /// Minimum lockup date size for rounding and indexing
    uint256 private immutable LOCKUP_UNIT;
    mapping(address minter => uint256 lockupTime) private minterLockupTime;

    constructor(
        uint256 defaultLockupTime, /// Default 95 days = 8208000 seconds
        uint256 lockupUnitSeconds, /// Default 5 days = 432000 seconds
        address authAddress,
        address refAddress
    ) ERC20("EmStars", "EMSTR") {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MINTER_ROLE, _msgSender());
        _grantRole(SPENDER_ROLE, _msgSender());

        DEFAULT_LOCKUP_TIME = defaultLockupTime;
        LOCKUP_UNIT = lockupUnitSeconds;
        _auth = IEmAuth(authAddress);
        _ref = IEmReferralPercents(refAddress);
    }

    event CommonLockupsUnlocked(uint256 amount, uint256 totalSupply);
    event LockupsUnlocked(address indexed holder, uint256 amount, uint256 balance);
    event LockupMinted(address indexed holder, uint256 indexed date, uint256 amount);
    event IncomeSent(address indexed spender, uint256 amount);
    event IncomeLocked(address indexed spender, uint256 amount);
    event RefIncomeSent(address indexed spender, address indexed refer, address indexed holder, uint256 amount);
    event RefIncomeLocked(address indexed spender, address indexed refer, address indexed holder, uint256 amount);
    event Spent(address indexed holder, address indexed caller, uint256 amount);
    event Refunded(address indexed holder, uint256 amount, uint256 refunded, bool blocked);
    event MinterLockupTimeSet(address indexed minter, uint256 time);
    event IncomeDistributorSet(address incomeAddress);

    /// @notice Unlocks ready common lockups and increases total supply
    function _unlockCommon() internal {
        uint256 unlocks;
        while (_commonLockupDate.length() > 0) {
            uint256 date = _commonLockupDate.first();
            if (date < block.timestamp) {
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

    /// @notice Unlocks ready lockups and increases holder balance;
    /// @param holder Lockups owner;
    /// @dev Does not unblock funds for blocked users;
    function _unlock(address holder) internal {
        if (_auth.isBlocked(holder)) return;
        uint256 unlocks;
        while (_lockupDate[holder].length() > 0) {
            uint256 date = _lockupDate[holder].first();
            if (date < block.timestamp) {
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
            _income.distributeFrom(incomeAddress, _balances[incomeAddress]);
        }
    }

    /// @notice Returns next lockup date based on block timestamp
    /// @param fromTimestamp Date when the lockup is minted
    /// @param lockupTime Amount of seconds for lockup period
    /// @return Rounded lockup date
    function _getLockupDate(uint256 fromTimestamp, uint256 lockupTime) internal view returns (uint256) {
        return fromTimestamp / LOCKUP_UNIT * LOCKUP_UNIT + lockupTime;
    }

    /// @notice Mint a new lockup or increase exists one
    /// @param holder Lockups owner
    /// @param amount Amount to mint
    function _mintLockup(address holder, uint256 amount, uint256 lockupTime) internal {
        require(lockupTime % LOCKUP_UNIT == 0, "lockupTime must be a multiple of LOCKUP_UNIT");
        /// Unlock previous ready lockups
        _unlockCommon();
        _unlock(holder);

        uint256 date = _getLockupDate(block.timestamp, lockupTime);
        if (_lockupDate[holder].length() == 0 || date > _lockupDate[holder].last()) {
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
    function _getLockupsBalance(address holder) internal view returns (uint256 amount) {
        for (uint256 i; i < _lockupDate[holder].length(); i++) {
            uint256 date = _lockupDate[holder].at(i);
            if (date < block.timestamp) {
                break;
            }
            amount += _lockupValue[holder][date];
        }
    }

    /// @notice Returns holder unlocked lockups sum
    /// @param holder Lockups owner
    /// @return amount Unlocked lockups sum
    function _getUnlockedLockupsBalance(address holder) internal view returns (uint256 amount) {
        if (_lockupDate[holder].length() == 0) {
            return 0;
        }
        for (uint256 i = _lockupDate[holder].length() - 1; i > 0; i--) {
            uint256 date = _lockupDate[holder].at(i);
            if (date >= block.timestamp) {
                break;
            }
            amount += _lockupValue[holder][date];
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

    /// @notice Distributes income with locked funds to referrals;
    /// @param holder Spender address;
    /// @param refs Pre-obtained structure of the referral system;
    /// @param locksDates Dates of locked funds
    /// @param locksValues Values of locked funds
    function _distributeLockedIncome(
        address holder,
        ReferralPercents[] memory refs,
        uint256[] memory locksDates,
        uint256[] memory locksValues
    ) internal {
        uint256 percentsLeft = PERCENT_PRECISION;
        /// Current step refer;
        address refer = holder;
        /// Loop for all available refers;
        uint r;
        while (r < refs.length) {
            /// Current parent; Stop if there is no parents left;
            address parent = refs[r].parentAddress;
            /// Stop loop is there is no referer or he is blocked
            if (parent == address(0) || _auth.isBlocked(parent)) {
                break;
            }
            /// Decrease total percents
            percentsLeft -= refs[r].percents;
            /// Merge parent lockup dates with income dates;
            _lockupDate[parent].fromArray(OrderedArrays.mergeAsc(
                locksDates,
                _lockupDate[parent].values()
            ));
            /// Add income to parent lockups;
            uint256 income;
            for (uint i; i < locksDates.length; i++) {
                uint256 dateIncome = locksValues[i] * refs[r].percents / PERCENT_PRECISION;
                _lockupValue[parent][locksDates[i]] += dateIncome;
                income += dateIncome;
            }
            emit RefIncomeLocked(holder, refer, parent, income);
            /// Next loop step;
            refer = parent;
            r++;
        }

        /// Merge income contract lockup dates with income dates;
        address incomeAddress = address(_income);
        _lockupDate[incomeAddress].fromArray(OrderedArrays.mergeAsc(
            locksDates,
            _lockupDate[incomeAddress].values()
        ));
        /// Add income to income contrac lockups;
        uint256 incomeLeft;
        for (uint i; i < locksDates.length; i++) {
            uint256 dateIncome = locksValues[i] * percentsLeft / PERCENT_PRECISION;
            _lockupValue[incomeAddress][locksDates[i]] += dateIncome;
            incomeLeft += dateIncome;
        }
        emit IncomeLocked(holder, incomeLeft);
    }

    /// @notice Distributes income to referrals;
    /// @param holder Spender address;
    /// @param refs Pre-obtained structure of the referral system;
    function _distributeIncome(address holder, uint256 amount, ReferralPercents[] memory refs) internal {
        uint amountLeft = amount;
        /// Current step refer;
        address refer = holder;
        /// Loop for all available refers;
        uint r;
        while (r < refs.length) {
            /// Current parent; Stop if there is no parents left;
            address parent = refs[r].parentAddress;
            /// Stop loop is there is no referer or he is blocked
            if (parent == address(0) || _auth.isBlocked(parent)) {
                break;
            }
            /// Decrease total percents
            amountLeft -= refs[r].percents;
            /// Transfer income;
            uint256 income = amount * refs[r].percents / PERCENT_PRECISION;
            _transfer(holder, parent, income);
            emit RefIncomeSent(holder, refer, parent, income);
            /// Next loop step;
            refer = parent;
            r++;
        }

        /// Send the rest to the income contract
        address incomeAddress = address(_income);
        _transfer(holder, incomeAddress, amountLeft);
        emit IncomeSent(holder, amountLeft);
        /// Distribute income to receivers
        _allowances[incomeAddress][incomeAddress] = _balances[incomeAddress];
        _income.distributeFrom(incomeAddress, _balances[incomeAddress]);
    }

    /// @notice Spend token amount by holder.
    /// @param holder Holder address;
    /// @param amount Token amount to spend;
    function _spend(address holder, uint256 amount) internal {
        /// Unlock previous ready lockups
        _unlockCommon();
        _unlock(holder);

        (
            uint256[] memory locksDates,
            uint256[] memory locksValues,
            uint256 amountLeft
        ) = _spendLockups(holder, amount);

        ReferralPercents[] memory refs = _ref.getReferralPercents(holder);
        _distributeLockedIncome(holder, refs, locksDates, locksValues);

        if (amountLeft > 0) {
            _distributeIncome(holder, amountLeft, refs);
        }
    }

    /// @notice Spend tokens from holder;
    /// @param holder Holder address;
    /// @param amount Token amount to spend;
    /// @dev Require SPENDER_ROLE
    function spend(address holder, uint256 amount) public onlyRole(SPENDER_ROLE) {
        require(!_auth.isBlocked(holder), "Account blocked");
        uint256 balance = _getLockupsBalance(holder) + _balances[holder];
        if (balance < amount) {
            revert ERC20InsufficientBalance(holder, balance, amount);
        }
        _spend(holder, amount);
        emit Spent(holder, _msgSender(), amount);
    }

    /// @notice Mint funds with time lockup;
    /// @param holder Holder address;
    /// @param amount Token amount to mint;
    /// @dev Require MINTER_ROLE
    function mintLockup(address holder, uint256 amount) public onlyRole(MINTER_ROLE) {
        uint256 lockupTime = minterLockupTime[_msgSender()] == 0
            ? DEFAULT_LOCKUP_TIME
            : minterLockupTime[_msgSender()];
        _mintLockup(holder, amount, lockupTime);
    }

    /// @notice Refund minted locked funds;
    /// @param holder Holder address;
    /// @param amount Token amount to refund;
    /// @param date Date of lockup
    /// @dev Require MINTER_ROLE
    function refundLockup(address holder, uint256 amount, uint256 date) public onlyRole(MINTER_ROLE) {
        /// Unlock previous ready lockups
        _unlockCommon();
        _unlock(holder);

        uint256 lockupsBalance = _getLockupsBalance(holder);

        if (_lockupValue[holder][date] >= amount) {
            /// If be able to refund a full amount from the one date
            _lockupValue[holder][date] -= amount;
            emit Refunded(holder, amount, amount, false);
        } else if (lockupsBalance + _balances[holder] >= amount) {
            /// If be able to refund a full amount
            (,,uint256 amountLeft) = _spendLockups(holder, amount);
            _balances[holder] -= amountLeft;
            /// Block user
            if (holder != address(_income)) {
                _auth.blockAccount(holder);
            }
            emit Refunded(holder, amount, amount, true);
        } else if (holder != address(_income)) {
            /// Partial refund
            uint256 refunded = lockupsBalance + _balances[holder];
            _spendLockups(holder, lockupsBalance);
            _balances[holder] = 0;
            /// Block user
            _auth.blockAccount(holder);
            emit Refunded(holder, amount, refunded, true);
        }
    }

    /// @notice Returns holder balance of unlocked funds;
    /// @param holder Holder address;
    /// @return Available balance
    function balanceOf(address holder) public view override returns (uint256) {
        return _balances[holder] + _getUnlockedLockupsBalance(holder);
    }

    /// @notice Returns holder locked balance available for payments only;
    /// @param holder Holder address;
    /// @return Locked balance for payments;
    function lockedOf(address holder) public view returns (uint256) {
        return _getLockupsBalance(holder);
    }

    /// @notice Returns array of holder lockups with information when the unlock will be available;
    /// @param holder Holder address;
    /// @return Array of holder lockups;
    function getLockups(address holder) public view returns (Lockup[] memory) {
        uint256 length = _lockupDate[holder].length();
        Lockup[] memory lockups = new Lockup[](length);
        for (uint256 i; i < length; i++) {
            lockups[i].untilTimestamp = _lockupDate[holder].at(i);
            if (lockups[i].untilTimestamp < block.timestamp) {
                break;
            }
            lockups[i].amount = _lockupValue[holder][lockups[i].untilTimestamp];
        }
        return lockups;
    }

    /// @notice Transfer current holder funds;
    /// @param to Recipient address;
    /// @param value Tokens to transfer;
    /// @return Transaction success
    function transfer(address to, uint256 value) public override returns (bool) {
        /// Unlock available lockups first
        _unlockCommon();
        _unlock(_msgSender());

        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    /// @notice Transfer holder funds;
    /// @param from Holder address;
    /// @param to Recipient address;
    /// @param value Tokens to transfer;
    /// @return Transaction success
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        address spender = _msgSender();

        /// Unlock available lockups first
        _unlockCommon();
        _unlock(spender);

        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

    /// @notice Unlock available holder lockups;
    /// @param holder Holder address;
    function unlockAvailable(address holder) public {
        _unlockCommon();
        if (holder == address(_income)) {
            _unlockIncome();
        } else {
            _unlock(holder);
        }
    }

    /// @notice Sets custom lockup time for specific minter
    /// @param minter Address with role MINTER_ROLE
    /// @param lockupTime Time in seconds for lockup period
    /// @dev Require role DEFAULT_ADMIN_ROLE
    function setMinterLockupTime(address minter, uint256 lockupTime) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(lockupTime % LOCKUP_UNIT == 0, "lockupTime must be a multiple of LOCKUP_UNIT");
        minterLockupTime[minter] = lockupTime;
        emit MinterLockupTimeSet(minter, lockupTime);
    }

    /// @notice Sets income distributor address
    /// @param incomeAddress Address of income distributor contract
    /// @dev Require role DEFAULT_ADMIN_ROLE
    function setIncomeDistributor(address incomeAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _income = IIncomeDistributor(incomeAddress);
        emit IncomeDistributorSet(incomeAddress);
    }




    /// Debug

    function DEVgetLockupDates(address holder) public view returns (uint256[] memory) {
        return _lockupDate[holder].values();
    }

    function DEVgetLockupValue(address holder, uint256 date) public view returns (uint256) {
        return _lockupValue[holder][date];
    }

    function DEVpush(address holder, uint256 date) public {
        _lockupDate[holder].push(date);
    }

}


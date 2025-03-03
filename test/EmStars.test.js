const {ethers} = require("hardhat");

// Helper function to create an array of test token IDs with given rarities

async function increaseTime(duration) {
  await ethers.provider.send("evm_increaseTime", [duration]);
  await ethers.provider.send("evm_mine", []);
}

const HOUR = 3600;
const DAY = HOUR * 24;

// const LOCKUP_TIME = 95 * DAY;
// const LOCKUP_UNIT = 5 * DAY;
const LOCKUP_TIME = 9 * DAY;
const LOCKUP_UNIT = 1 * DAY;

// Helper function to deploy and configure contracts
async function deployAndSetupContracts() {
  try {
    const list = {
      EmAuth: [],
      EmReferral: [],
      EmStars: [
        LOCKUP_TIME,
        LOCKUP_UNIT,
        'EmAuth',
        'EmReferral',
      ],
      IncomeDistributor: ['EmStars'],
    }
    const listKeys = Object.keys(list);
    const factory = {};
    const contract = {};
    const getValue = value => {
      return typeof value === 'string' && !!contract[value]
        ? contract[value].address
        : value;
    }
    await Promise.all(listKeys.map(async name => factory[name] = await ethers.getContractFactory(name)));
    for (let i = 0; i < listKeys.length; i++) {
      const name = listKeys[i];
      const args = list[name].map(value => getValue(value));
      // console.log('DEPLOY', name, args);
      contract[name] = await factory[name].deploy(...args);
    }
    
    await Promise.all(Object.keys(contract).map(name => contract[name].deployed()));
    
    // Update dependencies
    await contract.EmStars.setIncomeDistributor(contract.IncomeDistributor.address);
    await contract.EmAuth.grantRole(
      await contract.EmAuth.BLACKLIST_ROLE(),
      contract.EmStars.address,
    )
    
    return contract;
  } catch (error) {
    console.error('[deployAndSetupContracts]', error);
    throw error;
  }
}

const wei = {
  from: value => Number(ethers.utils.formatEther(value)),
  to: value => ethers.utils.parseEther(typeof value === 'number' ? value.toString() : value),
}

const processLockups = lockups => lockups.map(l => ({
  untilTimestamp: l.untilTimestamp.toNumber(),
  date: (new Date(l.untilTimestamp.toNumber() * 1000)).toGMTString(),
  amount: wei.from(l.amount),
}))

describe("EmStars Contract", function () {
  let owner, user, parent, grandpa;
  let contracts;
  
  beforeEach(async function () {
    [owner, user, parent, grandpa] = await ethers.getSigners();
    contracts = await deployAndSetupContracts();
  });
  
  const COUNT = 50;
  
  it(`should be right balance after mint ${COUNT} lockups`, async function () {
    const {expect} = await import("chai");
    
    const {
      EmAuth,
      EmReferral,
      EmStars,
      IncomeDistributor,
    } = contracts;
    
    let balance = 0;
    const AMOUNT_TO_MINT = 1;
    for (let i = 0; i < COUNT; i++) {
      await EmStars.mintLockup(user.address, wei.to(AMOUNT_TO_MINT));
      // console.log('DATES', (await EmStars.DEVgetLockupDates(user.address)).map(n => n.toNumber()));
      await increaseTime(DAY);
      balance += AMOUNT_TO_MINT;
    }
    
    const lockups = processLockups(await EmStars.getLockups(user.address));
    let lockupsSum = 0;
    lockups.map(l => lockupsSum += l.amount);
    // console.log('getLockups SUM', lockupsSum);
    const lockedOf = wei.from(await EmStars.lockedOf(user.address));
    const balanceOf = wei.from(await EmStars.balanceOf(user.address));
    // console.log('Lockups', lockups);
    // console.log('lockedOf', lockedOf);
    // console.log('balanceOf', balanceOf);
    // console.log('Total balance', balanceOf + lockedOf);
    
    expect(balanceOf + lockedOf).to.equal(balance);
  });
  
  it(`should spend with right income`, async function () {
    const {expect} = await import("chai");
    
    const {
      EmAuth,
      EmReferral,
      EmStars,
      IncomeDistributor,
    } = contracts;
    
    let balance = 0;
    const AMOUNT_TO_MINT = 1;
    for (let i = 0; i < COUNT; i++) {
      await EmStars.mintLockup(user.address, wei.to(AMOUNT_TO_MINT));
      await increaseTime(DAY);
      balance += AMOUNT_TO_MINT;
    }
    
    // console.log('DATES USER', (await EmStars.DEVgetLockupDates(user.address)).map(n => n.toNumber()));
    
    const AMOUNT_TO_SPEND = 10;
    await EmStars.connect(user).approve(owner.address, wei.to(AMOUNT_TO_SPEND));
    await EmStars.spend(user.address, wei.to(AMOUNT_TO_SPEND));
    await increaseTime(50 * DAY);
    await EmStars.unlockAvailable(IncomeDistributor.address);
    const incomeLocked = wei.from(await EmStars.lockedOf(IncomeDistributor.address));
    const incomeBalance = wei.from(await EmStars.balanceOf(IncomeDistributor.address));
    const incomeReceived = wei.from(await EmStars.balanceOf(owner.address));
    const lockedLeft = wei.from(await EmStars.lockedOf(user.address));
    const balanceLeft = wei.from(await EmStars.balanceOf(user.address));
    
    // console.log('SPEND', {
    //   incomeLocked,
    //   incomeBalance,
    //   incomeReceived,
    //   lockedLeft,
    //   balanceLeft,
    // });
    
    // console.log('DATES USER', (await EmStars.DEVgetLockupDates(user.address)).map(n => n.toNumber()));
    // console.log('DATES INCOME', (await EmStars.DEVgetLockupDates(IncomeDistributor.address)).map(n => n.toNumber()));
    
    expect(incomeLocked + incomeBalance + incomeReceived).to.equal(AMOUNT_TO_SPEND);
    expect(lockedLeft + balanceLeft).to.equal(balance - AMOUNT_TO_SPEND);
  });
  
  it(`should distribute to referral tree`, async function () {
    const {expect} = await import("chai");
    
    const {
      EmAuth,
      EmReferral,
      EmStars,
      IncomeDistributor,
    } = contracts;
    
    let balance = 0;
    const AMOUNT_TO_MINT = 1;
    for (let i = 0; i < COUNT; i++) {
      await EmStars.mintLockup(user.address, wei.to(AMOUNT_TO_MINT));
      await increaseTime(DAY);
      balance += AMOUNT_TO_MINT;
    }
    
    await EmReferral.addRelation(grandpa.address, parent.address);
    await EmReferral.addRelation(parent.address, user.address);
    
    const AMOUNT_TO_SPEND = 10;
    await EmStars.connect(user).approve(owner.address, wei.to(AMOUNT_TO_SPEND));
    await EmStars.spend(user.address, wei.to(AMOUNT_TO_SPEND));
    
    const incomeLocked = wei.from(await EmStars.lockedOf(IncomeDistributor.address));
    const incomeBalance = wei.from(await EmStars.balanceOf(IncomeDistributor.address));
    const incomeReceived = wei.from(await EmStars.balanceOf(owner.address));
    const lockedLeft = wei.from(await EmStars.lockedOf(user.address));
    const balanceLeft = wei.from(await EmStars.balanceOf(user.address));
    
    const parentLocked = wei.from(await EmStars.lockedOf(parent.address));
    const parentBalance = wei.from(await EmStars.balanceOf(parent.address));
    
    const grandpaLocked = wei.from(await EmStars.lockedOf(grandpa.address));
    const grandpaBalance = wei.from(await EmStars.balanceOf(grandpa.address));
    
    // console.log('SPEND', {
    //   incomeLocked,
    //   incomeBalance,
    //   incomeReceived,
    //   lockedLeft,
    //   balanceLeft,
    //   parentLocked,
    //   parentBalance,
    //   grandpaLocked,
    //   grandpaBalance,
    // });
    
    // console.log('DATES USER', (await EmStars.DEVgetLockupDates(user.address)).map(n => n.toNumber()));
    // console.log('DATES INCOME', (await EmStars.DEVgetLockupDates(IncomeDistributor.address)).map(n => n.toNumber()));
    
    expect(incomeLocked + incomeBalance + incomeReceived).to.above(0);
    expect(parentLocked + parentBalance).to.above(0);
    expect(grandpaLocked + grandpaBalance).to.above(0);
    expect(lockedLeft + balanceLeft).to.equal(balance - AMOUNT_TO_SPEND);
  });
  
  it(`should be right totalSupply`, async function () {
    const {expect} = await import("chai");
    
    const {
      EmAuth,
      EmReferral,
      EmStars,
      IncomeDistributor,
    } = contracts;
    
    let balance = 0;
    const AMOUNT_TO_MINT = 5;
    const mint = async account => {
      await EmStars.mintLockup(account.address, wei.to(AMOUNT_TO_MINT));
      balance += AMOUNT_TO_MINT;
    }
    await mint(parent);
    await increaseTime(LOCKUP_UNIT);
    await increaseTime(LOCKUP_UNIT);
    await mint(user);
    await mint(parent);
    await increaseTime(LOCKUP_UNIT);
    await mint(user);
    await increaseTime(LOCKUP_UNIT);
    await mint(user);
    await mint(parent);
    
    const before = {
      parent: {
        locked: wei.from(await EmStars.lockedOf(parent.address)),
        balance: wei.from(await EmStars.balanceOf(parent.address)),
      },
      user: {
        locked: wei.from(await EmStars.lockedOf(user.address)),
        balance: wei.from(await EmStars.balanceOf(user.address)),
      },
      total: {
        locked: wei.from(await EmStars.lockedSupply()),
        balance: wei.from(await EmStars.totalSupply()),
      },
    }
    await increaseTime(LOCKUP_TIME - LOCKUP_UNIT);
    await EmStars.unlockAvailable(user.address);
    const after = {
      parent: {
        locked: wei.from(await EmStars.lockedOf(parent.address)),
        balance: wei.from(await EmStars.balanceOf(parent.address)),
      },
      user: {
        locked: wei.from(await EmStars.lockedOf(user.address)),
        balance: wei.from(await EmStars.balanceOf(user.address)),
      },
      total: {
        locked: wei.from(await EmStars.lockedSupply()),
        balance: wei.from(await EmStars.totalSupply()),
      },
    }
    
    // console.log('BEFORE', before);
    // console.log('AFTER', after);
    
    expect(before.user.balance + before.user.locked).to.equal(balance / 2);
    expect(before.parent.balance + before.parent.locked).to.equal(balance / 2);
    expect(before.total.balance + before.total.locked).to.equal(balance);
    expect(after.user.balance + after.user.locked).to.equal(balance / 2);
    expect(after.parent.balance + after.parent.locked).to.equal(balance / 2);
    expect(after.total.balance + after.total.locked).to.equal(balance);
  });
  
  it(`should be able to refund and block account`, async function () {
    const {expect} = await import("chai");
    
    const {
      EmAuth,
      EmReferral,
      EmStars,
      IncomeDistributor,
    } = contracts;
    
    let balance = 0;
    const AMOUNT_TO_MINT = 10;
    const mint = async account => {
      await EmStars.mintLockup(account.address, wei.to(AMOUNT_TO_MINT));
      balance += AMOUNT_TO_MINT;
    }
    await mint(user);
    await increaseTime(LOCKUP_UNIT);
    await mint(user);
    
    const lockups = processLockups(await EmStars.getLockups(user.address));
    // console.log('LOCKUPS', lockups);
    
    const before = {
      user: {
        locked: wei.from(await EmStars.lockedOf(user.address)),
        balance: wei.from(await EmStars.balanceOf(user.address)),
      },
      total: {
        locked: wei.from(await EmStars.lockedSupply()),
        balance: wei.from(await EmStars.totalSupply()),
      },
    }
    
    await EmStars.refundLockup(user.address, wei.to(AMOUNT_TO_MINT / 2), lockups[0].untilTimestamp);
    await EmStars.refundLockup(user.address, wei.to(AMOUNT_TO_MINT / 2), lockups[0].untilTimestamp);
    await EmStars.refundLockup(user.address, wei.to(AMOUNT_TO_MINT / 2), lockups[0].untilTimestamp);
    await EmStars.refundLockup(user.address, wei.to(AMOUNT_TO_MINT / 2), lockups[0].untilTimestamp);
    
    const after = {
      user: {
        locked: wei.from(await EmStars.lockedOf(user.address)),
        balance: wei.from(await EmStars.balanceOf(user.address)),
      },
      total: {
        locked: wei.from(await EmStars.lockedSupply()),
        balance: wei.from(await EmStars.totalSupply()),
      },
    }
    
    await EmStars.refundLockup(user.address, wei.to(AMOUNT_TO_MINT / 2), lockups[0].untilTimestamp);
    
    // console.log('BEFORE', before);
    // console.log('AFTER', after);
    // console.log('AUTHS', await EmAuth.getAuths(user.address));
    // console.log('IS BLOCKED', await EmAuth.isBlocked(user.address));
    expect(after.user.balance + after.user.locked).to.equal(0);
    expect(await EmAuth.isBlocked(user.address)).to.equal(true);
  });
});

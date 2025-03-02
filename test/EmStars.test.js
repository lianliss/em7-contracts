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
const LOCKUP_TIME = 15 * DAY;
const LOCKUP_UNIT = 5 * DAY;

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
    console.log('getLockups SUM', lockupsSum);
    const lockedOf = wei.from(await EmStars.lockedOf(user.address));
    const balanceOf = wei.from(await EmStars.balanceOf(user.address));
    // console.log('Lockups', lockups);
    console.log('lockedOf', lockedOf);
    console.log('balanceOf', balanceOf);
    console.log('Total balance', balanceOf + lockedOf);
    
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
    await EmStars.spend(user.address, wei.to(AMOUNT_TO_SPEND));
    await increaseTime(50 * DAY);
    console.log('IncomeDistributor', IncomeDistributor.address);
    await EmStars.unlockAvailable(IncomeDistributor.address);
    const incomeLocked = wei.from(await EmStars.lockedOf(IncomeDistributor.address));
    const incomeBalance = wei.from(await EmStars.balanceOf(IncomeDistributor.address));
    const incomeReceived = wei.from(await EmStars.balanceOf(owner.address));
    const lockedLeft = wei.from(await EmStars.lockedOf(user.address));
    const balanceLeft = wei.from(await EmStars.balanceOf(user.address));
    
    console.log('SPEND', {
      incomeLocked,
      incomeBalance,
      incomeReceived,
      lockedLeft,
      balanceLeft,
    });
    
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
    
    console.log('SPEND', {
      incomeLocked,
      incomeBalance,
      incomeReceived,
      lockedLeft,
      balanceLeft,
      parentLocked,
      parentBalance,
      grandpaLocked,
      grandpaBalance,
    });
    
    // console.log('DATES USER', (await EmStars.DEVgetLockupDates(user.address)).map(n => n.toNumber()));
    // console.log('DATES INCOME', (await EmStars.DEVgetLockupDates(IncomeDistributor.address)).map(n => n.toNumber()));
    
    expect(incomeLocked + incomeBalance + incomeReceived).to.above(0);
    expect(parentLocked + parentBalance).to.above(0);
    expect(grandpaLocked + grandpaBalance).to.above(0);
    expect(lockedLeft + balanceLeft).to.equal(balance - AMOUNT_TO_SPEND);
  });
});

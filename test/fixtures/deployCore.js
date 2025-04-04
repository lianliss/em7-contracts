const {ethers} = require("hardhat");
const {
  LOCKUP_TIME,
  LOCKUP_UNIT,
  HOUR,
  DAY,
} = require("./const");

async function deployCore() {
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
      Balances: [],
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
    console.error('[deployCore]', error);
    throw error;
  }
}

module.exports = deployCore;


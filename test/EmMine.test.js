const deployAndSetupContracts = require("./fixtures/deployGame.js");
const {
  LOCKUP_TIME,
  LOCKUP_UNIT,
  HOUR,
  DAY,
} = require("./fixtures/const");
const {
  increaseTime,
  wei,
} = require("./fixtures/utils");
const {ethers} = require("hardhat");

describe("EmMine Contract", function () {
  let owner, user, parent, grandpa;
  let contracts;
  
  beforeEach(async function () {
    [owner, user, parent, grandpa] = await ethers.getSigners();
    contracts = await deployAndSetupContracts();
  });
  
  it(`should produce oil`, async function () {
    const {expect} = await import("chai");
    const {IncomeDistributor, EmAuth, EmReferral, EmStars, EmResFactory, EmEquipment, EmLevel, EmSlots, EmTech, EmMap, EmBuilding, EmBuildingEditor, EmMine, EmPlant, EmPlantExtra,Balances,} = contracts;
    
    await EmResFactory.createResource('Oil', 'EmOIL');
    const oil = await EmResFactory.at(2);
    await EmBuildingEditor.addType(
      'Oil pump',
      EmMine.address,
      0,
      10,
      0,
      2,
    );
    
    await EmMine.setTypeParams(0, oil.resource, {
      base: 1,
      geometric: 1,
      step: 1,
    },{
      base: 60,
      geometric: 1,
      step: 30,
    },)
    
    await EmMap.connect(user).claimArea(0,0);
    await EmBuilding.connect(user).build(0, 0, 0);
    // await EmBuilding.connect(user).upgrade(1);
    // await EmBuilding.connect(user).upgrade(1);
    // await EmBuilding.connect(user).upgrade(1);
    
    await increaseTime(4);
    
    const mine = await EmMine.getMine(user.address, 1);
    // console.log('MINE', mine);
    await EmMine.connect(user).claim(1);
    const balances = await Balances.getBalances(user.address, [oil.resource]);
    // console.log('BALANCES', balances);
    
    expect(oil.symbol).to.equal('EmOIL');
    expect(mine.volume.toNumber()).to.equal(60);
    expect(balances[0].toNumber()).to.equal(5);
  });
});

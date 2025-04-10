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

describe("EmPlant Contract", function () {
  let owner, user, parent, grandpa;
  let contracts;
  
  beforeEach(async function () {
    [owner, user, parent, grandpa] = await ethers.getSigners();
    contracts = await deployAndSetupContracts();
  });
  
  it(`should produce diesel and spend oil`, async function () {
    const {expect} = await import("chai");
    const {IncomeDistributor, EmAuth, EmReferral, EmStars, EmResFactory, EmEquipment, EmLevel, EmSlots, EmTech, EmMap, EmBuilding, EmBuildingEditor, EmMine, EmPlant, EmPlantExtra,Balances,} = contracts;
    
    await EmResFactory.createResource('Oil', 'EmOIL');
    await EmResFactory.createResource('Diesel', 'EmDSL');
    const oil = await EmResFactory.at(2);
    const diesel = await EmResFactory.at(3);
    await EmBuildingEditor.addType(
      'Oil pump',
      EmMine.address,
      0,
      10,
      0,
      1,
    );
    await EmBuildingEditor.addType(
      'Distillator',
      EmPlant.address,
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
    },{
      base: 1,
      geometric: 1,
      step: 0,
    })
    await EmPlantExtra.addRecipe(1, [{
      resource: oil.resource,
      amount: {
        base: 1,
        geometric: 1,
        step: 1,
      }
    }], [{
      resource: diesel.resource,
      amount: {
        base: 1,
        geometric: 1,
        step: 1,
      }
    }], [{
      base: 60,
      geometric: 1,
      step: 30,
    }],)
    
    await EmMap.connect(user).claimArea(0,0);
    await EmBuilding.connect(user).build(0, 0, 0);
    await EmBuilding.connect(user).build(1, 0, 1);
    
    await increaseTime(4);
    
    const mine = await EmMine.getMine(user.address, 1);
    // console.log('MINE', mine);
    let plant = await EmPlant.getPlant(user.address, 2);
    // console.log('PLANT', plant);
    await EmMine.connect(user).claim(1);
    await EmPlant.connect(user).claim(2);
    let balances = await Balances.getBalances(user.address, [oil.resource, diesel.resource]);
    // console.log('BALANCES', balances);
    
    // Fill the plant
    await EmPlantExtra.connect(user).fillIngredients(2, [6]);
    await increaseTime(4);
    // Claim the plant
    // await EmMine.connect(user).claim(1);
    await EmPlant.connect(user).claim(2);
    balances = await Balances.getBalances(user.address, [oil.resource, diesel.resource]);
    // console.log('BALANCES', balances);
    plant = await EmPlant.getPlant(user.address, 2);
    // console.log('PLANT', plant);
    
    expect(balances[1].toNumber()).to.equal(5);
    expect(plant.ingredients[0].toNumber()).to.equal(1);
  });
  
  it(`should produce diesel through the pipe`, async function () {
    const {expect} = await import("chai");
    const {IncomeDistributor, EmAuth, EmReferral, EmStars, EmResFactory, EmEquipment, EmLevel, EmSlots, EmTech, EmMap, EmBuilding, EmBuildingEditor, EmMine, EmPlant, EmPlantExtra,Balances,} = contracts;
    
    await EmResFactory.createResource('Oil', 'EmOIL');
    await EmResFactory.createResource('Diesel', 'EmDSL');
    const oil = await EmResFactory.at(2);
    const diesel = await EmResFactory.at(3);
    await EmBuildingEditor.addType(
      'Oil pump',
      EmMine.address,
      0,
      10,
      0,
      1,
    );
    await EmBuildingEditor.addType(
      'Distillator',
      EmPlant.address,
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
    },{
      base: 1,
      geometric: 1,
      step: 0,
    })
    await EmPlantExtra.addRecipe(1, [{
      resource: oil.resource,
      amount: {
        base: 1,
        geometric: 1,
        step: 1,
      }
    }], [{
      resource: diesel.resource,
      amount: {
        base: 1,
        geometric: 1,
        step: 1,
      }
    }], [{
      base: 60,
      geometric: 1,
      step: 30,
    }],)
    
    await EmMap.connect(user).claimArea(0,0);
    await EmBuilding.connect(user).build(0, 0, 0);
    await EmBuilding.connect(user).build(1, 0, 1);
    
    let plant = await EmPlant.getPlant(user.address, 2);
    // console.log('PLANT', plant);
    
    // console.log('Mine address', EmMine.address);
    // console.log('Plant address', EmPlant.address);
    // Fill the plant
    await EmPlant.connect(user).connectSource(2, 0, 1, 0);
    await increaseTime(10);
    // Claim the plant
    // await EmMine.connect(user).claim(1);
    const claim = await EmPlant.connect(user).claim(2);
    // console.log('CLAIM', await claim.wait());
    let balances = await Balances.getBalances(user.address, [oil.resource, diesel.resource]);
    // console.log('BALANCES', balances);
    // plant = await EmPlant.getPlant(user.address, 2);
    // console.log('PLANT', plant);
    
    expect(balances[1].toNumber()).to.equal(12);
  });
});

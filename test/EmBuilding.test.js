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

describe("EmBuilding Contract", function () {
  let owner, user, parent, grandpa;
  let contracts;
  
  beforeEach(async function () {
    [owner, user, parent, grandpa] = await ethers.getSigners();
    contracts = await deployAndSetupContracts();
  });
  
  it(`should create building type`, async function () {
    const {expect} = await import("chai");
    const {IncomeDistributor, EmAuth, EmReferral, EmStars, EmResFactory, EmEquipment, EmLevel, EmSlots, EmTech, EmMap, EmBuilding, EmBuildingEditor, EmMine, EmPlant, EmPlantExtra,} = contracts;
    
    await EmMap.connect(user).claimArea(0,0);
    
    // console.log(owner.address, 'owner');
    // Object.keys(contracts).map(name => console.log(contracts[name].address, name));
    await EmBuildingEditor.addType(
      'Oil pump',
      EmMine.address,
      0,
      10,
      0,
      1,
    )
    await EmBuildingEditor.setBuildingRequirements(0, [
      [],
      {
        base: 0,
        geometric: 0,
        step: 0,
      },
      []
    ]);
    const types = await EmBuilding.getTypes(0, 100);
    // console.log('TYPES', types);
    
    expect(types[0].length).to.equal(1);
    expect(types[0][0].functionality).to.equal(EmMine.address);
  });
  
  it(`should build and upgrade`, async function () {
    const {expect} = await import("chai");
    const {IncomeDistributor, EmAuth, EmReferral, EmStars, EmResFactory, EmEquipment, EmLevel, EmSlots, EmTech, EmMap, EmBuilding, EmBuildingEditor, EmMine, EmPlant, EmPlantExtra,} = contracts;
    
    await EmMap.connect(user).claimArea(0,0);
    await EmBuildingEditor.addType(
      'Oil pump',
      EmMine.address,
      0,
      10,
      0,
      2,
    );
    await EmBuilding.connect(user).build(0, 0, 0);
    await EmBuilding.connect(user).upgrade(1);
    await EmBuilding.connect(user).upgrade(1);
    // await EmBuilding.connect(user).build(0, 1, 1);
    const tile = await EmMap.getTileObject(user.address, 1, 1);
    const building = await EmBuilding.getBuilding(user.address, 1);
    // console.log('BUILDING', building);
    // console.log('TILE', tile, tile.buildingIndex.toNumber());
    // await EmBuilding.connect(user).build(0, 1, 1);
    // const buildings = await EmBuilding.getBuildings(user.address, 0, 100);
    // console.log('buildings', buildings);
    
    expect(tile.buildingIndex.toNumber()).to.equal(1);
    expect(building.level.toNumber()).to.equal(2);
  });
  
  it(`should demolish`, async function () {
    const {expect} = await import("chai");
    const {IncomeDistributor, EmAuth, EmReferral, EmStars, EmResFactory, EmEquipment, EmLevel, EmSlots, EmTech, EmMap, EmBuilding, EmBuildingEditor, EmMine, EmPlant, EmPlantExtra,} = contracts;
    
    await EmMap.connect(user).claimArea(0,0);
    await EmBuildingEditor.addType(
      'Oil pump',
      EmMine.address,
      0,
      10,
      0,
      2,
    );
    await EmBuilding.connect(user).build(0, 0, 0);
    await EmBuilding.connect(user).remove(1);
    const tile = await EmMap.getTileObject(user.address, 1, 1);
    const building = await EmBuilding.getBuilding(user.address, 1);
    // console.log('BUILDING', building);
    // console.log('TILE', tile, tile.buildingIndex.toNumber());
    // await EmBuilding.connect(user).build(0, 1, 1);
    // const buildings = await EmBuilding.getBuildings(user.address, 0, 100);
    // console.log('buildings', buildings);
    
    expect(tile.buildingIndex.toNumber()).to.equal(0);
    expect(building.level.toNumber()).to.equal(0);
  });
});

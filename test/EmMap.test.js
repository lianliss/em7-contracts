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

describe("EmMap Contract", function () {
  let owner, user, parent, grandpa;
  let contracts;
  
  beforeEach(async function () {
    [owner, user, parent, grandpa] = await ethers.getSigners();
    contracts = await deployAndSetupContracts();
  });
  
  it(`should claim areas`, async function () {
    const {expect} = await import("chai");
    const {IncomeDistributor, EmAuth, EmReferral, EmStars, EmResFactory, EmEquipment, EmLevel, EmSlots, EmTech, EmMap, EmBuilding, EmBuildingEditor, EmMine, EmPlant, EmPlantExtra,} = contracts;
    
    await EmMap.connect(user).claimArea(0,0);
    await EmMap.connect(user).claimArea(4,0);
    const areas = await EmMap.getClaimedAreas(user.address, 0, 100);
    
    expect(areas[0].length).to.equal(2);
  });
});

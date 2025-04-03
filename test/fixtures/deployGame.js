const {ethers} = require("hardhat");
const {
  LOCKUP_TIME,
  LOCKUP_UNIT,
  HOUR,
  DAY,
} = require("./const");
const deployCore = require("./deployCore");

async function deployGame() {
  try {
    const core = await deployCore();
    const auth = core.EmAuth.address;
    const list = {
      EmResFactory: [auth],
      EmResource: [
        'Resource Verification',
        'RV',
        auth,
      ],
      EmEquipment: [],
      EmLevel: [auth],
      EmSlots: ['EmLevel'],
      EmTech: ['EmResFactory', 'EmSlots'],
      EmMap: [
        core.EmStars.address,
        'EmResFactory',
      ],
      EmBuilding: [
        'EmTech',
        'EmMap',
        'EmSlots',
      ],
      EmBuildingEditor: ['EmBuilding'],
      EmMine: ['EmBuilding', 'EmTech'],
      EmPlant: ['EmBuilding', 'EmTech'],
      EmPlantExtra: ['EmPlant'],
    }
    const listKeys = Object.keys(list);
    const factory = {};
    const contract = {
      ...core,
    };
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
    
    // Resources
    await contract.EmResFactory.createResource('EmMoney', 'EmMNY');
    await contract.EmResFactory.createResource('EmScience', 'EmSCI');
    
    // Plant
    await contract.EmResFactory.addToWhitelist(
      contract.EmPlant.address,
    )
    await contract.EmResFactory.grantRole(
      await contract.EmResFactory.MINTER_ROLE(),
      contract.EmPlant.address,
    )
    await contract.EmMine.grantRole(
      await contract.EmMine.CONSUMER_ROLE(),
      contract.EmPlant.address,
    )
    await contract.EmPlant.grantRole(
      await contract.EmPlant.PROXY_ROLE(),
      contract.EmPlantExtra.address,
    )
    
    // Mine
    await contract.EmResFactory.grantRole(
      await contract.EmResFactory.MINTER_ROLE(),
      contract.EmMine.address,
    )
    
    // Building
    await contract.EmMap.grantRole(
      await contract.EmMap.BUILDER_ROLE(),
      contract.EmBuilding.address,
    )
    await contract.EmEquipment.grantRole(
      await contract.EmEquipment.MOD_ROLE(),
      contract.EmBuilding.address,
    )
    await contract.EmResFactory.grantRole(
      await contract.EmResFactory.MINTER_ROLE(),
      contract.EmBuilding.address,
    )
    await contract.EmResFactory.grantRole(
      await contract.EmResFactory.BURNER_ROLE(),
      contract.EmBuilding.address,
    )
    await contract.EmMine.grantRole(
      await contract.EmMine.CLAIMER_ROLE(),
      contract.EmBuilding.address,
    )
    await contract.EmPlant.grantRole(
      await contract.EmPlant.CLAIMER_ROLE(),
      contract.EmBuilding.address,
    )
    await contract.EmBuilding.grantRole(
      await contract.EmBuilding.PROXY_ROLE(),
      contract.EmBuildingEditor.address,
    )
    
    // Map
    await contract.EmStars.grantRole(
      await contract.EmStars.SPENDER_ROLE(),
      contract.EmMap.address,
    )
    await contract.EmResFactory.grantRole(
      await contract.EmResFactory.BURNER_ROLE(),
      contract.EmMap.address,
    )
    
    // Tech
    await contract.EmResFactory.grantRole(
      await contract.EmResFactory.BURNER_ROLE(),
      contract.EmTech.address,
    )
    
    return contract;
  } catch (error) {
    console.error('[deployGame]', error);
    throw error;
  }
}

module.exports = deployGame;


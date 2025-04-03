const {ethers} = require("hardhat");

async function increaseTime(duration) {
  await ethers.provider.send("evm_increaseTime", [duration]);
  await ethers.provider.send("evm_mine", []);
}

const wei = {
  from: value => Number(ethers.utils.formatEther(value)),
  to: value => ethers.utils.parseEther(typeof value === 'number' ? value.toString() : value),
}

module.exports = {
  increaseTime,
  wei,
}
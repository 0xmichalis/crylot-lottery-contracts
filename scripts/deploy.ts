import { ethers } from "hardhat";

const BASE_SEPOLIA_SETTINGS = {
  keyHash: "0x9e1344a1247c8a1785d0a4681a27152bffdb43666ae5bf7d14d24a5efd44bf71",
  vrfCoordinator: "0x5C210eF41CD1a72de73bF76eC39637bB0d3d7BEE",
  subscriptionId: 3330
};

const BASE_SETTINGS = {
  keyHash: "0x00b81b5a830cb0a4009fbd8904de511e28631e62ce5ad231373d3cdad373ccab",
  vrfCoordinator: "0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634",
  subscriptionId: 3330
};

export async function deployContract() {
  const prod = false;
  const settings = prod ? BASE_SETTINGS : BASE_SEPOLIA_SETTINGS
  const { keyHash, vrfCoordinator, subscriptionId } = settings

  const Crylot = await ethers.getContractFactory("Crylot");
  const lock = await Crylot.deploy(keyHash, vrfCoordinator, subscriptionId);

  console.log("Contract deployed to: " + lock.address)
  return lock.deployed();
}

async function main() {
  await deployContract();
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
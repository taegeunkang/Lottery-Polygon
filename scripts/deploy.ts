// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";

async function main() {
  console.log("VRFv2Consumer deploying...");
  const VRFv2Consumer = await ethers.getContractFactory("VRFv2Consumer");
  const Consumer = await VRFv2Consumer.deploy(283);
  await Consumer.deployed();

  console.log("Lottery deploying...");
  const Lottery = await ethers.getContractFactory("Lottery");
  const lottery = await Lottery.deploy(Consumer.address);
  await lottery.deployed();

  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

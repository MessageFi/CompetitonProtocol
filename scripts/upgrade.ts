import { ethers, upgrades } from "hardhat";

async function main() {
    // const a = await ethers.getContractFactory("a");

    // const upgraded = await upgrades.upgradeProxy('address', a);
    // console.log("a upgrade to:", await upgraded.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
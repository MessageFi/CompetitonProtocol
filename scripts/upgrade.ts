import { ethers, upgrades } from "hardhat";

async function main() {
    const BeaverCommunity = await ethers.getContractFactory("BeaverCommunity");

    const upgraded = await upgrades.upgradeProxy('0xd7c5c162F851C20b5Dd9dAb4186d3F59d598DBFE', BeaverCommunity);
    console.log("BeaverCommunity upgrade to:", await upgraded.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
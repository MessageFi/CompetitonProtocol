import { ethers, upgrades } from "hardhat";

async function main() {
  const Ticket20 = await ethers.getContractFactory("Ticket20");
  const tc = await Ticket20.deploy();
  await tc.waitForDeployment();
  console.log("Ticket20 deployed to:", await tc.getAddress());

  const Reward20 = await ethers.getContractFactory("Reward20");
  const rc = await Reward20.deploy();
  await rc.waitForDeployment();
  console.log("Reward20 deployed to:", await rc.getAddress());


  const CompetitionProtocol = await ethers.getContractFactory("DefaultCompetition");
  const cp = await upgrades.deployProxy(CompetitionProtocol, []);
  console.log("CompetitionProtocol deployed to:", await cp.getAddress());

  const cpAddress: string = await cp.getAddress();
  const OnchainHackson = await ethers.getContractFactory("OnchainHackson");
  const hackson = await OnchainHackson.deploy(cpAddress);
  await hackson.waitForDeployment();
  console.log("OnchainHackson deployed to:", await hackson.getAddress());

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

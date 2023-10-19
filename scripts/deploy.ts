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


  const CompetitionProtocol = await ethers.getContractFactory("CompetitionProtocol");
  const cp = await upgrades.deployProxy(CompetitionProtocol, []);
  console.log("CompetitionProtocol deployed to:", await cp.getAddress());

  const tcAddress: string = await tc.getAddress();
  const rcAddress: string = await rc.getAddress();
  await cp.setWhiteCoin(tcAddress, true);
  await cp.setWhiteCoin(rcAddress, true);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

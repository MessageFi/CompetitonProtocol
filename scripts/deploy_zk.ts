import { ethers, upgrades } from "hardhat";
import { time } from "@nomicfoundation/hardhat-toolbox/network-helpers";

async function main() {
  const SecretBallot = await ethers.getContractFactory("SecretBallot");
  const endTime = await time.latest() + 86400;

  const addresses: string[] = [
    "0x0000000741A0c7E57008D7d879c332619fB19160",
    "0x74e38875b72dcCEF3737e89348b056C2896F16d4",
    "0x08bc863803945b9eae7b96ba424c8d8ecf774c98",
    "0xf97cd972df2ada54d7e65ba19f7e2856853cb714"
  ];

  const zkBallot = await SecretBallot.deploy(addresses, [1, 9], 0, endTime);
  await zkBallot.waitForDeployment();
  console.log("SecretBallot deployed to:", await zkBallot.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

import { ethers, upgrades } from "hardhat";

async function main() {
  const WoodERC20 = await ethers.getContractFactory("WoodERC20");
  const wood = await WoodERC20.deploy("Wood Coin", "Wood");
  await wood.waitForDeployment();
  console.log("WoodERC20 deployed to:", await wood.getAddress());

  const LodgeERC721 = await ethers.getContractFactory("LodgeERC721");
  const lodge = await upgrades.deployProxy(LodgeERC721, ["Lodge", "Lodge"]);
  console.log("LodgeERC721 deployed to:", await lodge.getAddress());

  const BeaverCommunity = await ethers.getContractFactory("BeaverCommunity");
  const lodgeAddress: string = await lodge.getAddress();
  const woodAddress: string = await wood.getAddress();
  const community = await upgrades.deployProxy(BeaverCommunity, [lodgeAddress, woodAddress, 120]);
  console.log("BeaverCommunity deployed to:", await community.getAddress());

  const COMMUNITY_ROLE = await lodge.COMMUNITY_ROLE();
  await lodge.grantRole(COMMUNITY_ROLE, community.getAddress());

  await wood.mint(community.getAddress());

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

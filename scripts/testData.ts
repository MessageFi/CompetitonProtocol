import { ethers, upgrades,network } from "hardhat";
import { Contract } from "ethers";

//WoodERC20 deployed to: 0xC5eDef1d10F663674d35C067bA7F8806DeB2BF48
// LodgeERC721 deployed to: 0xCcA85635C7E0a67a5EdA943e0BD02ee0d108a0dE
// BeaverCommunity deployed to: 0x9A835ED238356Cf3BE47910bF19C3953D1BB81CF

async function main() {

    const [owner, otherAccount] = await ethers.getSigners();

    const community = await ethers.getContractAt("BeaverCommunity", "0x9A835ED238356Cf3BE47910bF19C3953D1BB81CF");
    const wood = await ethers.getContractAt("WoodERC20", "0xC5eDef1d10F663674d35C067bA7F8806DeB2BF48");
    // await community.build(false, '<p>山外青山楼外楼，西湖歌舞几时休？</p><p>暖风熏得游人醉，直把杭州作汴州。</p>');
    // await wood.approve("0xC5eDef1d10F663674d35C067bA7F8806DeB2BF48", 1e9);
    // console.log(await wood.allowance(owner, "0xC5eDef1d10F663674d35C067bA7F8806DeB2BF48"))
    await community.withdrawRoyalties(2);
    await community.withdrawRewards(2);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
  });
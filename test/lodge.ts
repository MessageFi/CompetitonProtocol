import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades,network } from "hardhat";
import { Contract } from "ethers";

describe("Lodge", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployLodgeFixture() {
    
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
        const community = await upgrades.deployProxy(BeaverCommunity, [lodgeAddress, woodAddress, 2]);
        console.log("BeaverCommunity deployed to:", await community.getAddress());

        const COMMUNITY_ROLE = await lodge.COMMUNITY_ROLE();
        await lodge.grantRole(COMMUNITY_ROLE, community.getAddress());

        await wood.mint(community.getAddress());
    
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
        
        return { wood, lodge, community, owner, otherAccount };
    }

    async function waitSecond(time: number): Promise<void> {
        return new Promise(resolve => {
          setTimeout(() => {
            resolve();
          }, time * 1000); 
        });
    }

    async function mint(){
        await network.provider.send("evm_mine", []);
    }

    async function printEvents(filter : string, contrat: Contract, transaction: any){
        // get events
        const events = await contrat.queryFilter(filter, transaction.blockNumber);

        // print events
        events.forEach((event) => {
            console.log("Event " + filter + ":", event.topics);
        });
    }

    describe("Deployment", function () {
        it("Should config correctly", async function () {
            const { wood, lodge, community, owner } = await loadFixture(deployLodgeFixture);
            expect(await community.currentRound()).to.equal(1);
            expect(await community.buildFee()).to.equal(0);
            expect(await community.buildFee()).to.equal(0);
            expect(await wood.balanceOf(community)).to.equal(1e9);

        });
    });

    describe("Functions", function(){
        it("Should output rewards value correctly", async function () {
            const { wood, lodge, community, owner } = await loadFixture(deployLodgeFixture);

            await network.provider.send("evm_setAutomine", [false]);
            await network.provider.send("evm_setIntervalMining", [0]);

            const communityAddress: string = await community.getAddress();
            await wood.approve(communityAddress, 1e9);
            await mint();
            var transaction = await community.build(false, "hello, world");
            await mint();
            await printEvents("NewLodge", community, transaction);
            

            // console.log("total lodges: ",await community.totalLodges());
            transaction = await community.vote(1, 5);
            await mint();
            await printEvents("VoteInCompetition", community, transaction);

            transaction = await community.vote(1, 5, 0, "My favourite!");
            await mint();
            await printEvents("NewComment", community, transaction);
            await printEvents("VoteOutCompetition", community, transaction);
            
            // console.log("competition: ",await community.competitionMapping(0));
            // console.log("lodgeRewards: ",await community.lodgeRewards(1));
            // console.log("sponsorRewards: ",await community.sponsorRewards(1, owner));

            await waitSecond(1);
            transaction =  await community.withdrawRoyalties(1);
            // transaction =  await community.batchWithdrawRoyalties([1]);
            await mint();
            await printEvents("WithdrawRoyalties", community, transaction);
            // await printEvents("BatchWithdrawRoyalties", community, transaction);

            expect(await wood.balanceOf(owner)).to.equal(50005);
            transaction = await community.withdrawRewards(1);
            // transaction = await community.batchWithdrawRewards([1]);
            await mint();
            await printEvents("WithdrawRewards", community, transaction);
            // await printEvents("BatchWithdrawRewards", community, transaction);

            expect(await wood.balanceOf(owner)).to.equal(50000 + 940509);
        });
    });
});
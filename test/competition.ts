import {
    time,
    loadFixture,
  } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers, upgrades,network } from "hardhat";
import { Contract } from "ethers";

describe("Competition Protocol", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployFixture() {
    
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
    
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
        
        return { tc, rc, cp, hackson, owner, otherAccount };
    }

    async function waitSecond(time: number): Promise<void> {
        return new Promise(resolve => {
          setTimeout(() => {
            resolve();
          }, time * 1000); 
        });
    }

    async function printEvents(filter : string, contrat: Contract, transaction: any){
        // get events
        const events = await contrat.queryFilter(filter, transaction.blockNumber);

        // print events
        events.forEach((event) => {
            console.log("Event " + filter + ":", event.topics);
            console.log("Event " + filter + ":", event.data);
        });
    }

    describe("Functions", function(){
        it("Should output events correctly", async function () {
            const { tc, rc, cp, owner } = await loadFixture(deployFixture);
            
            const cpAddress: string = await cp.getAddress();
            await tc.approve(cpAddress, 1e9);
            await rc.approve(cpAddress, 1e9);

            const endTime = await time.latest() + 5;

            const tcAddress:string = await tc.getAddress();
            const rcAddress:string = await tc.getAddress();
            let numbers: number[] = [1e6, 5e5, 1e5];
            var transaction = await cp.create(tcAddress, rcAddress, numbers,
                0, endTime);
            await printEvents("NewCompetition", cp, transaction);

            transaction = await cp.registerCandidate(1, owner);
            await printEvents("NewCandidate", cp, transaction);

            transaction = await cp.vote(1, 1, 10);
            await printEvents("Vote", cp, transaction);

            await waitSecond(6);

            transaction = await cp.withdrawByPlayer(1, 1, owner);
            await printEvents("WithdrawByPlayer", cp, transaction);
            
            transaction = await cp.withdrawByVoter(1, 1, owner);
            await printEvents("WithdrawByVoter", cp, transaction);
        });

        it("Should start a hackson", async function () {
            const { tc, rc, cp, hackson, owner } = await loadFixture(deployFixture);
            
            const cpAddress: string = await cp.getAddress();
            const hacksonAddress: string = await hackson.getAddress();
            const tcAddress:string = await tc.getAddress();
            const rcAddress:string = await rc.getAddress();

            await tc.approve(cpAddress, 1e9);
            await rc.approve(hacksonAddress, 1e9);

            // await rc.transfer(hacksonAddress, 1e6);

            var transaction = await hackson.init(tcAddress, rcAddress, 5);
            await printEvents("NewCompetition", cp, transaction);
            
            transaction = await hackson.register("CPT");
            await printEvents("NewCandidate", cp, transaction);

            transaction = await cp.vote(1, 1, 10);
            await printEvents("Vote", cp, transaction);

            await waitSecond(6);

            transaction = await cp.withdrawByPlayer(1, 1, owner);
            await printEvents("WithdrawByPlayer", cp, transaction);
            
            transaction = await cp.withdrawByVoter(1, 1, owner);
            await printEvents("WithdrawByVoter", cp, transaction);
        });
    });
});
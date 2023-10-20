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
    
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
        
        return { zkBallot, owner, otherAccount };
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
        it("Should verify successfully", async function () {
            const { zkBallot, owner } = await loadFixture(deployFixture);
            const proof = {
                "a": [
                  "0x0c5342ea5c54a5cc34f41c5c5617c4a797313a2899c3e3dd24227e532ce364c4",
                  "0x05db244dce927efa2f312f7266cb63329c3e93884c8adea925126be315594f10"
                ],
                "b": [
                  [
                    "0x2d6dd31f414abe3216caaf95a03acfb85fc7ba80476ddcb3cad207d235fe55c6",
                    "0x09f2c04b695d0611ead68c121143ccc297051096838e99aab94c33136710b828"
                  ],
                  [
                    "0x2f03d3e3f1a5df5b466fa413931f661c37b1922e815e5bdb0cb0bd4a3bde9b86",
                    "0x12783049b06b56e33ac72feef9597378d3335477bb52d73a13ca347605c7d2a2"
                  ]
                ],
                "c": [
                  "0x1062c330076c3df748410ba7c2035215f7713262b20fb35ad61c02049a124d36",
                  "0x16fe7538d3efaa2483e6041f757e560e8641da4cca0cd99fa7008ad4318d5a02"
                ]
              };
            await zkBallot.vote(9, [1,2,3,4], proof.a, proof.b, proof.c);
        });
    });
});
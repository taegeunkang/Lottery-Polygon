import { expect } from "chai";
import { ethers } from "hardhat";

describe("VRF2Consumer", function () {

    it("Should return the entries", async function () {
        const [owner] = await ethers.getSigners();
        console.log("owner address is " + owner.address);
        const VRF2Consumer = await ethers.getContractFactory("VRFv2Consumer");
        const consumer = await VRF2Consumer.deploy(283);
        await consumer.deployed();
        console.log(consumer.address);
        
        const res = await consumer.requestRandomness(3);
        await res.wait();


    });
});

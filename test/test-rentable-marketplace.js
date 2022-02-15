
const { expect } = require("chai");
const { ethers } = require("hardhat");
const dayjs = require("dayjs");
const { network  } = require("hardhat");


describe("NFTMarket", function() {
  it("Should create and execute market sales", async function() {

    const Market = await ethers.getContractFactory("RentalMarket")
    const market = await Market.deploy()
    await market.deployed()
    const marketAddress = market.address

    const NFT = await ethers.getContractFactory("NFT")
    const nft = await NFT.deploy(marketAddress)
    await nft.deployed()
    const nftContractAddress = nft.address


  });
});
const { expect } = require("chai");
const { ethers } = require("hardhat");
const dayjs = require("dayjs");
const { network  } = require("hardhat");


describe("NFTMarket", function() {
  it("Should create NFT tokens, list NFT for Rent in MarketPlace and allow renting of NFT", async function() {

    const Market = await ethers.getContractFactory("RentalMarket")
    const market = await Market.deploy()
    await market.deployed()
    const marketAddress = market.address

    const NFT = await ethers.getContractFactory("NFT")
    const nft = await NFT.deploy(marketAddress)
    await nft.deployed()
    const nftContractAddress = nft.address

    let listingPrice = await market.getListingPrice()
    listingPrice = listingPrice.toString()

    const auctionPrice = ethers.utils.parseUnits('1', 'ether')
    const NFT_price = ethers.utils.parseUnits('0.01', 'ether')

    console.log("Listing Price", listingPrice);
    const expiresAt = dayjs().add(1, 'day').unix()
    const [buyerAddress, renterAddress, renterAddress2, guyAddress] = await ethers.getSigners()

    await nft.connect(buyerAddress).createToken("https://www.mytokenlocation.com")
    // await nft.connect(buyerAddress).buyToken(1, { value: NFT_price})
    await nft.connect(buyerAddress).createToken("https://www.mytokenlocation2.com")
    // await nft.connect(buyerAddress).buyToken(2, { value: NFT_price})
    await nft.connect(buyerAddress).createToken("https://www.mytokenlocation3.com")
    // await nft.connect(buyerAddress).buyToken(3, { value: NFT_price})
    await nft.connect(buyerAddress).createToken("https://www.mytokenlocation3.com")
  
    // console.log("NFT 1 Owner Before-> ", await nft.ownerOf(1))
    await market.connect(buyerAddress).createMarketItem(nftContractAddress, 1, auctionPrice, expiresAt, { value: listingPrice })
    // console.log("NFT 1 Owner After-> ", await nft.ownerOf(1))
    // console.log("MarketPlace Address-> ", marketAddress)
    // console.log("~~~~~~~~~~~~~~~~~~~~~~~ USER CAN DEPOSIT TO MARKETPLACE ~~~~~~~~~~~~~~~~~~~~~~~")

    await market.connect(buyerAddress).createMarketItem(nftContractAddress, 2, auctionPrice, expiresAt, { value: listingPrice })
    await market.connect(buyerAddress).createMarketItem(nftContractAddress, 3, auctionPrice, expiresAt, { value: listingPrice })

    // console.log("NFT 1 Owner Before-> ", await nft.ownerOf(1))
    await market.connect(renterAddress).rentMarketItem(nftContractAddress, 1, { value: auctionPrice});
    await market.connect(renterAddress).rentMarketItem(nftContractAddress, 2, { value: auctionPrice});
    console.log("NFT 3 Owner Before-> ", await nft.ownerOf(3))
    console.log("MarketPlace Address-> ", marketAddress)
    await market.connect(renterAddress2).rentMarketItem(nftContractAddress, 3, { value: auctionPrice});
    
      
    // console.log("NFT 1 Owner After-> ", await nft.ownerOf(1))
    // console.log("Renter Address-> ", renterAddress.address)
    // console.log("~~~~~~~~~~~~~~~~~~~~~~~ USER CAN RENT FROM MARKETPLACE ~~~~~~~~~~~~~~~~~~~~~~~")

    // console.log("~~~~~~~~~~~~~~~~~~~~~~~ USER CAN PAYBACK THE RENTED NFT ~~~~~~~~~~~~~~~~~~~~~~~")
    
    await expect(
      nft.connect(renterAddress).transferFrom(renterAddress.address, guyAddress.address, 1)
    ).to.be.revertedWith('RentableNFT: this token is rented')


  });
});
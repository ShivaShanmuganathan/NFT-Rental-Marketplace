const { expect } = require("chai");
const { ethers } = require("hardhat");
const dayjs = require("dayjs");
const { network  } = require("hardhat");


describe("NFT Rental Marketplace", function() {

  let buyerAddress, renterAddress, renterAddress2, guyAddress;

  before(async function () {
    [buyerAddress, renterAddress, renterAddress2, guyAddress] = await ethers.getSigners()
  })

  it("Should Deploy Rental Marketplace & NFT contract", async function() {
    const Market = await ethers.getContractFactory("RentalMarket")
    market = await Market.deploy()
    await market.deployed()
    marketAddress = market.address
    console.log("NFT Rental Marketplace Address: ", marketAddress);

    const NFT = await ethers.getContractFactory("NFT")
    nft = await NFT.deploy(marketAddress)
    await nft.deployed()
    nftContractAddress = nft.address
    console.log("NFT Contract Address: ", nftContractAddress);

  });

  it("Should check listing price & declare necessary variables", async function() {
    
    listingPrice = (await market.getListingPrice()).toString()
    console.log("Listing Price", ethers.utils.formatEther(listingPrice), "ETH");
    expect(listingPrice).to.be.equal(ethers.utils.parseUnits('0.025', 'ether'))

    auctionPrice = ethers.utils.parseUnits('1', 'ether')
    NFT_price = ethers.utils.parseUnits('0.01', 'ether')

    expiresAt = dayjs().add(1, 'day').unix()
    

  });

  it("Should Create NFT and list it in Rental Marketplace", async function() {
    
    await nft.connect(buyerAddress).createToken("https://www.mytokenlocation.com")
    expect(await nft.ownerOf(1)).to.be.equal(buyerAddress.address)
    console.log("Token ID 1 Owner Address: ",await nft.ownerOf(1))
    console.log("Buyer Address: ",buyerAddress.address)
    

    await market.connect(buyerAddress).createMarketItem(nftContractAddress, 1, auctionPrice, 100, { value: listingPrice })
    expect(await nft.ownerOf(1)).to.be.equal(marketAddress)
    console.log("Token ID 1 Owner Address After Listing: ",await nft.ownerOf(1))
    console.log("Market Address: ",marketAddress)


    await nft.connect(buyerAddress).createToken("https://www.mytokenlocation2.com")
    expect(await nft.ownerOf(2)).to.be.equal(buyerAddress.address)
    await market.connect(buyerAddress).createMarketItem(nftContractAddress, 2, auctionPrice, 100, { value: listingPrice })
    expect(await nft.ownerOf(2)).to.be.equal(marketAddress)
    
    await nft.connect(buyerAddress).createToken("https://www.mytokenlocation3.com")
    expect(await nft.ownerOf(3)).to.be.equal(buyerAddress.address)
    await market.connect(buyerAddress).createMarketItem(nftContractAddress, 3, auctionPrice, 100, { value: listingPrice })
    expect(await nft.ownerOf(3)).to.be.equal(marketAddress)
    

    await nft.connect(buyerAddress).createToken("https://www.mytokenlocation3.com")
    expect(await nft.ownerOf(4)).to.be.equal(buyerAddress.address)
    // console.log("~~~~~~~~~~~~~~~~~~~~~~~ USER CAN LIST NFT FOR RENT IN MARKETPLACE ~~~~~~~~~~~~~~~~~~~~~~~")
    
  });

  it("Non-NFT Owner creating a listing on Rental Marketplace is prohibited ", async function() {
    
    await expect(market.connect(guyAddress).createMarketItem(nftContractAddress, 4, auctionPrice, 100, { value: listingPrice })).to.be.revertedWith('ERC721: transfer of token that is not own')

  });

  it("Allow anyone to Rent listed NFTs from Marketplace by paying rental fee ", async function() {

    expect(await nft.ownerOf(1)).to.be.equal(marketAddress)
    await market.connect(renterAddress).rentMarketItem(nftContractAddress, 1, { value: auctionPrice});
    expect(await nft.ownerOf(1)).to.be.equal(renterAddress.address)

    expect(await nft.ownerOf(2)).to.be.equal(marketAddress)
    await market.connect(renterAddress).rentMarketItem(nftContractAddress, 2, { value: auctionPrice});
    expect(await nft.ownerOf(2)).to.be.equal(renterAddress.address)

    // console.log("NFT 3 Owner Before-> ", await nft.ownerOf(3))
    // console.log("MarketPlace Address-> ", marketAddress)

    expect(await nft.ownerOf(3)).to.be.equal(marketAddress)
    await market.connect(renterAddress2).rentMarketItem(nftContractAddress, 3, { value: auctionPrice});
    expect(await nft.ownerOf(3)).to.be.equal(renterAddress2.address)
    // console.log("~~~~~~~~~~~~~~~~~~~~~~~ USER CAN RENT FROM MARKETPLACE ~~~~~~~~~~~~~~~~~~~~~~~")
    
  });

  it("Rented NFT Transfer attempt is prohibited ", async function() {

    await expect(nft.connect(renterAddress).transferFrom(renterAddress.address, guyAddress.address, 1)).
          to.be.revertedWith('RentableNFT: this token is rented')

    await expect(nft.connect(renterAddress2).transferFrom(renterAddress2.address, guyAddress.address, 3)).
                to.be.revertedWith('RentableNFT: this token is rented')

  });

  it("Token Owner's attempt to finishRenting before time expires is prohibited ", async function() {

    await expect (market.connect(buyerAddress).finishRenting(1)).to.be.revertedWith('RentableNFT: this token is rented')

  });

  it("Finish Renting NFT Early by renter", async function() {

    // console.log("~~~~~~~~~~~~~~~~~~~~~~~ EARLY FINISH ~~~~~~~~~~~~~~~~~~~~~~~")
    console.log("NFT 1 Owner Before Finish Renting-> ", await nft.ownerOf(1))
    expect(await nft.ownerOf(1)).to.be.equal(renterAddress.address)
    await market.connect(renterAddress).finishRenting(1)
    expect(await nft.ownerOf(1)).to.be.equal(buyerAddress.address)
    console.log("NFT 1 Owner After Finish Renting-> ", await nft.ownerOf(1))
    
    await expect(market.connect(guyAddress).finishRenting(3)).to.be.reverted;
    console.log();

    console.log("NFT 3 Owner Before Finish Renting-> ", await nft.ownerOf(3))
    await market.connect(renterAddress2).finishRenting(3)
    expect(await nft.ownerOf(3)).to.be.equal(buyerAddress.address)
    console.log("NFT 3 Owner After Finish Renting-> ", await nft.ownerOf(3))
    

  });


  it("Check NFTs Rented by the user in this marketplace", async function() {
    console.log("~~~~~~~~~~~~~~~~~~~~~~~ TESTING FETCH FUNCTIONS ~~~~~~~~~~~~~~~~~~~~~~~");
    console.log(await market.connect(renterAddress.address).fetchRentedNFTs())
    
    await market.connect(buyerAddress).createMarketItem(nftContractAddress, 4, auctionPrice, 100, { value: listingPrice })
    console.log("Returned Value For Fetch Function", await market.connect(buyerAddress).fetchMarketItems());
    await market.connect(buyerAddress).fetchMyNFTs()    

  })




  it("Increase Time & Finish Renting Rented NFT After Expiry", async function() {
    
    console.log("Time Now",new Date().getTime())
    //get how time is calculated in frontend
    await ethers.provider.send('evm_increaseTime', [1800]);
    await ethers.provider.send('evm_mine');
    console.log("~~~~~~~~~~~~~~~~~~~~~~~ TIME INCREASED ~~~~~~~~~~~~~~~~~~~~~~~")

    // console.log("~~~~~~~~~~~~~~~~~~~~~~~ AFTER TIME ~~~~~~~~~~~~~~~~~~~~~~~")
    
    console.log(await market.connect(buyerAddress).fetchItemsClaimable())
    // console.log("Returned Value For Fetch Function", await market.connect(buyerAddress).fetchMarketItems());

    // console.log("Checking Second NFT ")
    console.log("NFT 2 Owner Before Finish Renting-> ", await nft.ownerOf(2))
    await market.connect(guyAddress).finishRenting(2)
    expect(await nft.ownerOf(2)).to.be.equal(buyerAddress.address)
    console.log("NFT 2 Owner After Finish Renting-> ", await nft.ownerOf(2))
    
    console.log();
    
  })

  

  it("Test Changing Listing Price", async function() {

    await market.connect(buyerAddress).setListingPrice(ethers.utils.parseUnits('0.1', 'ether'))
    expect(await market.getListingPrice()).to.be.equal(ethers.utils.parseUnits('0.1', 'ether'))

  })

  

});

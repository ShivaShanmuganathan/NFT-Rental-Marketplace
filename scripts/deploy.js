// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");
const dayjs = require("dayjs");



async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const Market = await ethers.getContractFactory("RentalMarket")
    const market = await Market.deploy()
    await market.deployed()
    const marketAddress = market.address
    console.log("NFT Rental Marketplace: ", marketAddress);

    const NFT = await ethers.getContractFactory("NFT")
    const nft = await NFT.deploy(marketAddress)
    await nft.deployed()
    const nftContractAddress = nft.address
    console.log("NFT Contract: ", nftContractAddress);

    let listingPrice = await market.getListingPrice()
    listingPrice = listingPrice.toString()

    const auctionPrice = ethers.utils.parseUnits('1', 'ether')
    const NFT_price = ethers.utils.parseUnits('0.01', 'ether')

    console.log("Listing Price", listingPrice);
    const expiresAt = dayjs().add(1, 'day').unix()
    const [buyerAddress, renterAddress, renterAddress2, guyAddress] = await ethers.getSigners()

    // await nft.connect(buyerAddress).createToken("https://www.rd.com/wp-content/uploads/2021/03/GettyImages-1133605325-scaled-e1617227898456.jpg")
    // await market.connect(buyerAddress).createMarketItem(nftContractAddress, 1, auctionPrice, expiresAt, { value: listingPrice })
    // console.log("Created & Uploaded Token 1");
    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

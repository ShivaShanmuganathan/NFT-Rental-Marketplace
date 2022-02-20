# [NFT Rental Marketplace](https://nft-rental-marketplace.netlify.app/) 
![alt text](rental_poster1.JPG)
![alt text](rental_poster.JPG)

## Check Out [Live Site](https://nft-rental-marketplace.netlify.app/) - {Deployed Polygon Testnet}


## How Does It Work?

When an owner lists a NFT for rent in the Marketplace, the ownership of the item will be transferred from the owner to the marketplace.

When a user rents a NFT, the rental price will be transferred from the buyer to the seller and the NFT will be transferred from the marketplace to the renter.

The marketplace owner will be able to set a listing fee. This fee will be taken from the seller and transferred to the contract owner, enabling the owner of the marketplace to earn recurring revenue from any listing transacted in the marketplace.

## About Contracts
The marketplace logic will consist of two smart contracts:

NFT Contract - This contract allows users to mint unique digital assets.

Marketplace Contract - This contract allows NFT owners to put their digital assets for rent on an open market.

## Working Explained In Detail
1. Anyone who has created a ERC721 contract with additional functions similar to NFT.sol can list their NFTs for Rent in the Marketplace.
2. Anyone can rent the NFTs listed in the marketplace by paying rent.
3. The Renter will not be able to transfer the NFT to anyone, because the NFT.sol contract prevents the token transfer while it is on rent.
4. Finish Renting function will enable anyone to end the renting process, and return the NFT to Seller. 


## Clone This Project & Play Around


### Clone This Repo
```shell

git clone https://github.com/ShivaShanmuganathan/NFT-Rental-Marketplace.git
cd NFT-Rental-Marketplace

```

### Install Dependencies

``` shell
npm install
```

### Compile The Contracts & Test It

``` shell

npx hardhat compile
npx hardhat test

```

### Run The frontend

``` shell
cd frontend
npm install
npm run dev
```
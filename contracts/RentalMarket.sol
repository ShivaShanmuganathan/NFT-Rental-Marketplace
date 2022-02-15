// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract RentalMarket is ReentrancyGuard{
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsRented;
  
  address payable owner;
  uint256 listingPrice = 0.005 ether;

  constructor() {
    owner = payable(msg.sender);
  }

  struct MarketItem {
      uint itemId;
      bool isActive;
      address NFTContract;
      uint256 tokenId;
      address payable seller;
      address renter;
      uint256 price;
      uint256 expiresAt;
    }
  
  mapping(uint256 => MarketItem) private idToMarketItem;

  event MarketItemCreated (
    uint indexed itemId,
    bool isActive,
    address indexed NFTContract,
    uint256 indexed tokenId,
    address seller,
    address renter,
    uint256 price,
    uint256 expiresAt
  );

  /* Returns the listing price of the contract */
  function getListingPrice() public view returns (uint256) {
    return listingPrice;
  }

  /* Places an item for rent on the marketplace */
  function createMarketItem(address nftContract, uint256 tokenId, uint256 price, uint256 expiresAt ) public payable nonReentrant
  {
    
    require(price > 0, "Price must be at least 1 wei");
    require(msg.value == listingPrice, "Price must be equal to listing price");

    _itemIds.increment();
    uint256 itemId = _itemIds.current();
    

    idToMarketItem[itemId] =  MarketItem(
      itemId,
      false,
      address(nftContract),
      tokenId,
      payable(msg.sender),
      address(0),
      price,
      expiresAt
    );

    IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
    payable(owner).transfer(listingPrice);

    emit MarketItemCreated(
      itemId,
      false,
      nftContract,
      tokenId,
      msg.sender,
      address(0),
      price,
      expiresAt
    );

  }


  /* Renters can use this function to rent the listed NFT in the marketplace */
  /* Transfers ownership of the NFT, as well as funds between parties */
  function rentMarketItem(
    address nftContract,
    uint256 itemId
    ) public payable nonReentrant {

      uint price = idToMarketItem[itemId].price;
      uint tokenId = idToMarketItem[itemId].tokenId;

      require(msg.value == price, "Please submit the asking price in order to complete the purchase");
      require(IERC721(nftContract).ownerOf(tokenId) == address(this), "This Token Is Not Available For Rent");
      
      idToMarketItem[itemId].seller.transfer(msg.value);
      
      IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
      
      (bool success, ) = nftContract.call(
              abi.encodeWithSignature("modifyRental(bool,uint256)", true,tokenId)
      );      
      require(success);

      idToMarketItem[itemId].renter = msg.sender;
      idToMarketItem[itemId].isActive = true;
      _itemsRented.increment();
      
  }


  
  
}
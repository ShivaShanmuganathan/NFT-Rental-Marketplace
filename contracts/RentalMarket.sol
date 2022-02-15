// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract RentalMarket {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  
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
  
  
}
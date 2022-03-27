// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "hardhat/console.sol";

contract RentalMarket is ReentrancyGuard {
  using Counters for Counters.Counter;
  Counters.Counter private _itemIds;
  Counters.Counter private _itemsRented;
  Counters.Counter private _itemsPaidBack;
  
  address payable owner;
  uint256 listingPrice = 0.025 ether;

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

  function setListingPrice(uint256 _listingPrice) external onlyOwner{
    listingPrice = _listingPrice ;
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
      idToMarketItem[itemId].expiresAt = idToMarketItem[itemId].expiresAt + block.timestamp;
      idToMarketItem[itemId].renter = msg.sender;
      idToMarketItem[itemId].isActive = true;
      _itemsRented.increment();
      
  }

  /* Anyone can call this function to return the rented NFTs that have crossed expiry time */
  /* Transfers ownership of the NFT from renter to seller*/
  function finishRenting(uint256 itemId) external nonReentrant
  {
        
        MarketItem storage _rental = idToMarketItem[itemId];
        
        require(
            msg.sender == _rental.renter ||
                block.timestamp >= _rental.expiresAt,
            "RentableNFT: this token is rented"
        );

        require(_rental.isActive, "NFT is not on rent");
        
        _rental.isActive = false;
        (bool success, ) = (_rental.NFTContract).call(
              abi.encodeWithSignature("modifyRental(bool,uint256)", false, _rental.tokenId)
        );
        require(success);

        (bool success2, ) = (_rental.NFTContract).call(
              abi.encodeWithSignature("performTokenTransfer(address,address,uint256)", _rental.renter, _rental.seller, _rental.tokenId)
        );
        require(success2);

        console.log("Renter Address From Contract-> ", _rental.renter);
        console.log("Seller Address From Contract-> ", _rental.seller);
        
        _itemsPaidBack.increment();
        delete idToMarketItem[itemId];        

    }

    // NftOwner claims nft
    // function tokenOwnerClaimsNFT(uint256 itemId) external nonReentrant{ 

    //   MarketItem storage _rental = idToMarketItem[itemId];
        
    //   require(
    //       msg.sender == _rental.seller &&
    //           _rental.isActive == false,
    //       "RentableNFT: this token is rented"
    //   );
      

    //   require(IERC721(_rental.NFTContract).ownerOf(_rental.tokenId) == address(this), "MarketPlace Does Not Own This NFT");
    //   IERC721(_rental.NFTContract).transferFrom(address(this), msg.sender, _rental.tokenId);
    // }

    // // NftOwner Modifies nftDetails
    // function tokenOwnerModifiesNFT(uint256 itemId, uint256 price, uint256 expiresAt) external payable nonReentrant{ 

    //   MarketItem storage _rental = idToMarketItem[itemId];

    //   console.log("Time Now in Contract", block.timestamp);
    //   console.log("Expiry Time ", expiresAt);
      
    //   require(IERC721(_rental.NFTContract).ownerOf(_rental.tokenId) == address(this), "MarketPlace Does Not Own This NFT");  

    //   require(
    //       msg.sender == _rental.seller &&
    //           _rental.isActive == false,
    //       "RentableNFT: this token is rented"
    //   );
    //   require(block.timestamp >= _rental.expiresAt, "rental is not expired yet" );
    //   require(expiresAt > block.timestamp, "Time is lower than current time" );
    //   require(price > 0, "Price must be at least 1 wei");
    //   // console.log("Listing Price From Contract", listingPrice/2);
    //   require(msg.value == listingPrice/2, "Price must be equal to listing price");

    //   _rental.expiresAt = expiresAt;
    //   _rental.price = price;
    //   _rental.renter = address(0);
    //   _itemIds.increment();
      
    // }

  
  /* Returns all items listed for rent in market items */
  function fetchMarketItems() public view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsRented.current();
    uint currentIndex = 0;
    
    // console.log("item Count", itemCount);
    // console.log("item Rented", _itemsRented.current());
    // console.log("unsoldItemCount ",unsoldItemCount);

    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    console.log("Address Zero",address(0));
    for (uint i = 0; i < itemCount; i++) {

      console.log("Item ID",idToMarketItem[i + 1].itemId);
      console.log("Item Renter",idToMarketItem[i + 1].renter);
      
      if ( (idToMarketItem[i + 1].itemId != 0) && (idToMarketItem[i + 1].renter == address(0)) ) {

        uint currentId = i + 1;
        console.log("Item On Market", i);
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;

      }

    }
    return items;
  }

  /* Returns only items that a user owns*/
  function fetchMyNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].seller == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns only items that a user has rented*/
  function fetchRentedNFTs() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;

    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].renter == msg.sender) {
        itemCount += 1;
      }
    }

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].renter == msg.sender) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  /* Returns items that can be claimed */
  function fetchItemsClaimable() public view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;


    console.log("Time Now", block.timestamp);

    for (uint i = 0; i < totalItemCount; i++) {
      // Rent is Active && Time Has Crossed
      if (idToMarketItem[i + 1].isActive && idToMarketItem[i + 1].expiresAt <= block.timestamp) {
        itemCount += 1;
      }
    }

    console.log("total claimable items", itemCount);

    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].isActive && idToMarketItem[i + 1].expiresAt <= block.timestamp) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  modifier onlyOwner() {
      
      require(msg.sender == owner, "Only Owner Can Access This Function");
      _;

  }

}

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

  function setListingPrice(uint256 _listingPrice) external onlyOwner{
    listingPrice = _listingPrice ;
  }
  
  /* Places an item for sale on the marketplace */
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

  function finishRenting(uint256 itemId) external nonReentrant{
        
        MarketItem storage _rental = idToMarketItem[itemId];
        
        require(
            msg.sender == _rental.renter ||
                block.timestamp >= _rental.expiresAt,
            "RentableNFT: this token is rented"
        );
        
        _rental.isActive = false;
        (bool success, ) = (_rental.NFTContract).call(
              abi.encodeWithSignature("modifyRental(bool,uint256)", false, _rental.tokenId)
        );
        require(success);

        (bool success2, ) = (_rental.NFTContract).call(
              abi.encodeWithSignature("performTokenTransfer(address,address,uint256)", _rental.renter, address(this), _rental.tokenId)
        );
        require(success2);

        console.log("Renter Address From Contract-> ", _rental.renter);
        console.log("Seller Address From Contract-> ", _rental.seller);
        
        _rental.renter = address(0);
        _itemsPaidBack.increment();
        

    }

    // NftOwner claims nft
    function tokenOwnerClaimsNFT(uint256 itemId) external nonReentrant{ 

      MarketItem storage _rental = idToMarketItem[itemId];
        
      require(
          msg.sender == _rental.seller &&
              _rental.isActive == false,
          "RentableNFT: this token is rented"
      );
      

      require(IERC721(_rental.NFTContract).ownerOf(_rental.tokenId) == address(this), "MarketPlace Does Not Own This NFT");
      IERC721(_rental.NFTContract).transferFrom(address(this), msg.sender, _rental.tokenId);
    }

    // NftOwner Modifies nftDetails
    function tokenOwnerModifiesNFT(uint256 itemId, uint256 price, uint256 expiresAt) external payable nonReentrant{ 

      MarketItem storage _rental = idToMarketItem[itemId];

      console.log("Time Now in Contract", block.timestamp);
      console.log("Expiry Time ", expiresAt);
      
      require(IERC721(_rental.NFTContract).ownerOf(_rental.tokenId) == address(this), "MarketPlace Does Not Own This NFT");  

      require(
          msg.sender == _rental.seller &&
              _rental.isActive == false,
          "RentableNFT: this token is rented"
      );
      require(block.timestamp >= _rental.expiresAt, "rental is not expired yet" );
      require(expiresAt > block.timestamp, "Time is lower than current time" );
      require(price > 0, "Price must be at least 1 wei");
      // console.log("Listing Price From Contract", listingPrice/2);
      require(msg.value == listingPrice/2, "Price must be equal to listing price");

      _rental.expiresAt = expiresAt;
      _rental.price = price;
      _itemsRented.increment();
      
    }

    modifier onlyOwner() {
        
        require(msg.sender == owner, "Only Owner Can Access This Function");
        _;

    }

}
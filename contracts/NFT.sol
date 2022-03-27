// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";

// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Makes Debugging Easy
import "hardhat/console.sol";

// @title NFT 
/// @author Shiva Shanmuganathan
/// @notice This contract implements a simple NFT contract for the NFT Rental Marketplace 
/// @dev All function calls are currently implemented without any bugs
contract NFT is ERC721URIStorage {
    
    // We will use counters for tracking tokenId
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Address of NFT Rental Marketplace
    address contractAddress;

    // tokenId to Rent Status
    mapping (uint256 => bool) public rental;

    
    /// @notice Constructor function initializes the address of NFT Rental Marketplace Contract
    /// @dev contractAddress is set in constructor, so that we will be able to use it in modifier for verifying the sender of transaction
    /// @param marketplaceAddress -> Address of NFT Rental Marketplace
    constructor(address marketplaceAddress) ERC721("RentableNFT", "RFT") {
        contractAddress = marketplaceAddress;
    }

      
    /// @notice Create RFT Tokens by using mint & setTokenURI
    /// @dev First TokenId is incremented to 1
    /// @param tokenURI This string contains the image url link, which is associated to the NFT
    /// @return Returns the itemId of the created token
    function createToken(string memory tokenURI) public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        approve(contractAddress, newItemId);
        return newItemId;
    }

    /// @notice Update Rental Status To True or False
    /// @dev Only the NFT Rental Marketplace contract will be able to update the rental status 
    /// @param value The value to be updated is passed from the NFT Rental Marketplace contract
    /// @param tokenId The tokenId of token to be updated
    /// onlyMartketPlace Only NFT Rental Marketplace Contract will be able to access this function.
    function modifyRental(bool value, uint256 tokenId) external onlyMarketPlace {
        
        rental[tokenId] = value;

    }

    
    /// @notice Transfer Tokens From Renter To Seller
    /// @dev Only the NFT Rental Marketplace contract will be able to call this function, _transfer function is used to transfer the tokens
    /// @param from The address of renter, who is currently the token owner
    /// @param to The address of seller, which is passed from the NFT Rental Marketplace contract
    /// @param tokenId The tokenId of token to be transferred
    /// onlyMartketPlace Only NFT Rental Marketplace Contract will be able to access this function.
    function performTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external onlyMarketPlace
    {
        
        _transfer(from, to, tokenId);

    }

    /// @notice Overridden function to check if token is rented before making token transfer. 
    /// @dev Internal Function to check if token is rented before making token transfer. 
    /// @param from The address of sender, who is currently the token owner
    /// @param to The address of receiver, which is passed from the NFT Rental Marketplace contract
    /// @param tokenId The tokenId of token to be transferred
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        require(!rental[tokenId], "RentableNFT: this token is rented");

        super._beforeTokenTransfer(from, to, tokenId);
    }

    /// @notice Ensures that the function caller is the NFT Rental Marketplace Contract 
    /// @dev Ensures that the function caller is the NFT Rental Marketplace Contract 
    modifier onlyMarketPlace() {
        
        require(msg.sender == contractAddress, "Caller must be contractAddress");
        _;

    }

}
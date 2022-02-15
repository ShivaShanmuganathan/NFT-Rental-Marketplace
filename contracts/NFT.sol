// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFT is ERC721URIStorage {
    
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address contractAddress;

    // tokenId to Rent Status
    mapping (uint256 => bool) public rental;

    constructor(address marketplaceAddress) ERC721("RentableNFT", "RFT") {
        contractAddress = marketplaceAddress;
    }

    function createToken(string memory tokenURI) public returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        approve(contractAddress, newItemId);
        return newItemId;
    }

    function modifyRental(bool value, uint256 tokenId) external {
        
        rental[tokenId] = value;

    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        require(!rental[tokenId], "RentableNFT: this token is rented");

        super._beforeTokenTransfer(from, to, tokenId);
    }

}
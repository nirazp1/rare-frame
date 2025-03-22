// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract RareEvoTicket is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant MAX_TICKETS = 1000;
    
    struct TicketData {
        bool claimed;
        string registrantName;
        string registrantEmail;
        string registrantCompany;
        uint256 claimTimestamp;
    }
    
    mapping(uint256 => TicketData) public ticketDetails;
    
    event TicketMinted(address indexed buyer, uint256 indexed tokenId);
    event TicketClaimed(uint256 indexed tokenId, string registrantName, uint256 timestamp);
    
    constructor() ERC721("Rare Evo 2025 Ticket", "REVO") Ownable(msg.sender) {}
    
    function mintTicket() public payable returns (uint256) {
        require(msg.value >= TICKET_PRICE, "Insufficient payment");
        require(_tokenIds.current() < MAX_TICKETS, "All tickets sold out");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        
        _safeMint(msg.sender, newTokenId);
        
        // Set default metadata URI
        _setTokenURI(newTokenId, "ipfs://default-ticket-metadata");
        
        ticketDetails[newTokenId] = TicketData({
            claimed: false,
            registrantName: "",
            registrantEmail: "",
            registrantCompany: "",
            claimTimestamp: 0
        });
        
        emit TicketMinted(msg.sender, newTokenId);
        return newTokenId;
    }
    
    function claimTicket(
        uint256 tokenId,
        string memory name,
        string memory email,
        string memory company
    ) public {
        require(ownerOf(tokenId) == msg.sender, "Not ticket owner");
        require(!ticketDetails[tokenId].claimed, "Ticket already claimed");
        
        ticketDetails[tokenId].claimed = true;
        ticketDetails[tokenId].registrantName = name;
        ticketDetails[tokenId].registrantEmail = email;
        ticketDetails[tokenId].registrantCompany = company;
        ticketDetails[tokenId].claimTimestamp = block.timestamp;
        
        // Update metadata URI with claimed status
        _setTokenURI(tokenId, string(abi.encodePacked("ipfs://claimed-ticket-metadata-", toString(tokenId))));
        
        emit TicketClaimed(tokenId, name, block.timestamp);
    }
    
    function getTicketDetails(uint256 tokenId) public view returns (TicketData memory) {
        require(_exists(tokenId), "Ticket does not exist");
        return ticketDetails[tokenId];
    }
    
    function withdrawFunds() public onlyOwner {
        (bool success, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
    
    // Helper function to convert uint to string
    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
    
    // Override required functions
    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
    
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
} 
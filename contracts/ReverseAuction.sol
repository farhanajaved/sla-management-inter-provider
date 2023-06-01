pragma solidity ^0.8.0;

import "./DecentralizedMarketplace.sol";

contract ReverseAuction is DecentralizedMarketplace {
    struct Auction {
        string features;
        uint256 duration;
        address[] providers;
        bool auctionEnded;
        address winner;
        uint256 lowestBid;
    }

    mapping(address => Auction) public auctions;

    event AuctionStarted(address consumer, string features, uint256 duration);
    event BidPlaced(address provider, address consumer, uint256 bid);
    event AuctionEnded(address consumer, address winner, uint256 lowestBid);

    modifier onlyRegisteredWithTokenIdentity() {
        require(
            consumers[msg.sender].isRegistered || providers[msg.sender].isRegistered,
            "Only registered users with token identity can access this functionality"
        );
        _;
    }

    function startAuction(string memory features, uint256 duration) external onlyRegisteredWithTokenIdentity {
        require(consumers[msg.sender].isRegistered, "Only consumers can start an auction");

        auctions[msg.sender] = Auction(features, duration, new address[](0), false, address(0), 0);
        emit AuctionStarted(msg.sender, features, duration);
    }

    function placeBid(address consumer) external payable onlyRegisteredProvider {
        require(auctions[consumer].providers.length > 0, "Auction does not exist");
        require(!auctions[consumer].auctionEnded, "Auction has already ended");
        require(msg.value > 0, "Bid value must be greater than zero");

        auctions[consumer].providers.push(msg.sender);

        if (auctions[consumer].lowestBid == 0 || msg.value < auctions[consumer].lowestBid) {
            auctions[consumer].lowestBid = msg.value;
            auctions[consumer].winner = msg.sender;
        }

        emit BidPlaced(msg.sender, consumer, msg.value);
    }

    function endAuction(address consumer) external onlyRegisteredWithTokenIdentity {
        Auction storage auction = auctions[consumer];
        require(auction.providers.length > 0, "Auction does not exist");
        require(!auction.auctionEnded, "Auction has already ended");
        require(consumer == msg.sender || auction.winner == msg.sender, "Not authorized to end this auction");

        auction.auctionEnded = true;
        emit AuctionEnded(consumer, auction.winner, auction.lowestBid);
    }

    function getAuctionDetails(address consumer) external view onlyRegisteredWithTokenIdentity returns (string memory, uint256, bool, address, uint256) {
        Auction storage auction = auctions[consumer];
        require(auction.providers.length > 0, "Auction does not exist");

        return (auction.features, auction.duration, auction.auctionEnded, auction.winner, auction.lowestBid);
    }
}

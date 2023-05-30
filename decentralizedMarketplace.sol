pragma solidity ^0.8.0;

contract decentralizedMarketplace {
    mapping(address => bool) public isConsumerRegistered;
    mapping(address => bool) public isProviderRegistered;
    mapping(address => bool) public hasTokenizedIdentity;
    mapping(address => string) public ipfsHashes;

    event ConsumerRegistered(address consumer);
    event ProviderRegistered(address provider);

    modifier onlyRegisteredConsumer() {
        require(isConsumerRegistered[msg.sender], "Only registered consumers can access this functionality");
        _;
    }

    modifier onlyRegisteredProvider() {
        require(isProviderRegistered[msg.sender], "Only registered providers can access this functionality");
        _;
    }

    function registerConsumer() external {
        isConsumerRegistered[msg.sender] = true;
        emit ConsumerRegistered(msg.sender);
        if (isProviderRegistered[msg.sender])
            hasTokenizedIdentity[msg.sender] = true;
    }

    function registerProvider() external {
        isProviderRegistered[msg.sender] = true;
        emit ProviderRegistered(msg.sender);
        if (isConsumerRegistered[msg.sender])
            hasTokenizedIdentity[msg.sender] = true;
    }

    function getHash() external view onlyRegisteredConsumer returns (string memory) {
        return ipfsHashes[msg.sender];
    }

    function setHash(string memory hash) external onlyRegisteredConsumer {
        ipfsHashes[msg.sender] = hash;
    }
}

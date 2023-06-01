pragma solidity ^0.8.0;

contract DecentralizedMarketplace {
    struct Provider {
        string serviceName;
        string features;
        uint256 price;
        bool isRegistered;
        bool isServiceAvailable;
        address providerAddress;
        address[] consumers;
    }

    struct Consumer {
        bool isRegistered;
        bool hasPurchased;
        address consumerAddress;
        address providerAddress;
    }

    mapping(address => Provider) public providers;
    mapping(address => Consumer) public consumers;

    event ConsumerRegistered(address consumer);
    event ProviderRegistered(address provider);
    event ServiceOffered(address provider, string serviceName, string features, uint256 price);
    event ServicePurchased(address provider, address consumer, string serviceName, uint256 price);
    event ServiceRejected(address provider, address consumer, string serviceName);

    modifier onlyRegisteredConsumer() {
        require(consumers[msg.sender].isRegistered, "Only registered consumers can access this functionality");
        _;
    }

    modifier onlyRegisteredProvider() {
        require(providers[msg.sender].isRegistered, "Only registered providers can access this functionality");
        _;
    }

    modifier onlyRegisteredConsumerOrProvider() {
        require(consumers[msg.sender].isRegistered || providers[msg.sender].isRegistered, "Only registered consumers or providers can access this functionality");
        _;
    }

    function registerConsumer() external {
        require(!consumers[msg.sender].isRegistered, "Consumer is already registered");

        consumers[msg.sender] = Consumer(true, false, msg.sender, address(0));
        emit ConsumerRegistered(msg.sender);
    }

    function registerProvider() external {
        require(!providers[msg.sender].isRegistered, "Provider is already registered");

        providers[msg.sender] = Provider("", "", 0, true, false, msg.sender, new address[](0));
        emit ProviderRegistered(msg.sender);
    }

    function setIPFSHash(string memory hash) external onlyRegisteredConsumerOrProvider {
        if (consumers[msg.sender].isRegistered) {
            consumers[msg.sender].providerAddress = address(0);
        } else if (providers[msg.sender].isRegistered) {
            providers[msg.sender].isServiceAvailable = false;
        }
        emit ServiceRejected(msg.sender, consumers[msg.sender].consumerAddress, providers[msg.sender].serviceName);
    }

    function offerService(string memory serviceName, string memory features, uint256 price) external onlyRegisteredProvider {
        require(!providers[msg.sender].isServiceAvailable, "Provider has already offered a service");

        providers[msg.sender].serviceName = serviceName;
        providers[msg.sender].features = features;
        providers[msg.sender].price = price;
        providers[msg.sender].isServiceAvailable = true;
        emit ServiceOffered(msg.sender, serviceName, features, price);
    }

    function purchaseService(address providerAddress) external payable onlyRegisteredConsumer {
        Provider storage provider = providers[providerAddress];
        Consumer storage consumer = consumers[msg.sender];

        require(provider.isRegistered, "Provider is not registered");
        require(provider.isServiceAvailable, "Service is not available");
        require(!consumer.hasPurchased, "Consumer has already purchased a service");
        require(msg.value >= provider.price, "Insufficient payment");

        provider.consumers.push(msg.sender);
        consumer.providerAddress = providerAddress;
        consumer.hasPurchased = true;

        payable(providerAddress).transfer(msg.value);
        emit ServicePurchased(providerAddress, msg.sender, provider.serviceName, provider.price);
    }

    function acceptOffer(address consumerAddress) external onlyRegisteredProvider {
        Consumer storage consumer = consumers[consumerAddress];
        Provider storage provider = providers[msg.sender];

        require(consumer.isRegistered, "Consumer is not registered");
        require(provider.providerAddress == msg.sender, "Not authorized");

        if (consumer.hasPurchased) {
            provider.isServiceAvailable = false;
            emit ServiceRejected(msg.sender, consumerAddress, provider.serviceName);
        }
    }
}

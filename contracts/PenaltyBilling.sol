pragma solidity ^0.8.0;

import "./DecentralizedMarketplace.sol";
import "./ReverseAuction.sol";
import "./MonitorOracle.sol";

contract PenaltyBilling is DecentralizedMarketplace, ReverseAuction, MonitorOracle {
    uint256 public constant PENALTY_RATE = 0.005 * 10**18; // Penalty rate of 0.005 dollars

    mapping(address => uint256) public providerPenalties;
    mapping(address => SLA) public consumerSLAs;
    mapping(address => address) public providerToConsumer;

    struct SLA {
        uint256 breaches;
        // Add other properties of the SLA as needed
    }

   // modifier onlyAuthorized() {
        //require(
        //    consumers[msg.sender].isRegistered || providers[msg.sender].isRegistered,
       //     "Only authorized users can access this functionality"
      //  );
      //  _;
  //  }

    modifier onlyProvider() {
        require(providers[msg.sender].isRegistered, "Only providers can access this functionality");
        _;
    }

    modifier onlyConsumer() {
        require(consumers[msg.sender].isRegistered, "Only consumers can access this functionality");
        _;
    }

    function calculatePenalty(address _provider) internal view returns (uint256) {
        uint256 breaches = consumerSLAs[_provider].breaches;
        return breaches * PENALTY_RATE;
    }

    function getProviderPenalty(address _provider) external view returns (uint256) {
        return providerPenalties[_provider];
    }

    function askForFunds() external onlyProvider {
        address consumer = providerToConsumer[msg.sender];
        providerPenalties[msg.sender] = calculatePenalty(msg.sender);
        transferFunds(msg.sender, consumer, providerPenalties[msg.sender]);
    }

    function refundOption() external onlyProvider {
        address consumer = providerToConsumer[msg.sender];
        providerPenalties[msg.sender] = calculatePenalty(msg.sender);
        transferFunds(msg.sender, consumer, providerPenalties[msg.sender]);
    }

   // function sendButton() external onlyConsumer {
       // emit PaymentSent(msg.sender, msg.value);
    //}

    function askForRefund() external onlyConsumer {
        emit RefundRequested(msg.sender);
    }

    function transferFunds(address _from, address _to, uint256 _amount) private {
        emit FundsTransferred(_from, _to, _amount);
    }

    event PaymentSent(address indexed consumer, uint256 amount);
    event RefundRequested(address indexed consumer);
    event FundsTransferred(address indexed from, address indexed to, uint256 amount);
}

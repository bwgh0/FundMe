//SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;

    //Creates mapping to show who paid how much into the contract
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    //allows user to add $ to the contract and also adds to mapping
    function fund() public payable {
        //Checks to see if person sent $5 or more
        uint256 minimumUSD = 5 * (10**17);
        // 1 gWei is < $5
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You must spend more than $5"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        //Grab the ETH-USD rate from Chainlink Oracle
        funders.push(msg.sender);
    }

    //Gets version of Chainlink Aggregator interface on Rinkeby
    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    //Gets ETH-USD Price from Chainlink Aggregator Interface on Rinkeby
    function getPrice() public view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * (10**9));
    }

    //Returns 369722399011000000000
    //Gets Conversion rate from ETH amount
    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountUSD = (ethPrice * ethAmount) / (10**18);
        return ethAmountUSD;
    }

    //Gets Entrance Fee
    function getEntranceFee() public view returns (uint256) {
        // minimumUSD
        uint256 minimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (minimumUSD * precision) / price;
    }

    //Changes function in a declarative way
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    //Withdraws money sent to contract
    function withdraw() public payable onlyOwner {
        // only want the contract owner to be able to take funds
        //require (msg.sender = owner)
        msg.sender.transfer(address(this).balance);
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

// brownie doesn't know where to download the npm packages below
// so we tell brownie to download from github
// to do that, we create dependencies in brownie-config
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    using SafeMathChainlink for uint256;
    mapping(address => uint256) public addressToAmountFunded;

    address[] public funders;
    address public owner;
    AggregatorV3Interface public priceFeed;
    // constructors will be immediately executed upon contract deployment
    // here, we want to prevent anyone except the owner from calling withdraw()
    // so the constructor allows our(the owner) address to be 'fixed' at deployment such that
    // no other msg.sender can be the owner

    // there was some error here if i followed the video
    constructor(address _priceFeed) public {
       // priceFeed = AggresgatorV3Interface(_priceFeed);
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // function to accept payments
    function fund() public payable {
        // Set a minimum vaue of $50 worth of eth
        uint256 minimumUSD = 50 * (10**18);
        require(
            getConversionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH!"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        // want to accept other tokens as well
        // what the ETH -> USD conversion rate is
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface interacts with a contract address to get data from there.
        // In this case, we want to get eth/usd price, so we use that contract address listen on chainlink

        return priceFeed.version(); //version() is a function in AggregatorV3Interface.sol, which we imported
        //
    }

    function getPrice() public view returns (uint256) {

        (, int256 answer, , , ) = priceFeed.latestRoundData();
        return uint256(answer * 10000000000);
    }

    function getConversionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

        function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _; // execute the rest of the parent function if requirement is met
    }

    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);
        // the keyword 'this' refers to the contract we're currently in
        // therefore address(this) refers to current contract address
        // balance refers to the balance in eth of the contract
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        // the for loop resets all funders' funded amount
        // end of loop, clear out the funders array
    }
}

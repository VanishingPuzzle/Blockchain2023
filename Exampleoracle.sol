// SPDX-License-Identifier: MIT
// example oracle from chainlink we can use floor prices for mock up
// https://docs.chain.link/any-api/get-request/examples/single-word-response/ or something like this that returns constants for the mockup
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract NFTFloorPriceConsumerV3 {
    AggregatorV3Interface internal nftFloorPriceFeed;

    /**
     * Network: Goerli - No Sepolia feeds available at this time
     * Aggregator: CryptoPunks
     * Address: 0x5c13b249846540F81c093Bc342b5d963a7518145
     */
    constructor() {
        nftFloorPriceFeed = AggregatorV3Interface(
            0x5c13b249846540F81c093Bc342b5d963a7518145
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        // prettier-ignore
        (
            /*uint80 roundID*/,
            int nftFloorPrice,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = nftFloorPriceFeed.latestRoundData();
        return nftFloorPrice;
    }
}

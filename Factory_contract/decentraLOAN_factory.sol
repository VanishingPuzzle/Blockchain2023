// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./deployable_LAND_MARKT.sol"; // import the contract to create

contract MARKTdeployer {
    address[] public markets;
    uint256 public marketCounter;

    event MarketDeployed(address marketAddress);

    function deployMarkets(
        address _nftContract, 
        uint256 _BC, 
        uint256 _LT,
        uint256 _basket,
        uint256 _Uopt,
        uint256 _discount,
        uint256 _BI,
        string calldata _name,
        string calldata _ticker
    ) public  {
        LANDmarket market = new LANDmarket(
            _nftContract, 
            _BC, 
            _LT,
            _basket,
            _Uopt,
            _discount,
            _BI,
            _name,
            _ticker
        ); // deploy a new Land market
        markets.push(address(market));
        marketCounter += 1;
        emit MarketDeployed(address(market));
    }
}

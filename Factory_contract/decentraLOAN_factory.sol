// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./deployable_LAND_MARKT.sol"; // import the contract to create
import "@openzeppelin/contracts/utils/Strings.sol";

contract MARKTdeployer {
    using Strings for uint256;

    address[] public markets;
    uint256 public marketCounter;

    event MarketDeployed(address marketAddress);
// takes the parameters for the market policy
    function deployMarkets(
        address _nftContract, //address of the LAND NFT
        uint256 _BC, //as integers Ex. 9 = 90%
        uint256 _LT,
        uint256 _discount,
        uint256 _basket, //from 1 to 4
        uint256 _Uopt, //as bp Ex. 200 =2%
        uint256 _BI,
        uint256 _slope1,
        uint256 _slope2
    ) public  {
        marketCounter += 1; //Increase counter
        //Names the coin acording to the market number
        string memory _name = appendNumberToString("LENDCOIN", marketCounter);
        string memory _ticker = appendNumberToString("LND", marketCounter); 
         
        //Deploys the land market
        LANDmarket market = new LANDmarket(
            _nftContract, 
            _BC, 
            _LT,
            _basket,
            _Uopt,
            _discount,
            _BI,
            _slope1,
            _slope2,
            _name,
            _ticker
        ); 
        //puts the address in the 
        markets.push(address(market));
        emit MarketDeployed(address(market));
    }
    //For the numbering of the coins
    function appendNumberToString(string memory _str, uint256 _counter) internal pure returns (string memory) {
        return string(abi.encodePacked(_str, _counter.toString()));
    }
}

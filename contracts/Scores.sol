// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract CityOfGoldScores is Ownable {

    function getLandScore(uint tokenID) public view returns (uint score) {
        return block.timestamp % 170;
    }

}
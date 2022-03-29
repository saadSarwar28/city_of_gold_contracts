// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract CityOfGoldScores is Ownable {

    function getLandScore(uint tokenID) public view returns (uint score) {
        return 100;
    }

}
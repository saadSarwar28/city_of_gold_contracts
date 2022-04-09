// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract CityOfGoldScoresDummy is Ownable {

    mapping (uint => uint) public scores;

    constructor() {
        scores[1] = 70;
        scores[2] = 80;
        scores[3] = 90;
        scores[4] = 95;
        scores[5] = 88;
        scores[6] = 100;
        scores[7] = 105;
        scores[8] = 110;
        scores[9] = 118;
        scores[10] = 125;
        scores[11] = 120;
        scores[12] = 130;
        scores[13] = 150;
    }

    function getLandScore(uint tokenID) public view returns (uint score) {
        return scores[tokenID];
    }

    function setScore(uint tokenId, uint score) public onlyOwner{
        scores[tokenId] = score;
    }
}
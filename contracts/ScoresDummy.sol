// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IEstate  {
    function landIds(uint, uint) external view returns(uint);
}

contract CityOfGoldScoresDummy is Ownable {

    address public ESTATE;

    struct Tier {
        uint min;
        uint max;
        uint multiplier;
    }

    mapping (uint => Tier) public tierList;

    uint public totalTiers;

    constructor(address estate) {
        ESTATE = estate;
        totalTiers = 4;
        tierList[0] = Tier({
            min: 70,
            max: 90,
            multiplier: 1
        });
        tierList[1] = Tier({
            min: 91,
            max: 110,
            multiplier: 3
        });
        tierList[2] = Tier({
            min: 111,
            max: 130,
            multiplier: 5
        });
        tierList[3] = Tier({
            min: 131,
            max: 150,
            multiplier: 7
        });
    }

    function setEstateAddress(address estate) public onlyOwner {
        ESTATE = estate;
    }

    // be carefull , tiers shouldn't overlap
    function setTier(uint tierIndex, uint _min, uint _max, uint _multiplier) public onlyOwner {
        tierList[tierIndex] = Tier({
        min: _min,
        max: _max,
        multiplier: _multiplier
        });
    }

    function setTotalTiers(uint total) public onlyOwner {
        totalTiers = total;
    }

    function getEstateScore(uint tokenId) public view returns(uint score) {
        return getLandScore(IEstate(ESTATE).landIds(tokenId, 0)) + getLandScore(IEstate(ESTATE).landIds(tokenId, 1)) + getLandScore(IEstate(ESTATE).landIds(tokenId, 2));
    }

    function getTierMultiplier(uint tokenScore) public view returns (uint multiplier) {
        for (uint index = 0; index < totalTiers; index++) {
            Tier storage tier = tierList[index];
            if (tokenScore >= tier.min && tokenScore <= tier.max) {
                return tier.multiplier;
            }
        }
    }

    function getEstateMultiplier(uint tokenId) public view returns(uint score) {

        uint tokenScoreOne = getLandScore(IEstate(ESTATE).landIds(tokenId, 0));
        uint tokenScoreTwo = getLandScore(IEstate(ESTATE).landIds(tokenId, 1));
        uint tokenScoreThree = getLandScore(IEstate(ESTATE).landIds(tokenId, 2));

        uint multiplierOne = getTierMultiplier(tokenScoreOne);
        uint multiplierTwo = getTierMultiplier(tokenScoreTwo);
        uint multiplierThree = getTierMultiplier(tokenScoreThree);

        return (multiplierOne + multiplierTwo + multiplierThree) / 3;
    }

    function getLandScore(uint tokenId) public pure returns (uint256 score) {
        require(tokenId <= 10000 && tokenId > 0, "Invalid tokenId");
        return 100;
    }

}
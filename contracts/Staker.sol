// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";

interface ILandContract {
    function ownerOf(uint256 tokenId) external returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

interface IEstateContract {
    function ownerOf(uint256 tokenId) external returns (address);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function totalSupply() external view returns(uint);
}

interface ICogToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IScores {
    function getLandScore(uint tokenID) external view returns (uint score);
    function getEstateScore(uint tokenId) external view returns (uint score);
    function getEstateMultiplier(uint tokenId) external view returns (uint score);
}

contract CityOfGoldStaker is Ownable, ReentrancyGuard, IERC721Receiver {

    address public COG;
    address public LAND;
    address public ESTATE;
    address public SCORES;

    uint public COG_EMISSIONS_PER_DAY = 100;

    bool public CLAIM_REWARDS;

    uint public LOCKUP_PERIOD = 86400 * 50; // 50 days in seconds

    struct StakerInfo {
        address owner;
        uint stakedAt;
        uint lastRewardsClaimedAt;
    }

    // since token ids are unique so, creating a mapping with token ids instead of owner address
    mapping(uint => StakerInfo) public stakedLands;
    mapping(address => uint[]) public landBalances; // total balance of each address with land token ids
    mapping(address => uint) public totalLandsStaked; // convenience for frontend and to store in landBalance

    mapping(uint => StakerInfo) public stakedEstates;
    mapping(address => uint[]) public estateBalances;
    mapping(address => uint) public totalEstatesStaked;

    constructor (address cog, address land, address estate, address scores) {
        COG = cog;
        LAND = land;
        ESTATE = estate;
        SCORES = scores;
    }

    // for land
    modifier onlyLandMinter() {
        require(msg.sender == LAND, "Only the land minter contract can call this function.");
        _;
    }

    // estate contract is the estate minter.
    modifier onlyEstateMinter() {
        require(msg.sender == ESTATE, "Only the estate minter contract can call this function.");
        _;
    }

    function setLockupPeriod(uint lockTime) public onlyOwner {
        LOCKUP_PERIOD = lockTime;
    }

    function setCOGEmissions(uint _cogEmissionsPerDay) public onlyOwner {
        require(_cogEmissionsPerDay > 0, "Can't be zero");
        COG_EMISSIONS_PER_DAY = _cogEmissionsPerDay;
    }

    function setClaimRewards(bool claim) public onlyOwner {
        CLAIM_REWARDS = claim;
    }

    function setLand(address land) public onlyOwner {
        require(land != address(0), "Can't be a zero address");
        LAND = land;
    }

    function setEstate(address estate) public onlyOwner {
        require(estate != address(0), "Can't be a zero address");
        ESTATE = estate;
    }

    function setScores(address scores) public onlyOwner {
        require(scores != address(0), "Can't be a zero address");
        SCORES = scores;
    }

    function addLand(address owner, uint tokenId) private {
        landBalances[owner].push(tokenId);
        totalLandsStaked[owner] += 1;
    }

    function removeLand(address owner, uint tokenId) private {
        uint[] storage lands = landBalances[owner];
        for (uint index = 0; index < lands.length; index++) {
            if (lands[index] == tokenId) {
                lands[index] = 0;
            }
        }
        totalLandsStaked[owner] -= 1;
    }

    function checkLandOwner(address owner, uint tokenId) public view returns(bool answer) {
        uint[] storage lands = landBalances[owner];
        for (uint index = 0; index < lands.length; index++) {
            if (lands[index] == tokenId) {
                return true;
            }
        }
        return false;
    }

    // land balances will have some zeros because of the deletion. for view only
    function returnAllLandsOfOwner(address owner) public view returns(uint[] memory _totalLandsStaked) {
        uint[] storage lands = landBalances[owner];
        uint[] memory ownedLands = new uint[](totalLandsStaked[owner]);
        uint ownedLandsIndex= 0;
        for (uint index = 0; index < lands.length; index++) {
            if (lands[index] != 0) {
                ownedLands[ownedLandsIndex] = lands[index];
                ownedLandsIndex += 1;
            }
        }
        return ownedLands;
    }

    function addEstate(address owner, uint tokenId) private {
        estateBalances[owner].push(tokenId);
        totalEstatesStaked[owner] += 1;
    }

    function removeEstate(address owner, uint tokenId) private {
        uint[] storage estates = estateBalances[owner];
        for (uint index = 0; index < estates.length; index++) {
            if (estates[index] == tokenId) {
                estates[index] = 0;
            }
        }
        totalEstatesStaked[owner] -= 1;
    }

    function checkEstateOwner(address owner, uint tokenId) public view returns(bool answer) {
        uint[] storage estates = estateBalances[owner];
        for (uint index = 0; index < estates.length; index++) {
            if (estates[index] == tokenId) {
                return true;
            }
        }
        return false;
    }

    // balances will have some zeros because of the deletion. for view only
    function returnAllEstatesOfOwner(address owner) public view returns(uint[] memory _totalEstatesStaked) {
        uint[] storage estates = estateBalances[owner];
        uint[] memory ownedEstates = new uint[](totalEstatesStaked[owner]);
        uint ownedEstatesIndex= 0;
        for (uint index = 0; index < estates.length; index++) {
            if (estates[index] != 0) {
                ownedEstates[ownedEstatesIndex] = estates[index];
                ownedEstatesIndex += 1;
            }
        }
        return ownedEstates;
    }

    // for manual staking after mint
    function stakeLand(uint[] memory tokenIds) public nonReentrant returns (bool success) {
        for (uint index = 0; index < tokenIds.length; index++) {
            require(tokenIds[index] > 0 && tokenIds[index] <= 10000, "Invalid token id");
            require(ILandContract(LAND).ownerOf(tokenIds[index]) == msg.sender, "Not your Token");
            require(stakedLands[tokenIds[index]].stakedAt == 0, "Token already staked");
            ILandContract(LAND).transferFrom(msg.sender, address(this), tokenIds[index]);
            stakedLands[tokenIds[index]] =
            StakerInfo({
                owner : msg.sender,
                stakedAt : block.timestamp,
                lastRewardsClaimedAt : 0
            });
            addLand(msg.sender, tokenIds[index]);
        }
        return true;
    }

    // stake directly from mint
    function stakeLandFromMinter(uint[] memory tokenIds, address _owner) public onlyLandMinter returns(bool success){
        for (uint index = 0; index < tokenIds.length; index++) {
            stakedLands[tokenIds[index]] =
            StakerInfo({
                owner : _owner,
                stakedAt : block.timestamp,
                lastRewardsClaimedAt : 0
            });
            addLand(_owner, tokenIds[index]);
        }
        return true;
    }

    // unstake all lands or one by one
    function unStakeLand(uint[] memory tokenIds) public nonReentrant returns (bool result) {
        for (uint index = 0; index < tokenIds.length; index++) {
            require(checkLandOwner(msg.sender, tokenIds[index]), "No tokens staked");
            StakerInfo storage stakerInfo = stakedLands[tokenIds[index]];
            if (CLAIM_REWARDS && (block.timestamp - stakerInfo.stakedAt) > LOCKUP_PERIOD) {
                distributeCOG(calculateTokenDistributionForLand(tokenIds[index]), stakerInfo.owner);
            }
            ILandContract(LAND).transferFrom(address(this), stakerInfo.owner, tokenIds[index]);
            stakerInfo.owner = address(0);
            stakerInfo.stakedAt = 0;
            stakerInfo.lastRewardsClaimedAt = block.timestamp;
            removeLand(msg.sender, tokenIds[index]);
        }
        return true;
    }

    function claimLandRewards(uint[] memory tokenIds) public nonReentrant returns (bool success) {
        require(CLAIM_REWARDS, "Rewards distribution not started yet");
        require(landBalances[msg.sender].length > 0, "No tokens staked");
        for (uint index = 0; index < tokenIds.length; index++) {
            require(checkLandOwner(msg.sender, tokenIds[index]), "Not staked");
            StakerInfo storage stakerInfo = stakedLands[tokenIds[index]];
            require((block.timestamp - stakerInfo.stakedAt) > LOCKUP_PERIOD, "Lockup period not expired yet.");
            distributeCOG(calculateTokenDistributionForLand(tokenIds[index]), msg.sender);
            stakerInfo.lastRewardsClaimedAt = block.timestamp;
        }
        return true;
    }

    // for estate token
    function stakeEstate(uint[] memory tokenIds) public nonReentrant returns (bool result) {
        for (uint index = 0; index < tokenIds.length; index++) {
            require(tokenIds[index] > 0 && tokenIds[index] <= IEstateContract(ESTATE).totalSupply(), "Invalid token id");
            require(IEstateContract(ESTATE).ownerOf(tokenIds[index]) == msg.sender, "Token not your");
            require(stakedEstates[tokenIds[index]].stakedAt == 0, "Token already staked");
            IEstateContract(ESTATE).transferFrom(msg.sender, address(this), tokenIds[index]);
            stakedEstates[tokenIds[index]] =
            StakerInfo({
                owner : msg.sender,
                stakedAt : block.timestamp,
                lastRewardsClaimedAt : 0
            });
            addEstate(msg.sender, tokenIds[index]);
        }
        return true;
    }

    function stakeEstateFromMinter(uint tokenId, address _owner) public onlyEstateMinter returns(bool) {
        stakedEstates[tokenId] =
        StakerInfo({
            owner : _owner,
            stakedAt : block.timestamp,
            lastRewardsClaimedAt : 0
        });
        addEstate(_owner, tokenId);
        return true;
    }

    function unStakeEstate(uint[] memory tokenIds) public nonReentrant returns (bool result) {
        for (uint index = 0; index < tokenIds.length; index++) {
            require(checkEstateOwner(msg.sender, tokenIds[index]), "No tokens staked");
            StakerInfo storage stakerInfo = stakedEstates[tokenIds[index]];
            if (CLAIM_REWARDS && (block.timestamp - stakerInfo.stakedAt) > LOCKUP_PERIOD) {
                distributeCOG(calculateTokenDistributionForEstate(tokenIds[index]), stakerInfo.owner);
            }
            IEstateContract(ESTATE).transferFrom(address(this), stakerInfo.owner, tokenIds[index]);
            stakerInfo.owner = address(0);
            stakerInfo.stakedAt = 0;
            stakerInfo.lastRewardsClaimedAt = 0;
            removeEstate(msg.sender, tokenIds[index]);
        }
        return true;
    }

    function claimEstateRewards(uint[] memory tokenIds) public nonReentrant returns (bool) {
        require(CLAIM_REWARDS, "Rewards distribution not started yet");
        require(estateBalances[msg.sender].length > 0, "No tokens staked");
        for (uint index = 0; index < tokenIds.length; index++) {
            require(checkEstateOwner(msg.sender, tokenIds[index]), "Not staked");
            StakerInfo storage stakerInfo = stakedEstates[tokenIds[index]];
            require((block.timestamp - stakerInfo.stakedAt) > LOCKUP_PERIOD, "Lockup period not expired yet.");
            distributeCOG(calculateTokenDistributionForEstate(tokenIds[index]), msg.sender);
            stakerInfo.lastRewardsClaimedAt = block.timestamp;
        }
        return true;
    }

    // emergency withdrawal function
    function withdrawCOG(uint _amount) public onlyOwner {
        ICogToken(COG).transfer(msg.sender, _amount);
    }

    function distributeCOG(uint amount, address to) internal {
        ICogToken(COG).transfer(to, amount);
    }

    function calculateTokenDistributionForLand(uint tokenId) public view returns(uint amountToDistribute) {

        StakerInfo storage stakerInfo = stakedLands[tokenId];
        require(stakerInfo.owner == msg.sender, "Not your token");
        require(stakerInfo.stakedAt > 0, "Not staked yet");

        uint countRewardsFrom = stakerInfo.lastRewardsClaimedAt > 0 ? stakerInfo.lastRewardsClaimedAt : stakerInfo.stakedAt;

        uint landScore = IScores(SCORES).getLandScore(tokenId);
        uint tokensPerDay = (COG_EMISSIONS_PER_DAY / 100) * landScore;
        uint tokensPerSecond = (tokensPerDay * 10**18) / 86400; // raising power of tokens per day to divide by a larger denominator
        uint stakeTimeInSeconds = block.timestamp - countRewardsFrom;
        return tokensPerSecond * stakeTimeInSeconds;
    }

    // to calculate total cog earning, for view only, not to be used inside write functions
    function calculateTotalCogEarning(bool isLand) public view returns(uint amount) {
        uint totalTokens = 0;
        if (isLand) {
            for (uint index = 0; index < landBalances[msg.sender].length; index++) {
                if (landBalances[msg.sender][index] != 0) {
                    totalTokens += calculateTokenDistributionForLand(landBalances[msg.sender][index]);
                }
            }
        } else  {
            for (uint index = 0; index < estateBalances[msg.sender].length; index++) {
                if (estateBalances[msg.sender][index] != 0) {
                    totalTokens += calculateTokenDistributionForEstate(estateBalances[msg.sender][index]);
                }
            }
        }
        return totalTokens;
    }

    function calculateTokenDistributionForEstate(uint estateId) public view returns(uint amountToDistribute) {

        StakerInfo storage stakerInfo = stakedEstates[estateId];
        require(stakerInfo.owner == msg.sender, "Not your token");
        require(stakerInfo.stakedAt > 0, "Not staked yet");

        uint countRewardsFrom = stakerInfo.lastRewardsClaimedAt > 0 ? stakerInfo.lastRewardsClaimedAt : stakerInfo.stakedAt;

        uint estateScore = IScores(SCORES).getEstateScore(estateId);
        uint multiplier = IScores(SCORES).getEstateMultiplier(estateId);

        uint cogDistributionPerDay = (COG_EMISSIONS_PER_DAY / 100) * estateScore;
        uint tokensPerSecond = (cogDistributionPerDay * 10**18) / 86400; // raising power of tokens per day to divide by a larger denominator
        uint stakeTimeInSeconds = block.timestamp - countRewardsFrom;
        uint tokensToDistribute = stakeTimeInSeconds * tokensPerSecond;
        // multiplier is supposed to be 1.multiplier
        uint multiplierAmount = (tokensToDistribute / 10) * multiplier;
        return tokensToDistribute + multiplierAmount;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
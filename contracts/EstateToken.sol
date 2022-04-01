// SPDX-License-Identifier: MIT

/**
 * @title city of gold Estate nfts
 * @author Saad Sarwar
 */


pragma solidity ^0.8.4;


import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";


interface IStakerContract {
    function stakeEstateFromMinter(uint tokenId, address _owner) external returns(bool);
}

interface ILandContract {
    function ownerOf(uint tokenId) external returns(address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function burn(uint256 tokenId) external;
}

interface IScores {
    function getLandScore(uint tokenID) external view returns (uint score);
}

contract cityOfGoldEstate is ERC721Enumerable, Ownable, IERC721Receiver {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address public STAKER;

    address public LAND;

    address public SCORES;

    struct ScoreSlab{
        uint min;
        uint max;
        uint multiplier;
    }

    mapping(uint => ScoreSlab) public scoreSlabs; // scoring slabs to calculate multiplier

    uint public SLABS_NUMBER; // number of scoring slabs , helps iterate to all score slabs

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base Token URI
    string public baseTokenURI;

    // mapping for estate token id to the land token ids burned to make the estate
    mapping (uint => uint[]) public landIds;

    // mapping for estate multiplier
    mapping (uint => uint) public estateMultiplier;

    constructor(address staker, address land) ERC721("City Of Gold ESTATE", "ESTATE") {
        LAND = land;
        STAKER = staker;
    }

    function setScoreSlabs(uint num, uint _min, uint _max, uint _multiplier) public onlyOwner {
        scoreSlabs[num] = ScoreSlab({
        min: _min,
        max: _max,
        multiplier: _multiplier
        });
    }

    function setScoreSlabsNum(uint num) public onlyOwner {
        SLABS_NUMBER = num;
    }

    function setStakerAddress(address staker) public onlyOwner {
        require(staker != address(0), "Cannot be a zero address");
        STAKER = staker;
    }

    function setLandAddress(address land) public onlyOwner() {
        require(land != address(0), "Cannot be a zero address");
        LAND = land;
    }

    function setScoresAddress(address scores) public onlyOwner() {
        require(scores != address(0), "Cannot be a zero address");
        SCORES = scores;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseTokenURI = _newBaseURI;
    }

    // fallback  function to set a particular token uri manually if something incorrect in one of the metadata files
    function setTokenURI(uint tokenID, string memory uri) public onlyOwner() {
        require(ERC721._exists(tokenID), "Uri query for non existent token");
        _tokenURIs[tokenID] = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(ERC721._exists(tokenId), "Uri query for non existent token");
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            return _tokenURIs[tokenId];
        }
        return string(abi.encodePacked(baseTokenURI, Strings.toString(tokenId)));
    }

    function burnLands(uint[] memory tokenIds) internal {
        for (uint index = 0; index < tokenIds.length; index++) {
            ILandContract(LAND).transferFrom(msg.sender, address(this), tokenIds[index]);
            ILandContract(LAND).burn(tokenIds[index]);
        }
    }

    function mint(uint[] memory tokenIds, bool stake) public {
        require(tokenIds.length == 3, "Three land tokens required to make an estate");
        require((tokenIds[0] + 1) == tokenIds[1] && (tokenIds[1] + 1) == tokenIds[2], "Land tokens should be consecutive");
        burnLands(tokenIds);
        _tokenIds.increment();
        uint256 newEstateId = _tokenIds.current();
        if (stake) {
            _safeMint(STAKER, newEstateId);
            landIds[newEstateId] = tokenIds;
            require(IStakerContract(STAKER).stakeEstateFromMinter(newEstateId, msg.sender), "Staking failure");
        } else {
            _safeMint(msg.sender, newEstateId);
        }
        setMultiplier(newEstateId, calculateMultiplier(tokenIds));
    }

    // get total score of a estate
    function getScore(uint256 tokenId) public view returns(uint score) {
        uint[] storage _landIds = landIds[tokenId];
        return IScores(SCORES).getLandScore(_landIds[0]) + IScores(SCORES).getLandScore(_landIds[1]) + IScores(SCORES).getLandScore(_landIds[2]);
    }

    // get multiplier of a estate
    function getMultiplier(uint256 tokenId) public view returns(uint multiplier) {
        return estateMultiplier[tokenId];
    }

    function findScoreSlab(uint score) public view returns(uint slabMultiplier) {
        for (uint index = 1; index <= SLABS_NUMBER; index++) {
            ScoreSlab storage slab = scoreSlabs[index];
            if (score >= slab.min && score <= slab.max) {
                return slab.multiplier;
            }
        }
    }

    //estate multiplier is the avg of scores of all three corresponding land slab multipliers.
    function calculateMultiplier(uint[] memory _landIds) public view returns(uint multiplier) {
        uint scoreOne = findScoreSlab(IScores(SCORES).getLandScore(_landIds[0]));
        uint scoreTwo = findScoreSlab(IScores(SCORES).getLandScore(_landIds[1]));
        uint scoreThree = findScoreSlab(IScores(SCORES).getLandScore(_landIds[2]));
        return ((scoreOne + scoreTwo + scoreThree) / 3);
    }

    function setMultiplier(uint estateId, uint multiplier) public onlyOwner {
        estateMultiplier[estateId] = multiplier;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
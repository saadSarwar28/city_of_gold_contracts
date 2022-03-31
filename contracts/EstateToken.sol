// SPDX-License-Identifier: MIT

/**
 * @title city of gold Land nfts
 * @author Saad Sarwar
 */


pragma solidity ^0.8.4;

// import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";

interface IStakerContract {
    function stakeEstateFromMinter(uint tokenId, address _owner) external returns(bool);
}

interface ILandContract {
    function ownerOf(uint tokenId) external returns(address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract cityOfGoldEstate is ERC721Enumerable, Ownable {

    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bool public saleIsActive = false; // to control sale

    address public STAKER;

    address public LAND;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Base Token URI
    string public baseTokenURI;

    // mapping for estate token id to the land token ids burned to make the estate
    mapping (uint => uint[]) public landIds;

    constructor(address staker, address land) ERC721("City Of Gold ESTATE", "ESTATE") {
        LAND = land;
        STAKER = staker;
    }

    function setStakerAddress(address staker) public onlyOwner {
        require(staker != address(0), "Cannot be a zero address");
        STAKER = staker;
    }

    function setLandAddress(address land) public onlyOwner() {
        require(land != address(0), "Cannot be a zero address");
        LAND = land;
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
        return string(abi.encodePacked(baseTokenURI, tokenId.toString(), ".json"));
    }

    // function totalSupply() public view returns (uint256) {
    //     return _tokenIds.current();
    // }

    /*
    * for public sale
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function burnLands(uint[] memory tokenIds) internal {
        for (uint index = 0; index < tokenIds.length; index++) {
            ILandContract(LAND).transferFrom(msg.sender, address(0), tokenIds[index]);
        }
    }

    function mint(uint[] memory tokenIds, bool stake) public {
        require(tokenIds.length == 3, "Three land tokens required to make an estate");
        require((tokenIds[0] + 1) == tokenIds[1] && (tokenIds[1] + 1) == tokenIds[2], "Land tokens should be consecutive");
        burnLands(tokenIds);
        if (stake) {
            _tokenIds.increment();
            uint256 newNftId = _tokenIds.current();
            _safeMint(STAKER, newNftId);
            landIds[newNftId] = tokenIds;
            require(IStakerContract(STAKER).stakeEstateFromMinter(newNftId, msg.sender), "Staking failure");
        } else {
            _tokenIds.increment();
            uint256 newNftId = _tokenIds.current();
            _safeMint(msg.sender, newNftId);
        }
    }
}
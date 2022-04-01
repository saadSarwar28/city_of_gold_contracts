// SPDX-License-Identifier: MIT

/**
 * @title city of gold Land nfts
 * @author Saad Sarwar
 */


pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";

interface IStakerContract {
    function stakeLandFromMinter(uint[] memory tokenIds, address _owner) external returns(bool success);
}

contract cityOfGoldLand is ERC721Enumerable, Ownable {

    uint256 public nftPrice;

    uint public whitelistPrice;

    string public PROVENANCE_HASH = "";

    bytes32 public merkleRoot;

    mapping(address => bool) public whitelistClaimed;

    uint256 public MAX_SUPPLY; // max supply of nfts

    bool public whiteListActive = false; // for white listed addressess sale

    bool public saleIsActive = false; // to control public sale

    address payable public treasury;

    address public STAKER;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Token URI
    string public baseTokenURI;

    event NftMinted(address to, uint date, uint tokenId, string tokenURI); // Used to generate NFT data on external decentralized storage service

    constructor(uint256 maxNftSupply, address payable _treasury, uint publicSalePrice, uint _whiteListPrice) ERC721("City Of Gold LAND", "LAND") {
        MAX_SUPPLY = maxNftSupply;
        treasury = _treasury;
        nftPrice = publicSalePrice;
        whitelistPrice = _whiteListPrice;
    }

    function setStakerAddress(address staker) public onlyOwner {
        require(staker != address(0), "Cannot be a zero address");
        STAKER = staker;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner() {
        PROVENANCE_HASH = provenanceHash;
    }

    function setSalePrice(uint price) public onlyOwner() {
        require(price > 0, "Cannot be zero");
        nftPrice = price;
    }

    function changeTreasuryAddress(address payable _newTreasuryAddress) public onlyOwner() {
        require(_newTreasuryAddress != address(0), "cannot be a zero address");
        treasury = _newTreasuryAddress;
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

    /*
    * for public sale
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * for whitelist sale
    */
    function flipWhitelistSaleState() public onlyOwner {
        whiteListActive = !whiteListActive;
    }

    function whitelistMint(bytes32[] calldata _merkleProof, bool stake) public payable {
        require(whiteListActive, "Whitelist sale is not active yet.");
        require(whitelistPrice > 0, "Whitelist price not set yet");
        require((totalSupply() + 1) <= MAX_SUPPLY, "Purchase would exceed max supply of NFTs");
        require(msg.value >= whitelistPrice, "Not enough balance");
        require(!whitelistClaimed[msg.sender], "Address has already claimed");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof");
        whitelistClaimed[msg.sender] = true;
        treasury.transfer(msg.value);
        uint256 newNftId = totalSupply() + 1;
        if (stake) {
            _safeMint(STAKER, newNftId);
            uint[] memory tokenIds = new uint[](1);
            tokenIds[0] = newNftId;
            require(IStakerContract(STAKER).stakeLandFromMinter(tokenIds, msg.sender), "Staking failure");
        }  else {
            _safeMint(msg.sender, newNftId);
        }
    }

    // the default mint function for public sale
    function publicMint(uint amount, bool stake) public payable {
        require(amount > 0 && amount < 5, "Cannot be more than five");
        require(nftPrice > 0, "NFT price not set yet");
        require(treasury != address(0), "Treasury address not set yet");
        require(saleIsActive, "Sale must be active to mint nft");
        require((totalSupply() + amount) <= MAX_SUPPLY, "Purchase would exceed max supply of NFTs");
        require(msg.value >= (nftPrice * amount), "Not enough balance");
        treasury.transfer(msg.value);
        if (stake) {
            uint[] memory tokenIds = new uint[](amount);
            for (uint index = 0; index < amount; index++) {
                uint256 newLandId = totalSupply() + 1;
                _safeMint(STAKER, newLandId);
                tokenIds[index] = newLandId;
            }
            require(IStakerContract(STAKER).stakeLandFromMinter(tokenIds, msg.sender), "Staking failure");
        } else {
            for (uint index = 0; index < amount; index++) {
                uint256 newLandId = totalSupply() + 1;
                _safeMint(msg.sender, newLandId);
            }
        }
    }

    // mint for function to mint an nft for a given address, can be called only by owner
    function mintFor(address _to) public onlyOwner() {
        require((totalSupply() + 1) <= MAX_SUPPLY, "Purchase would exceed max supply of NFTs");
        uint256 newNftId = totalSupply() + 1;
        _safeMint(_to, newNftId);
    }

    // mass minting function, one for each address
    function massMint(address[] memory addresses) public onlyOwner() {
        uint index;
        for (index = 0; index < addresses.length; index++) {
            mintFor(addresses[index]);
        }
    }

    // additional burn function
    function burn(uint256 tokenId) public {
        require(ERC721._exists(tokenId), "burning non existent token");
        require(ERC721.ownerOf(tokenId) == msg.sender, "Not your token");
        _burn(tokenId);
    }
}
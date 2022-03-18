// SPDX-License-Identifier: MIT

/**
 * @title CloserLookNFT
 * @author Saad Sarwar
 */


pragma solidity ^0.8.4;
import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/utils/Counters.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";

contract CloserLookNFT is ERC721, Ownable {
    //    using SafeMath for uint256;
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public nftPrice;
    bool isNftPriceSet = false;

    string public PROVENANCE_HASH = "";

    uint256 public PROVENANCE_HASH_TIMESTAMP; // time when provenance hash was set

    bytes32 public merkleRoot;

    mapping(address => bool) public whitelistClaimed;

    uint256 public MAX_SUPPLY; // max supply of nfts

    uint public MAX_WHITELIST;

    bool public preMintActive = false; // for private premint sale

    bool public whiteListActive = false; // for white listed addressess sale

    bool public saleIsActive = false; // to control public sale

    uint256 public startingIndexBlock;

    uint256 public startingIndex;

    address payable public treasury;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Token URI
    string public baseTokenURI;

    // default URI , before revealing the images or when baseURI is not set
    string public defaultURI = "ipfs://QmZYkpDfirLHWqNn9fkPqydB8dqBh836xbkNfpKuLJS56m";

    event NftMinted(address to, uint date, uint tokenId, string tokenURI); // Used to generate NFT data on external decentralized storage service

    constructor(uint256 maxNftSupply, address payable _treasury) ERC721("CloserLookNFT", "CLK") {
        MAX_SUPPLY = maxNftSupply;
        treasury = _treasury;
    }

    function setDefaultURI(string memory _defaultURI) public onlyOwner() {
        defaultURI = _defaultURI;
    }

    function setMaxWhitelist(uint max) public onlyOwner() {
        MAX_WHITELIST = max;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner() {
        require(PROVENANCE_HASH_TIMESTAMP == 0, "Provenance hash already been set");
        PROVENANCE_HASH_TIMESTAMP = block.timestamp;
        PROVENANCE_HASH = provenanceHash;
    }

    function setSalePrice(uint price) public onlyOwner() {
        nftPrice = price;
        isNftPriceSet = true;
    }

    function changeTreasuryAddress(address payable _newTreasuryAddress) public onlyOwner() {
        require(_newTreasuryAddress != address(0), "cannot be a zero address");
        treasury = _newTreasuryAddress;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseTokenURI = _newBaseURI;
    }

    function setTokenURI(uint tokenID, string memory uri) public onlyOwner() {
        _tokenURIs[tokenID] = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        // if token uri is set manually, for first 10 tokens
        bytes memory tokenURIString = bytes(_tokenURIs[tokenId]);
        if (tokenURIString.length != 0) {
            return _tokenURIs[tokenId];
        }

        // return default hidden address if base URI is not set yet.
        bytes memory baseUriTest = bytes(_baseURI());
        if (baseUriTest.length == 0) {
            return defaultURI;
        }

        uint256 newTokenID = tokenId + startingIndex;
        if (newTokenID > totalSupply()) {
            newTokenID = newTokenID - totalSupply();
        }
        return string(abi.encodePacked(baseTokenURI, newTokenID.toString()));

    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    /*
    * for public sale
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    /*
    * for premint private sale
    */
    function flipPremintSaleState() public onlyOwner {
        preMintActive = !preMintActive;
    }

    /*
    * for whitelist sale
    */
    function flipWhitelistSaleState() public onlyOwner {
        whiteListActive = !whiteListActive;
    }

    function whitelistMint(bytes32[] calldata _merkleProof) public payable {
        require(whiteListActive, "Whitelist sale is not active yet.");
        require(isNftPriceSet, "NFT price not set yet");
        require(MAX_WHITELIST != 0, "Max number of addresses for whitelist not set yet");
        require((totalSupply() - 10) <= MAX_WHITELIST, "Purchase would exceed max supply of NFTs for whitelist");
        require(msg.value >= nftPrice, "Not enough balance");
        require(!whitelistClaimed[msg.sender], "Address has already claimed");
        require(merkleRoot.length > 0, "Merkle Root not defined yet");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof");
        whitelistClaimed[msg.sender] = true;
        treasury.transfer(msg.value);
        _tokenIds.increment();
        uint256 newNftId = _tokenIds.current();
        _safeMint(msg.sender, newNftId);
        emit NftMinted(msg.sender, block.timestamp, newNftId, tokenURI(newNftId));
    }

    // the default mint function for public sale
    function publicMint(uint nftsToMint) public payable {
        require(isNftPriceSet, "NFT price not set yet");
        require(treasury != address(0), "Treasury address not set yet");
        require(saleIsActive, "Sale must be active to mint nft");
        require(msg.value >= nftPrice * nftsToMint, "Not enough balance");
        treasury.transfer(msg.value);
        for (uint index = 0; index < nftsToMint; index++) {
            require((totalSupply() + 1) <= MAX_SUPPLY, "Purchase would exceed max supply of NFTs");
            _tokenIds.increment();
            uint256 newNftId = _tokenIds.current();
            _safeMint(msg.sender, newNftId);
            emit NftMinted(msg.sender, block.timestamp, newNftId, tokenURI(newNftId));
            if (_tokenIds.current() == MAX_SUPPLY) {
                startingIndexBlock = block.number;
                break;
            }
        }
    }

    // mint for function to mint an nft for a given address, for private premint sale
    function mintFor(address _to) public onlyOwner() {
        require(preMintActive, "Premint sale must be active to mint nft");
        _tokenIds.increment();
        uint256 newNftId = _tokenIds.current();
        _safeMint(_to, newNftId);
        emit NftMinted(msg.sender, block.timestamp, newNftId, tokenURI(newNftId));
    }

}
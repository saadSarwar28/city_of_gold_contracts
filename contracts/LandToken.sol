// SPDX-License-Identifier: MIT

/**
 * @title city of gold Land nfts
 */


pragma solidity ^0.8.4;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/utils/cryptography/MerkleProof.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";


interface IStakerContract {
    function stakeLandFromMinter(uint[] memory tokenIds, address _owner) external returns(bool success);
}

contract CityOfGoldLand is ERC721Enumerable, Ownable, ReentrancyGuard {

    uint public TOKEN_ID = 0; // starts from one

    uint256 public nftPrice;

    uint public whitelistPrice;

    string public PROVENANCE_HASH = "";

    uint public STARTING_INDEX;

    bytes32 public merkleRoot;

    uint public MAX_PER_WALLET;

    uint public ALLOCATED_FOR_TEAM;

    uint public TEAM_COUNT;

    mapping(address => uint) public whitelistClaimed;

    uint256 public MAX_SUPPLY; // max supply of nfts

    bool public whiteListActive = false; // for white listed addressess sale

    bool public saleIsActive = false; // to control public sale

    address payable public treasury;

    address public STAKER;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    // Token URI
    string public baseTokenURI;

    constructor(
        uint256 maxNftSupply,
        address payable _treasury,
        uint publicSalePrice,
        uint _whiteListPrice,
        uint maxPerWallet,
        uint allocatedForTeam
    ) ERC721("City Of Gold LAND", "LAND") {
        MAX_SUPPLY = maxNftSupply;
        treasury = _treasury;
        nftPrice = publicSalePrice;
        whitelistPrice = _whiteListPrice;
        MAX_PER_WALLET = maxPerWallet;
        ALLOCATED_FOR_TEAM = allocatedForTeam;
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setStakerAddress(address staker) public onlyOwner {
        STAKER = staker;
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner() {
        PROVENANCE_HASH = provenanceHash;
    }

    function setSalePrice(uint price) public onlyOwner() {
        nftPrice = price;
    }

    function changeTreasuryAddress(address payable _newTreasuryAddress) public onlyOwner() {
        treasury = _newTreasuryAddress;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner() {
        baseTokenURI = _newBaseURI;
    }

    // function to set a particular token uri manually if something incorrect in one of the metadata files
    function setTokenURI(uint tokenID, string memory uri) public onlyOwner() {
        _tokenURIs[tokenID] = uri;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            return _tokenURIs[tokenId];
        }
        uint _tokenId = tokenId + STARTING_INDEX;
        if (_tokenId > MAX_SUPPLY) {
            _tokenId = _tokenId - MAX_SUPPLY;
        }
        return string(abi.encodePacked(baseTokenURI, Strings.toString(_tokenId)));
    }

    /*
    * for public sale
    */
    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }

    function setMaxPerWallet(uint maxPerWallet) public onlyOwner {
        MAX_PER_WALLET = maxPerWallet;
    }

    /*
    * for whitelist sale
    */
    function flipWhitelistSaleState() public onlyOwner {
        whiteListActive = !whiteListActive;
    }

    function whitelistMint(bytes32[] calldata _merkleProof, bool stake, uint amount) public payable nonReentrant {
        require(whiteListActive && whitelistPrice > 0, "Whitelist not active yet.");
        require((TOKEN_ID + amount) <= MAX_SUPPLY && (whitelistClaimed[msg.sender] + amount) < 10, "Mint exceeds limits");
        require(msg.value >= whitelistPrice, "Not enough balance");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Proof");
        treasury.transfer(msg.value);
        if (stake) {
            uint[] memory tokenIds = new uint[](amount);
            for (uint index = 0; index < amount; index++) {
                whitelistClaimed[msg.sender] += 1;
                TOKEN_ID += 1;
                _safeMint(STAKER, TOKEN_ID);
                tokenIds[index] = TOKEN_ID;
            }
            require(IStakerContract(STAKER).stakeLandFromMinter(tokenIds, msg.sender), "Staking failure");
        } else {
            for (uint index = 0; index < amount; index++) {
                whitelistClaimed[msg.sender] += 1;
                TOKEN_ID += 1;
                _safeMint(msg.sender, TOKEN_ID);
            }
        }
        if (TOKEN_ID == MAX_SUPPLY) {
            setStartingIndex();
        }
    }

    // the default mint function for public sale
    function publicMint(uint amount, bool stake) public payable nonReentrant {
        require(amount > 0 && amount <= MAX_PER_WALLET, "Invalid Amount");
        require(saleIsActive && nftPrice > 0 && treasury != address(0), "Config not done yet");
        require((TOKEN_ID + amount) <= MAX_SUPPLY, "Mint exceeds limits");
        require(msg.value >= (nftPrice * amount), "Not enough balance");
        treasury.transfer(msg.value);
        if (stake) {
            uint[] memory tokenIds = new uint[](amount);
            for (uint index = 0; index < amount; index++) {
                TOKEN_ID += 1;
                _safeMint(STAKER, TOKEN_ID);
                tokenIds[index] = TOKEN_ID;
            }
            require(IStakerContract(STAKER).stakeLandFromMinter(tokenIds, msg.sender), "Staking failure");
        } else {
            for (uint index = 0; index < amount; index++) {
                TOKEN_ID += 1;
                _safeMint(msg.sender, TOKEN_ID);
            }
        }
        if (TOKEN_ID == MAX_SUPPLY) {
            setStartingIndex();
        }
    }

    function setStartingIndex() private {
        STARTING_INDEX = block.timestamp % MAX_SUPPLY;
    }

    // for emergency reveal
    function setStartingIndexEmergency() public onlyOwner {
        require(STARTING_INDEX  == 0, "Already set");
        STARTING_INDEX = block.timestamp % MAX_SUPPLY;
    }

    // mass minting function, one for each address
    function massMint(address[] memory addresses) public onlyOwner() {
        for (uint index = 0; index < addresses.length; index++) {
            require(TEAM_COUNT < ALLOCATED_FOR_TEAM && (TOKEN_ID + 1) <= MAX_SUPPLY, "Amount exceeds allocation");
            TOKEN_ID += 1;
            _safeMint(addresses[index], TOKEN_ID);
            TEAM_COUNT += 1;
        }
    }

    // additional burn function
    function burn(uint256 tokenId) public {
        require(ERC721._exists(tokenId), "burning non existent token");
        require(ERC721.ownerOf(tokenId) == msg.sender, "Not your token");
        _burn(tokenId);
    }
}
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import "openzeppelin-solidity/contracts/access/Ownable.sol";


contract CityOfGold is ERC20, Ownable {

    uint public MAX_SUPPLY;

    address public MINTER;

    address public AUTHENTICATOR;

    uint public CURRENT_MINT_ID;

    enum Status {PENDING, APPROVED, DISAPPROVED}

    struct MintDetails {
        uint amount;
        address to;
        uint validTill;
        Status status;
        uint executedAt;
    }

    // mapping from mint id to mint details.
    mapping(uint => MintDetails) public mintDetails;

    constructor(uint maxSupply) ERC20("City Of Gold", "COG") {
        MAX_SUPPLY = maxSupply;
    }

    modifier onlyMinter() {
        require(msg.sender == MINTER, "Only the minter role can call this function.");
        _;
    }

    modifier onlyAuthenticator() {
        require(msg.sender == AUTHENTICATOR, "Only the authenticator role can call this function.");
        _;
    }

    function setMinter(address minter) public onlyOwner {
        MINTER = minter;
    }

    function setAuthenticator(address authenticator) public onlyOwner {
        AUTHENTICATOR = authenticator;
    }

    function requestMint(uint _amount, address _to, uint validity) public onlyMinter {
        require(_to != address(0), "Cannot mint to a zero address");
        require(totalSupply() + _amount <= MAX_SUPPLY, "Mint exceeds max supply of the token.");
        CURRENT_MINT_ID = CURRENT_MINT_ID + 1;
        // just to start from one
        mintDetails[CURRENT_MINT_ID] =
            MintDetails({
                amount : _amount,
                to : _to,
                validTill : block.timestamp + validity,
                status : Status.PENDING,
                executedAt: 0
        });
    }

    function authenticateMint(uint mintId, bool authenticate) public onlyAuthenticator {
        MintDetails storage _mintDetails = mintDetails[mintId];
        require(_mintDetails.status == Status.PENDING, "Mint already approved or disapproved");
        require(_mintDetails.validTill >= block.timestamp, "Mint time expired");
        if (authenticate) {
            _mintDetails.status = Status.APPROVED;
            _mintDetails.executedAt = block.timestamp;
            _mint(_mintDetails.to, _mintDetails.amount);
        } else {
            _mintDetails.status = Status.DISAPPROVED;
        }
    }

}
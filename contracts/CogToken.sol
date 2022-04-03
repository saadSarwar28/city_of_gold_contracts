// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";
//import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

import 'openzeppelin-solidity/contracts/token/ERC20/ERC20.sol';
import "openzeppelin-solidity/contracts/access/Ownable.sol";


contract CityOfGold is ERC20, Ownable{

    uint public MAX_SUPPLY;

    constructor(uint maxSupply) ERC20("City Of Gold", "COG") {
        MAX_SUPPLY = maxSupply;
    }

    function mint(uint amount, address to) public onlyOwner {
        require(to != address(0), "Cannot mint to a zero address");
        amount = amount * 10**18;
        require(totalSupply() + amount <= MAX_SUPPLY, "Mint exceeds max supply of the token.");
        _mint(to, amount);
    }


}
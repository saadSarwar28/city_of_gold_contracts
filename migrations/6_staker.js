const Staker = artifacts.require("Staker");

// for testnet
const cog = "0xEee73FFA1b982bC4832Cd0d4B063bC741446C3E8"
const land = "0x324679F796cbe7c9680647830B2854E265719e93"
const estate = "0x42D19262598aBd65d7941586432160765e803D1b"
const scores = "0xDD15446D1e870643ED8D35495a84Ae6CfF2A923d"

module.exports = async function (deployer) {
    await deployer.deploy(Staker, cog, land, estate, scores);
};
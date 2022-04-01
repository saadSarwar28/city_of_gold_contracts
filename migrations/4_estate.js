const cityOfGoldEstate = artifacts.require("cityOfGoldEstate");
const staker = "0x5340fc6cA1315bcFBbdEc73686247DDCD0f38F98"
const land = "0x324679F796cbe7c9680647830B2854E265719e93"

module.exports = async function (deployer) {
    await deployer.deploy(cityOfGoldEstate, staker, land);
};

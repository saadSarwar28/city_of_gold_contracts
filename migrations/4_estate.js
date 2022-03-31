const cityOfGoldEstate = artifacts.require("cityOfGoldEstate");
const staker = ""
const land = ""

module.exports = async function (deployer) {
    await deployer.deploy(cityOfGoldEstate, staker, land);
};

const Staker = artifacts.require("Staker");
const cog = ""
const land = ""
const estate = ""
const scores = ""

module.exports = async function (deployer) {
    await deployer.deploy(Staker, cog, land, estate, scores);
};
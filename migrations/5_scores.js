const CityOfGoldScores = artifacts.require("CityOfGoldScores");

module.exports = async function (deployer) {
    await deployer.deploy(CityOfGoldScores);
};
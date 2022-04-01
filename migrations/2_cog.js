const cogToken = artifacts.require("CityOfGold");
const maxSupply = '1000000000000000000000000000'

module.exports = async function (deployer) {
    await deployer.deploy(cogToken, maxSupply);
};

const Staker = artifacts.require("Staker");
const CityOfGoldScores = artifacts.require("CityOfGoldScores");
const cityOfGoldEstate = artifacts.require("cityOfGoldEstate");
const cityOfGoldLand = artifacts.require("cityOfGoldLand");

module.exports = async function (deployer) {

    // const maxNfts = 10000
    // const treasury = '0xA97F7EB14da5568153Ea06b2656ccF7c338d942f' // saad's address
    // const publicSalePrice = '150000000000000000'  // 0.15 ether
    // const whitelistPrice = '100000000000000000'  // 0.1 ether
    // const maxPerWallet = 9
    // await deployer.deploy(cityOfGoldLand, maxNfts, treasury, publicSalePrice, whitelistPrice, maxPerWallet);
    // const landContract = await cityOfGoldLand.deployed()

    await deployer.deploy(Staker,
        "0x6A5d97788D4339Ee9FEB0Bbb0257a3e81d18db9b",
        "0x945DF3A54Fa8dF92e97aeD79b575DC0427fB5FEB",
        "0xA82a1cF2621753De77ACA71B4A9Ba7A2c8119b8b",
        "0xb996555807A52Fe9D61DA61e1cc15E35B0DFacDb"
    )
    // const staker = await Staker.deployed()

    // await deployer.deploy(cityOfGoldEstate, "0xA3dF354A5614b2a9B2cCC3a2220EbE558c0bbc9A", "0x0f4CA49d770C216A66270fA96480669E21a45444");
    // await deployer.deploy(CityOfGoldScores);
};

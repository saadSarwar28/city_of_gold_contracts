const Staker = artifacts.require("CityOfGoldStaker");
const CityOfGoldScores = artifacts.require("CityOfGoldScores");
const cityOfGoldEstate = artifacts.require("CityOfGoldEstate");
const cityOfGoldLand = artifacts.require("CityOfGoldLand");

module.exports = async function (deployer) {

    // const maxNfts = 100
    // const treasury = '0xA97F7EB14da5568153Ea06b2656ccF7c338d942f' // saad's address
    // const publicSalePrice = '150000000000000000'  // 0.15 ether
    // const whitelistPrice = '100000000000000000'  // 0.1 ether
    // const maxPerWallet = 9
    // const allocatedForTeam = 25
    // await deployer.deploy(cityOfGoldLand, maxNfts, treasury, publicSalePrice, whitelistPrice, maxPerWallet, allocatedForTeam);
    // const landContract = await cityOfGoldLand.deployed()

    await deployer.deploy(Staker,
        "0xb809635a64E477e37fde105856903De232cA2C24",
        "0x5f773674b4543E8f323d92A333B25C7912ED5Be4",
        "0x438B650C2D2A25aA7607Dbe66ed9266f979b5641",
        "0x694a473FF193DBE566A00E85d4117af06f400616"
    )
    // const staker = await Staker.deployed()

    // await deployer.deploy(cityOfGoldEstate, "0xA3dF354A5614b2a9B2cCC3a2220EbE558c0bbc9A", "0x0f4CA49d770C216A66270fA96480669E21a45444");
    // await deployer.deploy(CityOfGoldScores);
};

const Staker = artifacts.require("CityOfGoldStaker");
const CityOfGoldScores = artifacts.require("CityOfGoldScores");
const cityOfGoldEstate = artifacts.require("CityOfGoldEstate");
const cityOfGoldLand = artifacts.require("CityOfGoldLand");

module.exports = async function (deployer) {

    const maxNfts = 100
    const treasury = '0xA97F7EB14da5568153Ea06b2656ccF7c338d942f' // saad's address
    const publicSalePrice = '150000000000000000'  // 0.15 ether
    const whitelistPrice = '100000000000000000'  // 0.1 ether
    const maxPerWallet = 9
    const allocatedForTeam = 25
    await deployer.deploy(cityOfGoldLand, maxNfts, treasury, publicSalePrice, whitelistPrice, maxPerWallet, allocatedForTeam);
    // const landContract = await cityOfGoldLand.deployed()

    // await deployer.deploy(Staker,
    //     "0x1F53eEb267e7642245E1899ef3D095721aA2AA05",
    //     "0xf4ec89B7daA79c4d41752cf04fd7B2b40735Faf2",
    //     "0x994755c0Dd72763500F705045143893D3b3Fa11a",
    //     "0x911B76FC1Eb89deEf1D5B3D61b85286C6D313021"
    // )
    // const staker = await Staker.deployed()

    // await deployer.deploy(cityOfGoldEstate, "0xA3dF354A5614b2a9B2cCC3a2220EbE558c0bbc9A", "0x0f4CA49d770C216A66270fA96480669E21a45444");
    // await deployer.deploy(CityOfGoldScores);
};

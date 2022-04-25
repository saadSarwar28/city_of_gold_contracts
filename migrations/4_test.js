// scores
const CityOfGoldScores = artifacts.require("CityOfGoldScoresDummy");
// cog token
const cogToken = artifacts.require("CityOfGold");
// land token
const cityOfGoldLand = artifacts.require("CityOfGoldLand");
// estate token
const cityOfGoldEstate = artifacts.require("CityOfGoldEstate");
// staker
const Staker = artifacts.require("CityOfGoldStaker");

module.exports = async function (deployer) {

    await deployer.deploy(CityOfGoldScores, "0x0000000000000000000000000000000000000000")
    const scoresContract = await CityOfGoldScores.deployed()

    const maxSupplyCog = '1000000000000000000000000000' // one billion
    await deployer.deploy(cogToken, maxSupplyCog)
    const cogContract = await cogToken.deployed()


    const maxNfts = 100
    const treasury = '0xA97F7EB14da5568153Ea06b2656ccF7c338d942f' // saad's address
    const publicSalePrice = '15000000000000000'  // 0.015 ether
    const whitelistPrice =  '12000000000000000'  // 0.012 ether
    const maxPerWallet = 9
    const allocatedForTeam = 25
    await deployer.deploy(cityOfGoldLand, maxNfts, treasury, publicSalePrice, whitelistPrice, maxPerWallet, allocatedForTeam);
    const landContract = await cityOfGoldLand.deployed()

    await deployer.deploy(cityOfGoldEstate, scoresContract.address, landContract.address);
    const estateContract = await cityOfGoldEstate.deployed()

    await deployer.deploy(Staker, cogContract.address, landContract.address, estateContract.address, scoresContract.address)
    const staker = await Staker.deployed()

    estateContract.setStakerAddress(staker.address) // correction of staker address
    landContract.setStakerAddress(staker.address) // correction of staker address
    scoresContract.setEstateAddress(estateContract.address) // correction of estate contract address
};

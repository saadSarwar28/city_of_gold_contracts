// scores
const CityOfGoldScores = artifacts.require("CityOfGoldScoresDummy");
// cog token
const cogToken = artifacts.require("CityOfGold");
// land token
const cityOfGoldLand = artifacts.require("cityOfGoldLand");
// estate token
const cityOfGoldEstate = artifacts.require("cityOfGoldEstate");
// staker
const Staker = artifacts.require("Staker");

module.exports = async function (deployer) {

    const maxSupplyCog = '1000000000000000000000000000' // one billion
    await deployer.deploy(cogToken, maxSupplyCog)
    const cogContract = await cogToken.deployed()

    const maxNfts = 30
    const treasury = '0xA97F7EB14da5568153Ea06b2656ccF7c338d942f' // saad's address
    const publicSalePrice = '150000000000000000'  // 0.15 ether
    const whitelistPrice =  '120000000000000000'  // 0.12 ether
    const maxPerWallet = 9
    await deployer.deploy(cityOfGoldLand, maxNfts, treasury, publicSalePrice, whitelistPrice, maxPerWallet);
    const landContract = await cityOfGoldLand.deployed()

    await deployer.deploy(CityOfGoldScores, "0x0000000000000000000000000000000000000000")
    const scoresContract = await CityOfGoldScores.deployed()

    await deployer.deploy(cityOfGoldEstate, scoresContract.address, landContract.address);
    const estateContract = await cityOfGoldEstate.deployed()

    await deployer.deploy(Staker, cogContract.address, landContract.address, estateContract.address, scoresContract.address)
    const staker = await Staker.deployed()

    estateContract.setStakerAddress(staker.address) // correction of staker address
    landContract.setStakerAddress(staker.address) // correction of staker address
    scoresContract.setEstateAddress(estateContract.address) // correction of estate contract address
};

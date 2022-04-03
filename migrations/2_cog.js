// scores
const CityOfGoldScores = artifacts.require("CityOfGoldScores");
// cog token
const cogToken = artifacts.require("CityOfGold");
// land token
const cityOfGoldLand = artifacts.require("cityOfGoldLand");
// estate token
const cityOfGoldEstate = artifacts.require("cityOfGoldEstate");
// staker
const Staker = artifacts.require("Staker");

module.exports = async function (deployer) {

    await deployer.deploy(CityOfGoldScores)
    const scoresContract = await CityOfGoldScores.deployed()

    const maxSupplyCog = '1000000000000000000000000000' // one billion
    await deployer.deploy(cogToken, maxSupplyCog)
    const cogContract = await cogToken.deployed()
    await cogContract.mint("1000", "0x5340fc6cA1315bcFBbdEc73686247DDCD0f38F98") // minting 1000 for test


    const maxNfts = 10000
    const treasury = '0xA97F7EB14da5568153Ea06b2656ccF7c338d942f' // saad's address
    const publicSalePrice = '150000000000000000'  // 0.15 ether
    const whitelistPrice = '100000000000000000'  // 0.1 ether

    await deployer.deploy(cityOfGoldLand, maxNfts, treasury, publicSalePrice, whitelistPrice);
    const landContract = await cityOfGoldLand.deployed()

    await deployer.deploy(cityOfGoldEstate, scoresContract.address, landContract.address);
    const estateContract = await cityOfGoldEstate.deployed()

    await deployer.deploy(Staker, cogContract.address, landContract.address, estateContract.address, scoresContract.address)
    const staker = await Staker.deployed()

    estateContract.setStakerAddress(staker.address) // correction of staker address
    landContract.setStakerAddress(staker.address) // setting staker address

};

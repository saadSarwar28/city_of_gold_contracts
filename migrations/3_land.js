const cityOfGoldLand = artifacts.require("cityOfGoldLand");
const maxNfts = 10000
const treasury = '0xA97F7EB14da5568153Ea06b2656ccF7c338d942f'
const publicSalePrice = '150000000000000000'  // 0.15 ether
const whitelistPrice = '100000000000000000'  // 0.1 ether

module.exports = async function (deployer) {
    await deployer.deploy(cityOfGoldLand, maxNfts, treasury, publicSalePrice, whitelistPrice);
};

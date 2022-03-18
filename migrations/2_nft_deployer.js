const CloserLookNFT = artifacts.require("CloserLookNFT");
const maxNfts = 10000
const treasury = '0xA97F7EB14da5568153Ea06b2656ccF7c338d942f'

module.exports = async function (deployer) {
    await deployer.deploy(CloserLookNFT, maxNfts, treasury);
};

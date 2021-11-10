// ============ Contracts ============
const Trader = artifacts.require('Trader')
const Converter = artifacts.require('Converter')

// ============ Main Migration ============
const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployTrader(deployer, network),
  ])
}

// ============ Deploy Functions ============
async function deployTrader(deployer, network) {
  const converter = await Converter.deployed()
  await deployer.deploy(Trader, converter.address)
}

module.exports = migration

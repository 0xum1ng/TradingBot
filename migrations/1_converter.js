// ============ Contracts ============
const Converter = artifacts.require('Converter')

// ============ Main Migration ============
const migration = async (deployer, network, accounts) => {
  await Promise.all([
    deployConverter(deployer, network),
  ])
}

// ============ Deploy Functions ============
async function deployConverter(deployer, network) {
  const weth = "0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000"
  const router = "0x4df04E20cCd9a8B82634754fcB041e86c5FF085A"
  await deployer.deploy(Converter, weth, router)
}

module.exports = migration

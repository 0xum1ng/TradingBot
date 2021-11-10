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
  const router = "0x17C83E2B96ACfb5190d63F5E46d93c107eC0b514"
  await deployer.deploy(Converter, weth, router)
}

module.exports = migration

require('dotenv').config()
const {
    Contract,
    Wallet,
    providers,
    utils
} = require('ethers')
const Web3 = require('Web3')

const {
  LOOP_INTERVAL,
  PRIVATE_KEY,
  RPC
} = process.env

const trader = require("../build/contracts/Trader");

// Set up web3
const provider = new providers.JsonRpcProvider(RPC);
const signer = new Wallet(PRIVATE_KEY, provider);
const traderInstance = new Contract('0xf366A6c441bd93C383b4ca64771269A112ab0a9E', trader.abi, signer);

const trades = [
    {
        "tokenIn": "0xDeadDeAddeAddEAddeadDEaDDEAdDeaDDeAD0000", // eth
        "tokenOut": "0x4204a0aF0991b2066d2D617854D5995714a79132", // oolong
        "amountIn": "0.000001",
        "minAmountOut": "4.23"
    }
];

async function main() {
  for (let i=0; i<trades.length; i++) {
    // Check if trade is profitable
    const isProfitable = await traderInstance.isProfitableSwap(
        trades[i].tokenIn,
        trades[i].tokenOut,
        utils.parseEther(trades[i].amountIn),
        // TODO: Fetch live price from binance, and add % based discount
        utils.parseEther(trades[i].minAmountOut)
    );

    // execute trade if profitable
    if (isProfitable) {
       console.log(`\n`)
       console.log("found profitable trade: ", trades[i],)
       console.log("swapping...")
       try {
         const swapTx = await traderInstance.swap(
           trades[i].tokenIn,
           trades[i].tokenOut,
           utils.parseEther(trades[i].amountIn),
           utils.parseEther(trades[i].minAmountOut)
         )
         console.log("swapped SUCCEEDED: ", swapTx.hash)
       } catch (e) {
         console.log("swapped FAILED with exception: ", e.error.error.body)
       }
    }
  }

  setTimeout(() => {
    main()
  }, LOOP_INTERVAL)
}

main()

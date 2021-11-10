require('dotenv').config()
const {
    Contract,
    Wallet,
    providers,
    utils
} = require('ethers')
const Web3 = require('Web3')
const axios = require("axios");

const {
  LOOP_INTERVAL,
  PRIVATE_KEY,
  RPC
} = process.env

const trader = require("../build/contracts/Trader");
const trades = require("./trades.json");

// Set up web3
const provider = new providers.JsonRpcProvider(RPC);
const signer = new Wallet(PRIVATE_KEY, provider);
const traderInstance = new Contract('0x7f0A0229606A33F94C9367ad7497768A93a54670', trader.abi, signer);

async function executeTrade(trader, tokenIn, tokenOut, amountIn, amountOut) {
  try {
   const swapTx = await trader.swap(
     tokenIn,
     tokenOut,
     amountIn,
     amountOut
   )
   console.log("swapTx: ", swapTx)
   console.log("swapped SUCCEEDED: ", swapTx.hash)
  } catch (e) {
   console.log("swapped FAILED with exception: ", e.error.error.body)
  }
}

async function checkIfProfitable(trader, tokenIn, tokenOut, amountIn, amountOut) {
  try {
    return await trader.isProfitableSwap(
      tokenIn,
      tokenOut,
      amountIn,
      amountOut
    )
  } catch (e) {
    console.log("error checking swap: ", e.error.error.body)
  }
}

async function main() {
  for (let i=0; i<trades.length; i++) {
    // Get price from binance
    const query = "https://api.binance.com/api/v3/ticker/price?symbol=" + trades[i].symbol
    const response = await axios.get(query);
    const currentPrice1To2 = response.data.price;

    // Check if token1 -> token2 is profitable
    const profitablePrice1To2 = Number(currentPrice1To2) * (1 + trades[i].profitPercent) // get profitable price from token1 to token2
    const expectedToken2Amount = Number(trades[i].token1Amount * profitablePrice1To2) // expected token2 out
    const isProfitable1To2 = await checkIfProfitable(
      traderInstance,
      trades[i].token1,
      trades[i].token2,
      utils.parseEther(String(trades[i].token1Amount)),
      utils.parseEther(String(expectedToken2Amount))
    )
    if (isProfitable1To2) {
      console.log(`==================================\n`)
      console.log("Found profitable trade")
      console.log("Symbol: ", trades[i].symbol)
      console.log("Direction: 1->2")
      console.log("Current price: ", currentPrice1To2)
      console.log("Execution price: ", profitablePrice1To2)
      console.log("Amount1In: ", trades[i].token1Amount)
      console.log("ExpectedAmount2Out: ", expectedToken2Amount)
      // await executeTrade(
      //   traderInstance,
      //   trades[i].token1,
      //   trades[i].token2,
      //   utils.parseEther(String(trades[i].token1Amount)),
      //   utils.parseEther(String(expectedToken2Amount))
      // )
    }

    // Check if token2 -> token1 is profitable
    const currentPrice2To1 = 1 / Number(currentPrice1To2)
    const profitablePrice2To1 = currentPrice2To1 * (1 + trades[i].profitPercent) // get profitable price from token2 to token1
    const expectedToken1Amount = Number(trades[i].token2Amount * profitablePrice2To1) // expected token1 out
    const isProfitable2To1 = await checkIfProfitable(
      traderInstance,
      trades[i].token2,
      trades[i].token1,
      utils.parseEther(String(trades[i].token2Amount)),
      utils.parseEther(String(expectedToken1Amount))
    )
    if (isProfitable2To1) {
      console.log(`==================================\n`)
      console.log("Found profitable trade")
      console.log("Symbol: ", trades[i].symbol)
      console.log("Direction: 2->1")
      console.log("Current price: ", currentPrice1To2)
      console.log("Exeuction price: ", profitablePrice2To1)
      console.log("Amount2In: ", trades[i].token2Amount)
      console.log("ExpectedAmount1Out: ", expectedToken1Amount)
      // await executeTrade(
      //   traderInstance,
      //   trades[i].token1,
      //   trades[i].token2,
      //   utils.parseEther(String(trades[i].token1Amount)),
      //   utils.parseEther(String(expectedToken2Amount))
      // )
    }
  }

  setTimeout(() => {
    main()
  }, LOOP_INTERVAL)
}

main()

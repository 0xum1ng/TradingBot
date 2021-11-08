// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

interface IConverter {
  function swap(address _tokenIn, address _tokenOut, uint _amountIn) external returns (uint amountOut_);
  function addLiquidity(address _tokenA, address _tokenB, uint _amountA, uint _amountB) external returns (uint lpAmount_);
  function removeLiquidity(address _lpPair, uint _liquidity) external returns (address _tokenA, address _tokenB, uint amountA_, uint amountB_);
  function getExpectedAmountOut(address _tokenIn, address _tokenOut, uint _amountIn) external view returns (uint amountOut_);
}

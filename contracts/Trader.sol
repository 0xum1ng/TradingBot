// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "./common/SafeMath.sol";
import "./common/IERC20.sol";
import "./common/Address.sol";
import "./common/SafeERC20.sol";

import "./interfaces/IConverter.sol";

contract Trader {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public governance;
    address public converter;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _converter) public {
        governance = msg.sender;
        converter = _converter;
    }

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance);
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function holdings(address _token)
        public
        view
        returns (uint256)
    {
        return IERC20(_token).balanceOf(address(this));
    }

    function testSwap(address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256) {
        return IConverter(converter).getExpectedAmountOut(_tokenIn, _tokenOut, _amountIn);
    }

    function isProfitableSwap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _expectedAmountOut) external view returns (bool) {
        uint256 actualAmountOut = testSwap(_tokenIn, _tokenOut, _amountIn);
        return actualAmountOut >= _expectedAmountOut ? true : false;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    receive() external payable {}

    // swap any token to any token
    function swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _expectedAmountOut) external onlyGov {
        IERC20(_tokenIn).approve(converter, 99999999999999999999999999999999999999999);
        uint256 amountOut = IConverter(converter).swap(_tokenIn, _tokenOut, _amountIn);
        require(amountOut >= _expectedAmountOut, "unprofitable");
        emit Swapped(_tokenIn, _tokenOut, _amountIn, amountOut);
    }

    /* ========== ADMIN FUNCTIONS ========== */

    function setGov(address _governance)
        public
        onlyGov
    {
        governance = _governance;
    }

    function setConverter(address _converter)
        public
        onlyGov
    {
        converter = _converter;
    }

    function takeOut(
        address _token,
        address _destination,
        uint256 _amount
    )
        public
        onlyGov
    {
        require(_amount <= holdings(_token), "!insufficient");
        IERC20(_token).safeTransfer(_destination, _amount);
    }

    function takeOutETH(
        address payable _destination,
        uint256 _amount
    )
        public
        payable
        onlyGov
    {
        _destination.transfer(_amount);
    }

    /* ========== EVENTS ========== */

    event Swapped(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
}

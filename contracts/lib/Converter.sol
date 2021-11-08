// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "../common/Address.sol";
import "../common/SafeERC20.sol";

import "../interfaces/IConverter.sol";
import "../interfaces/IOolongSwapRouter.sol";
import "../interfaces/IOolongSwapPair.sol";

// A stateless converter for swappng token and LPs
contract Converter is IConverter {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========== STATE VARIABLES ========== */

    address public governance;
    address public immutable weth;
    address public immutable router;
    mapping(address => address) internal bridges; // mapping of token => bridge token

    /* ========== CONSTRUCTOR ========== */

    constructor(address _weth, address _router) public {
        weth = _weth;
        router = _router;
        governance = msg.sender;
    }

    /* ========== VIEWS ========== */

    function bridgeFor(address _token) public view returns (address) {
        address bridge = bridges[_token];
        if (bridge == address(0)) {
            bridge = weth;
        }
        return bridge;
    }

    function getExpectedAmountOut(address _tokenIn, address _tokenOut, uint _amountIn) external override view returns (uint amountOut_) {
        address bridgeToken = bridgeFor(_tokenIn);
        bool is_bridgeToken = _tokenIn == bridgeToken || _tokenOut == bridgeToken;
        address[] memory path = new address[](is_bridgeToken ? 2 : 3);
        path[0] = _tokenIn;
        if (is_bridgeToken) {
            path[1] = _tokenOut;
        } else {
            path[1] = bridgeToken;
            path[2] = _tokenOut;
        }
        uint[] memory amounts = IOolongSwapRouter(router).getAmountsOut(_amountIn, path);
        amountOut_ = amounts[amounts.length - 1];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // swap any token to any token and send back to msg.sender
    function swap(address _tokenIn, address _tokenOut, uint _amountIn) external override returns (uint amountOut_) {
        if (_tokenIn == _tokenOut) return _amountIn;
        IERC20(_tokenIn).safeTransferFrom(msg.sender, address(this), _amountIn);
        amountOut_ = _swap(_tokenIn, _tokenOut, _amountIn, msg.sender);
    }

    // add liquidity for any token pair and return LP token to msg.sender
    function addLiquidity(address _tokenA, address _tokenB, uint _amountA, uint _amountB) external override returns (uint lpAmount_) {
        IERC20(_tokenA).safeTransferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).safeTransferFrom(msg.sender, address(this), _amountB);
        lpAmount_ = _addLiquidity(_tokenA, _tokenB, _amountA, _amountB, msg.sender);
    }

    // remove liquidity for any LP and return underlyings to msg.sender
    function removeLiquidity(address _lpPair, uint _liquidity) external override returns (address _tokenA, address _tokenB, uint amountA_, uint amountB_) {
        _tokenA = IOolongSwapPair(_lpPair).token0();
        _tokenB = IOolongSwapPair(_lpPair).token1();
        IERC20(_lpPair).safeTransferFrom(msg.sender, address(this), _liquidity);
        (amountA_, amountB_) = _removeLiquidity(_tokenA, _tokenB, _lpPair, _liquidity, msg.sender);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _swap(address _tokenIn, address _tokenOut, uint _amountIn, address _to) internal returns (uint amountOut_) {
        address bridgeToken = bridgeFor(_tokenIn);
        bool is_bridgeToken = _tokenIn == bridgeToken || _tokenOut == bridgeToken;
        address[] memory path = new address[](is_bridgeToken ? 2 : 3);
        path[0] = _tokenIn;
        if (is_bridgeToken) {
            path[1] = _tokenOut;
        } else {
            path[1] = bridgeToken;
            path[2] = _tokenOut;
        }
        IERC20(_tokenIn).safeApprove(router, 0);
        IERC20(_tokenIn).safeApprove(router, _amountIn);
        uint[] memory amounts = IOolongSwapRouter(router).swapExactTokensForTokens(
            _amountIn,
            0,
            path,
            _to,
            now.add(1800)
        );
        amountOut_ = amounts[amounts.length - 1];
    }

    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB,
        address _to
    )
        internal
        returns (uint lpAmount_)
    {
        IERC20(_tokenA).safeApprove(router, 0);
        IERC20(_tokenA).safeApprove(router, _amountA);
        IERC20(_tokenB).safeApprove(router, 0);
        IERC20(_tokenB).safeApprove(router, _amountB);
        ( , , lpAmount_) = IOolongSwapRouter(router).addLiquidity(
            _tokenA,
            _tokenB,
            _amountA,
            _amountB,
            uint(0),
            uint(0),
            _to,
            now.add(1800)
        );
    }

    function _removeLiquidity(
        address _tokenA,
        address _tokenB,
        address _lpToken,
        uint _liquidity,
        address _to
    )
        public
        returns (uint amountA_, uint amountB_)
    {
        IERC20(_lpToken).safeApprove(router, 0);
        IERC20(_lpToken).safeApprove(router, _liquidity);
        (amountA_, amountB_) = IOolongSwapRouter(router).removeLiquidity(
            _tokenA,
            _tokenB,
            _liquidity,
            uint(0),
            uint(0),
            _to,
            now.add(1800)
        );
    }

    /* ========== MODIFIER ========== */

    modifier onlyGov() {
        require(msg.sender == governance);
        _;
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setGov(address _governance)
        public
        onlyGov
    {
        governance = _governance;
    }

    // Allow governance to rescue tokens
    function rescue(address _token)
        public
        onlyGov
    {
        uint _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(governance, _balance);
    }

    function setBridge(address _token, address _bridge) external onlyGov {
        // Checks
        require(_token != weth && _token != _bridge, "Invalid bridge");
        // Effects
        bridges[_token] = _bridge;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./MemeToken.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

interface IPancakeV3Factory {
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);
}

interface IUniswapV3Pool {
    function initialize(uint160 sqrtPriceX96) external;
    function slot0()
        external
        view
        returns (
            uint160 sqrtPriceX96, // Current price as a sqrt(token1/token0) Q64.96
            int24 tick, // Current tick
            uint16 observationIndex, // Index of the last oracle observation that was written
            uint16 observationCardinality, // Current maximum number of observations stored in the pool
            uint16 observationCardinalityNext, // Next maximum number of observations, to be updated when the observation cardinality increases
            uint8 feeProtocol, // Protocol fee is a representation of the fee in token0 and token1
            bool unlocked // True if the pool is unlocked, false if it is locked
        );
}

interface INonfungiblePositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function mint(
        MintParams calldata params
    )
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );
}

contract TestLP is AccessControl, ERC721Holder {
    address public positionManagerAddress =
        0x427bF5b37357632377eCbEC9de3626C71A5396c1;
    address public factoryAddress = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;

    address public tokenA;
    address public tokenB;

    int24 private constant MIN_TICK = -887220;
    int24 private constant MAX_TICK = 887220;
    int24 private constant TICK_SPACING = 10;
    uint24 private constant FEE = 500; // Fee for 0.05% tier

    constructor() {}

    function createToken() external {
        MemeToken token0 = new MemeToken(
            address(this),
            1000000 * 10 ** 18,
            "TOKEN0",
            "T0"
        );
        MemeToken token1 = new MemeToken(
            address(this),
            1000000 * 10 ** 18,
            "TOKEN1",
            "T1"
        );

        // Set tokens in lexicographical order
        (tokenA, tokenB) = address(token0) < address(token1)
            ? (address(token0), address(token1))
            : (address(token1), address(token0));
    }

    function calculateSqrtPriceX96(
        uint256 supplyA,
        uint256 supplyB
    ) internal pure returns (uint160) {
        require(supplyA > 0, "SupplyA must be greater than 0");

        // Calculate the price ratio in fixed-point format (supplyB * 1e18 / supplyA for precision)
        uint256 priceRatio = (supplyB * 1e18) / supplyA;

        // Calculate the square root of the price ratio using OpenZeppelin's Math library
        uint256 sqrtRatio = Math.sqrt(priceRatio);

        // Convert to Q64.96 format by dividing back to the original scale and shifting
        return uint160((sqrtRatio * (2 ** 96)) / 1e9);
    }
    
    function createPool() external {
        IPancakeV3Factory(factoryAddress).createPool(tokenA, tokenB, FEE);
        address pool = IPancakeV3Factory(factoryAddress).getPool(
            tokenA,
            tokenB,
            FEE
        );

        uint256 amountADesired = 1000 * 10 ** 18;
        uint256 amountBDesired = 2000 * 10 ** 18;

        // Calculate the price ratio based on amountADesired and amountBDesired
        uint256 priceRatio = (amountBDesired * (10 ** 18)) / amountADesired;

        // Calculate sqrtPriceX96 using the price ratio
        uint160 sqrtPriceX96 = calculateSqrtPriceX96(
            amountADesired,
            amountBDesired
        );

        // Initialize the pool if the current price is 0
        (uint160 currentPrice, , , , , , ) = IUniswapV3Pool(pool).slot0();
        if (currentPrice == 0) {
            IUniswapV3Pool(pool).initialize(sqrtPriceX96);
        }
    }

    event MintAttempt(
        address token0,
        address token1,
        uint24 fee,
        int24 tickLower,
        int24 tickUpper
    );
    function createLP() external {
        uint256 amountADesired = 1000 * 10 ** 18;
        uint256 amountBDesired = 2000 * 10 ** 18;

        IERC20(tokenA).approve(positionManagerAddress, amountADesired);
        IERC20(tokenB).approve(positionManagerAddress, amountBDesired);

        emit MintAttempt(tokenA, tokenB, FEE, MIN_TICK, MAX_TICK);

        INonfungiblePositionManager.MintParams
            memory params = INonfungiblePositionManager.MintParams({
                token0: tokenA,
                token1: tokenB,
                fee: FEE,
                tickLower: MIN_TICK,
                tickUpper: MAX_TICK,
                amount0Desired: amountADesired,
                amount1Desired: amountBDesired,
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp + 300
            });

        (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        ) = INonfungiblePositionManager(positionManagerAddress).mint(params);
    }
}

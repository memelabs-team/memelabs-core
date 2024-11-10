// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    function mint(MintParams calldata params)
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );
}

contract MockNonfungiblePositionManager is INonfungiblePositionManager {

    uint256 public nextTokenId = 1;

    // Mock function for mint
    function mint(MintParams calldata params)
        external
        override
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        // Use `nextTokenId` to simulate unique token IDs
        tokenId = nextTokenId++;
        liquidity = 1000; // Mock liquidity value
        amount0 = params.amount0Desired; // Mocked to use `amount0Desired`
        amount1 = params.amount1Desired; // Mocked to use `amount1Desired`

        // Simulate transfer of tokens and creation of the liquidity position (not implemented in mock)
        
        return (tokenId, liquidity, amount0, amount1);
    }
}

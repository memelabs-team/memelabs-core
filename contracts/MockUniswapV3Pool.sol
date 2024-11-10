// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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


contract MockUniswapV3Pool is IUniswapV3Pool {
    uint160 private _sqrtPriceX96;
    int24 private _tick;
    uint16 private _observationIndex;
    uint16 private _observationCardinality;
    uint16 private _observationCardinalityNext;
    uint8 private _feeProtocol;
    bool private _unlocked = true;

    event Initialized(uint160 sqrtPriceX96);

    // Initialize the pool with the initial sqrt price
    function initialize(uint160 sqrtPriceX96) external override {
        _sqrtPriceX96 = sqrtPriceX96;
        _tick = 0; // Set initial tick to 0 for simplicity
        _observationIndex = 0;
        _observationCardinality = 1; // Minimal observation cardinality for testing
        _observationCardinalityNext = 1;
        _feeProtocol = 0;
        _unlocked = true;

        emit Initialized(sqrtPriceX96);
    }

    // Return the current state of the pool's slot0
    function slot0()
        external
        view
        override
        returns (
            uint160 sqrtPriceX96,
            int24 tick,
            uint16 observationIndex,
            uint16 observationCardinality,
            uint16 observationCardinalityNext,
            uint8 feeProtocol,
            bool unlocked
        )
    {
        return (
            _sqrtPriceX96,
            _tick,
            _observationIndex,
            _observationCardinality,
            _observationCardinalityNext,
            _feeProtocol,
            _unlocked
        );
    }

    // Optional: A function to mock setting the slot0 values, useful for testing purposes
    function setSlot0(
        uint160 sqrtPriceX96,
        int24 tick,
        uint16 observationIndex,
        uint16 observationCardinality,
        uint16 observationCardinalityNext,
        uint8 feeProtocol,
        bool unlocked
    ) external {
        _sqrtPriceX96 = sqrtPriceX96;
        _tick = tick;
        _observationIndex = observationIndex;
        _observationCardinality = observationCardinality;
        _observationCardinalityNext = observationCardinalityNext;
        _feeProtocol = feeProtocol;
        _unlocked = unlocked;
    }
}

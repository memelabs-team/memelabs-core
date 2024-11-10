// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract MockPancakeV3Factory {
    mapping(bytes32 => address) public pools;
    uint256 public poolCount = 0;

    event PoolCreated(address indexed tokenA, address indexed tokenB, uint24 fee, address pool);

    address mockupPool;

    function setMockPool(address pool) external{
        mockupPool = pool;
    }
    // Function to create a pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external  returns (address pool) {
        require(tokenA != tokenB, "Identical token addresses");
        require(tokenA != address(0) && tokenB != address(0), "Invalid token address");

        // Generate a unique identifier for the pool
        bytes32 poolId = keccak256(abi.encodePacked(tokenA, tokenB, fee));

        // Check if the pool already exists
        require(pools[poolId] == address(0), "Pool already exists");

        pools[poolId] = mockupPool;

        emit PoolCreated(tokenA, tokenB, fee, pool);

        return mockupPool;
    }

    // Function to get the address of a pool if it exists
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view  returns (address pool) {
        bytes32 poolId = keccak256(abi.encodePacked(tokenA, tokenB, fee));
        return pools[poolId];
    }
}

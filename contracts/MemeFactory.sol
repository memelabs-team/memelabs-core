// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./MemeToken.sol";

contract MemeFactory {
    
    event TokenCreated(
        address indexed tokenAddress,
        address indexed owner,
        uint256 initialSupply
    );

    function createToken(
        address initialOwner,
        uint256 initialSupply,
        string memory name,
        string memory symbol
    ) public returns (address) {
        MemeToken newToken = new MemeToken(initialOwner, initialSupply, name, symbol);
        emit TokenCreated(address(newToken), initialOwner, initialSupply);
        return address(newToken);
    }
}

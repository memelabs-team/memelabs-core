// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract LPVault is AccessControl, ERC721Holder {
    // bytes32 public constant LIQUIDITY_PROVIDER_ROLE = keccak256("LIQUIDITY_PROVIDER_ROLE");
    // mapping(address => mapping(address => uint256)) public balances;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function withdraw(
        address token,
        uint256 tokenId
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        IERC721(token).transferFrom(address(this), msg.sender, tokenId);
    }
}

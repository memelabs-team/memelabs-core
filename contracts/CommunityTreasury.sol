// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract CommunityTreasury is AccessControl {

    struct Project {
        uint256 balance;
        address tokenAddress;
    }

    struct WithdrawalRequest {
        uint256 projectId;
        uint256 amount;
        address recipient;
        uint256 votes;
        bool executed;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Project) public projects;
    mapping(uint256 => WithdrawalRequest) public withdrawalRequests;
    uint256 public withdrawalRequestCount;

    event TokensDeposited(uint256 projectId, address indexed from, uint256 amount);
    event WithdrawalRequested(uint256 requestId, uint256 projectId, uint256 amount, address indexed recipient);
    event Voted(uint256 requestId, address indexed voter, uint256 weight);
    event WithdrawalExecuted(uint256 requestId, uint256 projectId, uint256 amount, address indexed recipient);

    modifier onlyTokenHolder(uint256 projectId) {
        require(IERC20(projects[projectId].tokenAddress).balanceOf(msg.sender) > 0, "Must hold tokens to vote");
        _;
    }

    bytes32 public constant REQUESTER = keccak256("REQUESTER");
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(REQUESTER, msg.sender);
    }

    // Deposit tokens into the treasury for a specific project
    function deposit(uint256 projectId, uint256 amount, address tokenAddress) external {
        require(amount > 0, "Deposit amount must be greater than zero");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);

        projects[projectId].balance += amount;
        projects[projectId].tokenAddress = tokenAddress;

        emit TokensDeposited(projectId, msg.sender, amount);
    }

    // Request a withdrawal from the treasury
    function requestWithdrawal(uint256 projectId, uint256 amount, address recipient) external onlyRole(REQUESTER) {
        require(projects[projectId].balance >= amount, "Insufficient balance for project");

        uint256 requestId = ++withdrawalRequestCount;
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        request.projectId = projectId;
        request.amount = amount;
        request.recipient = recipient;
        request.votes = 0;
        request.executed = false;

        emit WithdrawalRequested(requestId, projectId, amount, recipient);
    }

    // Vote on a withdrawal request (weight is based on token balance)
    function vote(uint256 requestId) external onlyTokenHolder(withdrawalRequests[requestId].projectId) {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        require(!request.executed, "Withdrawal already executed");
        require(!request.hasVoted[msg.sender], "Already voted");

        uint256 voterBalance = IERC20(projects[request.projectId].tokenAddress).balanceOf(msg.sender);
        request.votes += voterBalance;
        request.hasVoted[msg.sender] = true;

        emit Voted(requestId, msg.sender, voterBalance);

        if (_hasMajorityVotes(requestId)) {
            _executeWithdrawal(requestId);
        }
    }

    // Check if the votes are more than 50% of the total token supply
    function _hasMajorityVotes(uint256 requestId) internal view returns (bool) {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        Project storage project = projects[request.projectId];
        uint256 totalSupply = IERC20(project.tokenAddress).totalSupply();

        return request.votes > (totalSupply / 2);
    }

    // Execute the withdrawal if the majority vote is achieved
    function _executeWithdrawal(uint256 requestId) internal {
        WithdrawalRequest storage request = withdrawalRequests[requestId];
        Project storage project = projects[request.projectId];

        require(!request.executed, "Withdrawal already executed");
        require(project.balance >= request.amount, "Insufficient balance in project");

        request.executed = true;
        project.balance -= request.amount;
        IERC20(project.tokenAddress).transfer(request.recipient, request.amount);

        emit WithdrawalExecuted(requestId, request.projectId, request.amount, request.recipient);
    }
}

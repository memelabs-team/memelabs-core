// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TokenVesting is AccessControl {

    bytes32 public constant MEME_BUILDER_ROLE = keccak256("MEME_BUILDER_ROLE");
    uint256 public constant WEEK = 1 weeks;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MEME_BUILDER_ROLE, msg.sender);
    }

    struct VestingSchedule {
        IERC20 token; // Token to be vested
        uint256 totalAmount; // Total tokens vested for the investor
        uint256 start; // Vesting start timestamp
        uint256 duration; // Total vesting duration in seconds
        uint256 released; // Amount of tokens released so far
    }

    // Mapping of each investor and project ID to a vesting schedule
    mapping(address => mapping(uint256 => VestingSchedule)) public vestingSchedules;

    event VestingAdded(
        address indexed investor,
        address indexed token,
        uint256 totalAmount,
        uint256 start,
        uint256 duration,
        uint256 projectId
    );
    event TokensReleased(
        address indexed investor,
        address indexed token,
        uint256 amount
    );

    /**
     * @notice Adds a new vesting schedule for an investor.
     * @param _investor Address of the investor.
     * @param _token Address of the ERC20 token.
     * @param _totalAmount Total amount of tokens to vest.
     * @param _start Vesting start timestamp.
     * @param _duration Total duration of vesting (in seconds).
     * @param _projectId ID of the project associated with this vesting schedule.
     */
    function addVesting(
        address _investor,
        address _token,
        uint256 _totalAmount,
        uint256 _start,
        uint256 _duration,
        uint256 _projectId
    ) external onlyRole(MEME_BUILDER_ROLE) {
        require(_investor != address(0), "Invalid investor address");
        require(_token != address(0), "Invalid token address");
        require(_totalAmount > 0, "Vesting amount should be > 0");

        vestingSchedules[_investor][_projectId] = VestingSchedule({
            token: IERC20(_token),
            totalAmount: _totalAmount,
            start: _start,
            duration: _duration,
            released: 0
        });

        emit VestingAdded(_investor, _token, _totalAmount, _start, _duration, _projectId);
    }

    /**
     * @notice Allows an investor to release vested tokens from a specific vesting schedule.
     * @param _projectId ID of the project associated with the vesting schedule.
     */
    function releaseTokens(uint256 _projectId) external {
        VestingSchedule storage vesting = vestingSchedules[msg.sender][_projectId];
        uint256 vestedAmount = calculateVestedAmount(msg.sender, _projectId);
        uint256 unreleased = vestedAmount - vesting.released;

        require(unreleased > 0, "No tokens are due for release");

        vesting.released += unreleased;
        vesting.token.transfer(msg.sender, unreleased);

        emit TokensReleased(msg.sender, address(vesting.token), unreleased);
    }

    /**
     * @notice Calculates the amount of vested tokens for a specific vesting schedule.
     * This function provides a gradual release based on the elapsed time.
     * @param _investor Address of the investor.
     * @param _projectId ID of the project associated with the vesting schedule.
     * @return The total vested amount available based on time elapsed.
     */
    function calculateVestedAmount(
        address _investor,
        uint256 _projectId
    ) public view returns (uint256) {
        VestingSchedule storage vesting = vestingSchedules[_investor][_projectId];

        if (block.timestamp < vesting.start) {
            return 0;
        } else if (block.timestamp >= vesting.start + vesting.duration) {
            return vesting.totalAmount;
        } else {
            uint256 elapsedTime = block.timestamp - vesting.start;
            uint256 vestedAmount = (vesting.totalAmount * elapsedTime) / vesting.duration;
            return vestedAmount;
        }
    }

    /**
     * @notice Returns the amount of tokens that can currently be released for a specific vesting schedule.
     * @param _investor Address of the investor.
     * @param _projectId ID of the project associated with the vesting schedule.
     * @return The amount of tokens that are available for release.
     */
    function getReleasableAmount(
        address _investor,
        uint256 _projectId
    ) external view returns (uint256) {
        return calculateVestedAmount(_investor, _projectId) - vestingSchedules[_investor][_projectId].released;
    }
}

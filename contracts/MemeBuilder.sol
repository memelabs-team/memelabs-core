// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./MemeToken.sol";

interface IPancakeV3Factory {
    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
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

    function mint(MintParams calldata params)
        external
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );
}

contract MemeBuilder is AccessControl {
    address public platformFeeAddress;
    address public communityDropAddress;
    address public investorAddress;
    address public ownerAddress;
    address public communityTreasuryAddress;
    address public lpVaultAddress;

 
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    address public positionManagerAddress =
        0x427bF5b37357632377eCbEC9de3626C71A5396c1;
    address public factoryAddress = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);

        //TEST
        platformFeeAddress = msg.sender;
        communityDropAddress = msg.sender;
        investorAddress = msg.sender;
        ownerAddress = msg.sender;
        communityTreasuryAddress = msg.sender;
        lpVaultAddress = msg.sender;

 
    }

    struct MemeRequirement {
        address token;
        uint256 amount;
        uint256 platformFeeRate;
        uint256 communityDropRate;
        uint256 liquidityRate;
        uint256 investorRate;
        uint256 ownerRate;
        uint256 communityTreasuryRate;
    }

    struct MemeProposal {
        uint256 id;
        address owner;
        string name;
        string symbol;
        uint256 supply;
        string memeStory;
        string logo;
        string status;
        SocialChannel socialChannel;
        MemeRequirement memeRequirement;
        uint256 startVotingAt;
        uint256 startInvestmentAt;
        uint256 startVestingAt;
        uint voteYes;
        uint voteNo;
        uint256 risedAmount;
    }

    mapping(uint => mapping(address => bool)) memeVoters;

    struct SocialChannel {
        string X;
        string website;
    }

    MemeProposal[] private memeProposals_;

    event NewMemeProposal(address indexed user, uint256 indexed index);
    event Vote(address indexed voter, string result, uint indexed id);

    enum VoteResult {
        YES,
        NO
    }

    // uint votePeriod = 1 weeks;
    // uint investPeriod = 2 weeks;

    uint votePeriod = 2 minutes;
    uint investPeriod = 2 minutes;

    uint minimumVoter = 1;

    function setMinimumVoter(uint voter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minimumVoter = voter;
    }
    function setVotePeriod(uint period) external onlyRole(DEFAULT_ADMIN_ROLE) {
        votePeriod = period;
    }

    function setInvestPeriod(
        uint period
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        investPeriod = period;
    }

    // Function to create a new meme proposal
    function createMemeProposal(
        string memory _name,
        string memory _symbol,
        uint256 _supply,
        string memory _memeStory,
        string memory _logo,
        SocialChannel memory _socialChannel,
        MemeRequirement memory _memeRequirement
    ) external {
        MemeProposal[] storage proposals = memeProposals_;
        proposals.push(
            MemeProposal(
                proposals.length, // Assuming id is the index in the array
                msg.sender,
                _name,
                _symbol,
                _supply,
                _memeStory,
                _logo,
                "IN-PROCESS",
                _socialChannel,
                _memeRequirement,
                block.timestamp,
                block.timestamp + votePeriod,
                block.timestamp + votePeriod + investPeriod,
                0,
                0,
                0
            )
        );

        emit NewMemeProposal(msg.sender, proposals.length - 1);
    }

    event TokenCreated(
        address indexed tokenAddress,
        address indexed owner,
        uint256 initialSupply
    );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }
    // function provideFullRangeLiquidity(MintParams memory params) internal {
    //     // Define the full range by setting ticks from lowest possible (-887220) to highest possible (887220)
    //     int24 tickLower = -887220;
    //     int24 tickUpper = 887220;
    //     // Call mint to create a full-range liquidity position
    //     (
    //         uint256 tokenId,
    //         uint128 liquidity,
    //         uint256 amount0,
    //         uint256 amount1
    //     ) = positionManager.mint(
    //             params.token0,
    //             params.token1,
    //             params.fee,
    //             tickLower,
    //             tickUpper,
    //             params.amount0Desired,
    //             params.amount1Desired,
    //             params.amount0Min,
    //             params.amount1Min,
    //             params.recipient,
    //             params.deadline
    //         );

    //     // Optionally, handle tokenId or other returned values here for tracking purposes
    // }

    event SetFailed(uint256 indexed id);
    function cleanMeme(uint[] memory ids) public onlyRole(EXECUTOR_ROLE) {
        for (uint i = 0; i < ids.length; i++) {
            if (
                keccak256(bytes(memeProposals_[ids[i]].status)) ==
                keccak256(bytes("IN-PROCESS"))
            ) {
                if (
                    block.timestamp > memeProposals_[ids[i]].startInvestmentAt
                ) {
                    if (!voteResult(ids[i])) {
                        memeProposals_[ids[i]].status = "FAILED";
                        emit SetFailed(ids[i]);
                    }
                }
            }
        }
    }

    event LiquidityProvided(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

    function provideLP(
        address tokenA,
        address tokenB,
        uint24 fee,
        uint amountADesired,
        uint amountBDesired
    ) external {


        IPancakeV3Factory(factoryAddress).createPool(tokenA, tokenB, fee);

        require(IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired), "Transfer of tokenA failed");
        require(IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired), "Transfer of tokenB failed");

        IERC20(tokenA).approve(positionManagerAddress, amountADesired);
        IERC20(tokenB).approve(positionManagerAddress, amountBDesired);
        int24 tickLower = -887220;
        int24 tickUpper = 887220;
        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: tokenA,
            token1: tokenB,
            fee: fee,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amountADesired,
            amount1Desired: amountBDesired,
            amount0Min: 0,
            amount1Min: 0,
            recipient: msg.sender,
            deadline: block.timestamp + 1 hours
        });

        (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) = INonfungiblePositionManager(positionManagerAddress).mint(params);
        emit LiquidityProvided(tokenId, liquidity, amount0, amount1);
    }

    function mintMeme(uint[] memory ids) public onlyRole(EXECUTOR_ROLE) {
        for (uint i = 0; i < ids.length; i++) {
            require(
                keccak256(bytes(memeProposals_[ids[i]].status)) !=
                    keccak256(bytes("MINTED")),
                "Meme already minted"
            );

            uint totalSupply = memeProposals_[ids[i]].supply;
            uint256 platformFee = (totalSupply *
                memeProposals_[ids[i]].memeRequirement.platformFeeRate) / 10000;
            uint256 communityDrop = (totalSupply *
                memeProposals_[ids[i]].memeRequirement.communityDropRate) /
                10000;
            uint256 liquidity = (totalSupply *
                memeProposals_[ids[i]].memeRequirement.liquidityRate) / 10000;
            uint256 investor = (totalSupply *
                memeProposals_[ids[i]].memeRequirement.investorRate) / 10000;
            uint256 owner = (totalSupply *
                memeProposals_[ids[i]].memeRequirement.ownerRate) / 10000;
            uint256 communityTreasury = (totalSupply *
                memeProposals_[ids[i]].memeRequirement.communityTreasuryRate) /
                10000;

            //TODO: creatr token
            MemeToken newToken = new MemeToken(
                address(this),
                totalSupply,
                memeProposals_[ids[i]].name,
                memeProposals_[ids[i]].symbol
            );

            memeProposals_[ids[i]].status = "MINTED";

            //TODO: provide liquidity on pancakes swap v3
            // provideFullRangeLiquidity(
            //     MintParams(
            //         address(newToken),
            //         memeProposals_[ids[i]].memeRequirement.token,
            //         500,
            //         liquidity,
            //         memeProposals_[ids[i]].risedAmount,
            //         1,
            //         1,
            //         lpVaultAddress,
            //         block.timestamp + 1 minutes
            //     )
            // );

            //TODO: distribute token
            // IERC20(address(newToken)).transfer(platformFeeAddress, platformFee);
            // IERC20(address(newToken)).transfer(
            //     communityTreasuryAddress,
            //     communityTreasury
            // );

            // IERC20(address(newToken)).transfer(
            //     communityDropAddress,
            //     communityDrop
            // );

            //Move to vesting
            // IERC20(address(newToken)).transfer(investorAddress, investor);
            // IERC20(address(newToken)).transfer(ownerAddress, owner);
        }
    }

    // Function to retrieve meme proposals with a specific status
    function getMemeProposalsByStatus(
        string memory status
    ) external view returns (MemeProposal[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < memeProposals_.length; i++) {
            if (
                keccak256(bytes(memeProposals_[i].status)) ==
                keccak256(bytes(status))
            ) {
                count++;
            }
        }

        MemeProposal[] memory proposals = new MemeProposal[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < memeProposals_.length; i++) {
            if (
                keccak256(bytes(memeProposals_[i].status)) ==
                keccak256(bytes(status))
            ) {
                proposals[index] = memeProposals_[i];
                index++;
            }
        }
        return proposals;
    }

    function voteResult(uint256 id) public view returns (bool) {
        bool passedVoterAmountCondition = (memeProposals_[id].voteYes +
            memeProposals_[id].voteNo) >= minimumVoter;
        bool passedYesMorethanNoCondition = (memeProposals_[id].voteYes >
            memeProposals_[id].voteNo);
        return (passedVoterAmountCondition && passedYesMorethanNoCondition);
    }

    function invest(uint256 id, address token, uint amount) external {
        require(
            block.timestamp >= memeProposals_[id].startInvestmentAt &&
                block.timestamp < memeProposals_[id].startVestingAt,
            "Investment period has ended"
        );

        require(voteResult(id), "Vote result not passed");

        require(
            memeProposals_[id].memeRequirement.token == token,
            "Invalid address"
        );

        //TODO: validate invest amount

        memeProposals_[id].risedAmount += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function vote(uint256 id, VoteResult result) external {
        require(
            block.timestamp >= memeProposals_[id].startVotingAt &&
                block.timestamp < memeProposals_[id].startInvestmentAt,
            "Voting period has ended"
        );

        require(!memeVoters[id][msg.sender], "Voting already done");

        if (result == VoteResult.YES) {
            memeProposals_[id].voteYes++;
        } else {
            memeProposals_[id].voteNo++;
        }

        memeVoters[id][msg.sender] = true;

        emit Vote(msg.sender, result == VoteResult.YES ? "YES" : "NO", id);
    }
}

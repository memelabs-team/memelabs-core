// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./MemeToken.sol";


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
interface MemeVesting {
    function addVesting(
        address _investor,
        address _token,
        uint256 _totalAmount,
        uint256 _start,
        uint256 _duration,
        uint256 _projectId
    ) external;
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

interface ICommunityTreasury {
    function deposit(uint256 projectId, uint256 amount, address tokenAddress) external;
}

contract MemeBuilder is AccessControl, ERC721Holder {

    address public vestingAddress;
    address public communityTreasuryAddress;
    address public lpVaultAddress;

    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    address public positionManagerAddress = 0x427bF5b37357632377eCbEC9de3626C71A5396c1;
    address public factoryAddress = 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender);
    }

    struct SocialChannel {
        string X;
        string website;
        string telegram;
    }

    struct MemeRequirement {
        address token;
        uint256 amount;
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
        uint minimumVoter;
        uint minimumInvestmentAmount;
        uint maximumInvestmentAmount;
    }

    mapping(uint => mapping(address => bool)) memeVoters;
    mapping(uint => mapping(address => uint)) memeInvesterAmounts;
    mapping(uint => address[]) memeInvesterAddresses;



    MemeProposal[] private memeProposals;
    uint public releaseTokenTime = 1 weeks;

    int24 private constant MIN_TICK = -887220;
    int24 private constant MAX_TICK = 887220;
    int24 private constant TICK_SPACING = 10;
    uint24 private constant FEE = 500; // Fee for 0.05% tier
 
    event NewMemeProposal(address indexed user, uint256 indexed index);
    event Vote(address indexed voter, string result, uint indexed id);

    enum VoteResult {
        NO,
        YES
    }

    // uint votePeriod = 1 weeks;
    // uint investPeriod = 2 weeks;

    //For Testing
    uint public votePeriod = 5 minutes;
    uint public investPeriod = 5 minutes;
    uint public minimumVoter = 1;
    uint public voterRate = 100;// 1%

    function setVoterRate(uint _voteRate) external onlyRole(DEFAULT_ADMIN_ROLE)  {
        voterRate = _voteRate;
    }

    function setReleaseTokenTime(uint duration) external onlyRole(DEFAULT_ADMIN_ROLE) {
        releaseTokenTime = duration;
    }

    function setMinimumVoter(uint voter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        minimumVoter = voter;
    }

    function setVotePeriod(uint period) external onlyRole(DEFAULT_ADMIN_ROLE) {
        votePeriod = period;
    }

    function setPositionManagerAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        positionManagerAddress = addr;
    }

    function setFactoryAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        factoryAddress = addr;
    }

    function setInvestPeriod(
        uint period
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        investPeriod = period;
    }

    function setCommunityTreasuryContract( address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        communityTreasuryAddress = addr;
    }

    function setVestingContract(
        address addr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vestingAddress = addr;
    }

    function setLPVaultContract(
        address addr
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        lpVaultAddress = addr;
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

        MemeProposal[] storage proposals = memeProposals;

        //TODO: check valid tokenomic

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
                0,
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

    event SetFailed(uint256 indexed id);
    function cleanMeme(uint[] memory ids) public onlyRole(EXECUTOR_ROLE) {
        for (uint i = 0; i < ids.length; i++) {
            if (
                keccak256(bytes(memeProposals[ids[i]].status)) ==
                keccak256(bytes("IN-PROCESS"))
            ) {
                if (
                    block.timestamp > memeProposals[ids[i]].startInvestmentAt
                ) {
                    if (!isVoteResultPassed(ids[i])) {
                        memeProposals[ids[i]].status = "FAILED";
                        emit SetFailed(ids[i]);
                    }
                }
            }
        }
    }


    function mint(uint[] memory ids) public onlyRole(EXECUTOR_ROLE) {

        for (uint i = 0; i < ids.length; i++) {

            require(memeProposals[ids[i]].risedAmount >= memeProposals[ids[i]].memeRequirement.amount , "Not enough raised amount");
            
            require(
                keccak256(bytes(memeProposals[ids[i]].status)) !=
                    keccak256(bytes("MINTED")),
                "Meme already minted"
            );

            uint totalSupply = memeProposals[ids[i]].supply;
            uint totalRaisedAmount = memeProposals[ids[i]].risedAmount;

            uint256 liquidity = (totalSupply *
                memeProposals[ids[i]].memeRequirement.liquidityRate) / 10000;
            uint256 amountForInvestor = (totalSupply *
                memeProposals[ids[i]].memeRequirement.investorRate) / 10000;
            uint256 ownerAmount = (totalSupply *
                memeProposals[ids[i]].memeRequirement.ownerRate) / 10000;
            uint256 communityTreasury = (totalSupply *
                memeProposals[ids[i]].memeRequirement.communityTreasuryRate) /
                10000;


            //TODO: creatr token
            MemeToken newToken = new MemeToken(
                address(this),
                totalSupply,
                memeProposals[ids[i]].name,
                memeProposals[ids[i]].symbol
            );

            memeProposals[ids[i]].status = "MINTED";

            //Provide liquidity on pancakes swap v3
            createPool(address(newToken),memeProposals[ids[i]].memeRequirement.token,liquidity,totalRaisedAmount);
            provideLP(address(newToken),memeProposals[ids[i]].memeRequirement.token,liquidity,totalRaisedAmount);

            //Deposit tokens to community treasury
            IERC20(address(newToken)).approve(communityTreasuryAddress, communityTreasury);
            ICommunityTreasury(communityTreasuryAddress).deposit(ids[i], communityTreasury, address(newToken));

            //create vesting
            for (uint256 j = 0; j < memeInvesterAddresses[ids[i]].length; j++) {

                address investerAddress = memeInvesterAddresses[ids[i]][j];

                uint investmentAmount = memeInvesterAmounts[ids[i]][
                    investerAddress
                ];

                uint256 percentageOfPool = (investmentAmount * 10 ** 18) /
                    totalRaisedAmount;
                uint256 tokensReceived = (amountForInvestor *
                    percentageOfPool) / 10 ** 18;

                MemeVesting(vestingAddress).addVesting(
                    investerAddress,
                    address(newToken),
                    tokensReceived,
                    block.timestamp,
                    releaseTokenTime,
                    ids[i]
                );
            }

            //for owner
            MemeVesting(vestingAddress).addVesting(
                    memeProposals[ids[i]].owner,
                    address(newToken),
                    ownerAmount,
                    block.timestamp,
                    releaseTokenTime,
                    ids[i]
            );


            IERC20(address(newToken)).transfer(
                vestingAddress,
                amountForInvestor
            );

          
        }
    }

    function hasAlreadyVoted(
        uint id,
        address voter
    ) public view returns (bool) {
        return memeVoters[id][voter];
    }

    // Function to retrieve meme proposals with a specific status
    function getMemeProposalsByStatus(
        string memory status
    ) external view returns (MemeProposal[] memory) {

        uint256 count = memeProposals.length;
        MemeProposal[] memory proposals = new MemeProposal[](count);
        uint256 index = 0;

        for (uint256 i = 0; i < memeProposals.length; i++) {
            if (
                keccak256(bytes(memeProposals[i].status)) ==
                keccak256(bytes(status))
            ) {
                proposals[index] = memeProposals[i];
                index++;
            }
        }

        // truncate the array to the correct length
        assembly {
            mstore(proposals, index)
        }

        return proposals;
    }

    function getMyProposals(
        uint256 _page,
        uint256 _pageSize,
        address owner
    )
        external
        view
        returns (MemeProposal[] memory)
    {
       
        uint256 count = memeProposals.length;
        MemeProposal[] memory proposals = new MemeProposal[](_pageSize);
        uint256 index = 0;

        // calculate the start index based on the page number
        uint256 startIndex = _page * _pageSize;

        for (uint256 i = startIndex; i < memeProposals.length; i++) {
            if (
                 owner == memeProposals[i].owner
            ) {
                if (index >= _pageSize) {
                    break;
                }
                MemeProposal memory proposal = memeProposals[i];
                proposal.minimumVoter = calculateVoterAmount(memeProposals[i].id);
                (proposal.minimumInvestmentAmount, proposal.maximumInvestmentAmount) = calculateInvestmentAmountPerAddress(proposal.memeRequirement.amount);
                proposals[index] = proposal;
                index++;
            }
        }

        // truncate the array to the correct length
        assembly {
            mstore(proposals, index)
        }

        return proposals;
    }

     
    function getMyVotedProposals(
        uint256 _page,
        uint256 _pageSize,
        address _address
    )
        external
        view
        returns (MemeProposal[] memory)
    {
       
        uint256 count = memeProposals.length;
        MemeProposal[] memory proposals = new MemeProposal[](_pageSize);
        uint256 index = 0;

        // calculate the start index based on the page number
        uint256 startIndex = _page * _pageSize;

        for (uint256 i = startIndex; i < memeProposals.length; i++) {
            if (
                memeInvesterAmounts[memeProposals[i].id][_address] > 0
            ) {
                if (index >= _pageSize) {
                    break;
                }
                MemeProposal memory proposal = memeProposals[i];
                proposal.minimumVoter = calculateVoterAmount(memeProposals[i].id);
                (proposal.minimumInvestmentAmount, proposal.maximumInvestmentAmount) = calculateInvestmentAmountPerAddress(proposal.memeRequirement.amount);
                proposals[index] = proposal;
                index++;
            }
        }

        // truncate the array to the correct length
        assembly {
            mstore(proposals, index)
        }

        return proposals;
    }

    function getMyInvestedProposals(
        uint256 _page,
        uint256 _pageSize,
        address _address
    )
        external
        view
        returns (MemeProposal[] memory)
    {
       
        uint256 count = memeProposals.length;
        MemeProposal[] memory proposals = new MemeProposal[](_pageSize);
        uint256 index = 0;

        // calculate the start index based on the page number
        uint256 startIndex = _page * _pageSize;

        for (uint256 i = startIndex; i < memeProposals.length; i++) {
            if (
                memeInvesterAmounts[memeProposals[i].id][_address] > 0
            ) {
                if (index >= _pageSize) {
                    break;
                }
                MemeProposal memory proposal = memeProposals[i];
                proposal.minimumVoter = calculateVoterAmount(memeProposals[i].id);
                (proposal.minimumInvestmentAmount, proposal.maximumInvestmentAmount) = calculateInvestmentAmountPerAddress(proposal.memeRequirement.amount);
                proposals[index] = proposal;
                index++;
            }
        }

        // truncate the array to the correct length
        assembly {
            mstore(proposals, index)
        }

        return proposals;
    }

    function getVotingProposals(
        uint256 _page,
        uint256 _pageSize
    )
        external
        view
        returns (MemeProposal[] memory)
    {
       
        uint256 count = memeProposals.length;
        MemeProposal[] memory proposals = new MemeProposal[](_pageSize);
        uint256 index = 0;

        // calculate the start index based on the page number
        uint256 startIndex = _page * _pageSize;

        for (uint256 i = startIndex; i < memeProposals.length; i++) {
            if (
                keccak256(bytes(memeProposals[i].status)) ==
                keccak256(bytes("IN-PROCESS")) &&
                block.timestamp < memeProposals[i].startInvestmentAt &&
                !isVoteResultPassed(memeProposals[i].id)
            ) {
                if (index >= _pageSize) {
                    break;
                }
                MemeProposal memory proposal = memeProposals[i];
                proposal.minimumVoter = calculateVoterAmount(memeProposals[i].id);
                (proposal.minimumInvestmentAmount, proposal.maximumInvestmentAmount) = calculateInvestmentAmountPerAddress(proposal.memeRequirement.amount);
                proposals[index] = proposal;
                index++;
            }
        }

        // truncate the array to the correct length
        assembly {
            mstore(proposals, index)
        }

        return proposals;
    }

    function getInvestingProposals(  
        uint256 _page,
        uint256 _pageSize)
        external
        view
        returns (MemeProposal[] memory)
    {
    
        uint256 count = memeProposals.length;
        MemeProposal[] memory proposals = new MemeProposal[](_pageSize);
        uint256 index = 0;

        // calculate the start index based on the page number
        uint256 startIndex = _page * _pageSize;

        for (uint256 i = startIndex; i < memeProposals.length; i++) {
            if (
                keccak256(bytes(memeProposals[i].status)) == keccak256(bytes("IN-PROCESS")) &&
                block.timestamp < memeProposals[i].startVestingAt &&
                isVoteResultPassed(memeProposals[i].id)
            ) {
                if (index >= _pageSize) {
                    break;
                }
                MemeProposal memory proposal = memeProposals[i];
                proposal.minimumVoter = calculateVoterAmount(memeProposals[i].id);
                (proposal.minimumInvestmentAmount, proposal.maximumInvestmentAmount) = calculateInvestmentAmountPerAddress(proposal.memeRequirement.amount);
                proposals[index] = proposal;
                index++;
            }
        }

        // truncate the array to the correct length
        assembly {
            mstore(proposals, index)
        }

        return proposals;
    }

    function getMentedMemes( 
        uint256 _page,
        uint256 _pageSize
        ) external view returns (MemeProposal[] memory) {
         uint256 count = memeProposals.length;
        MemeProposal[] memory proposals = new MemeProposal[](_pageSize);
        uint256 index = 0;

        // calculate the start index based on the page number
        uint256 startIndex = _page * _pageSize;

        for (uint256 i = startIndex; i < memeProposals.length; i++) {
            if (
                 keccak256(bytes(memeProposals[i].status)) == keccak256(bytes("MINTED"))
            ) {
                if (index >= _pageSize) {
                    break;
                }
                MemeProposal memory proposal = memeProposals[i];
                proposal.minimumVoter = calculateVoterAmount(memeProposals[i].id);
                (proposal.minimumInvestmentAmount, proposal.maximumInvestmentAmount) = calculateInvestmentAmountPerAddress(proposal.memeRequirement.amount);
                proposals[index] = proposal;
                index++;
            }
        }

        // truncate the array to the correct length
        assembly {
            mstore(proposals, index)
        }

        return proposals;
    }

    /**
     * @notice Determines if the vote result for a given proposal has passed.
     * @dev Checks if the total number of votes meets the minimum voter requirement.
     *      Also checks if the number of 'yes' votes is greater than the number of 'no' votes.
     * @param id The ID of the meme proposal.
     * @return True if both conditions are met, false otherwise.
     */
    function isVoteResultPassed(uint256 id) public view returns (bool) {
        // Check if the total number of votes meets the minimum voter requirement
        
        bool passedVoterAmountCondition = (memeProposals[id].voteYes + memeProposals[id].voteNo) >= minimumVoter;

        // Check if the number of 'yes' votes is greater than the number of 'no' votes
        bool passedYesMoreThanNoCondition = memeProposals[id].voteYes > memeProposals[id].voteNo;

        // Return true if both conditions are met
        return (passedVoterAmountCondition && passedYesMoreThanNoCondition);
    }

    /**
     * @notice Calculates the minimum and maximum investment amount per address based on the required amount.
     * @param requiredAmount The required amount to be used for investment calculations.
     * @return minimumInvestmentAmount The calculated minimum investment amount per address.
     * @return maximumInvestmentAmount The calculated maximum investment amount per address.
     */
    function calculateInvestmentAmountPerAddress(uint requiredAmount) internal view returns (uint, uint) {
        // Calculate the minimum investment amount by scaling the required amount
        uint256 minimumInvestmentAmount = (requiredAmount * voterRate) / 10000 / 1e18;

        // Calculate the maximum investment amount as double the minimum investment amount
        uint maximumInvestmentAmount = minimumInvestmentAmount * 2;

        return (minimumInvestmentAmount, maximumInvestmentAmount);
    }

    /**
     * @notice Calculates the voter amount for a given proposal based on its meme requirement.
     * @param id The ID of the meme proposal.
     * @return The calculated voter amount.
     */
    function calculateVoterAmount(uint256 id) internal view returns (uint256) {
        // Retrieve the required amount from the meme proposal
        uint256 requiredAmount = memeProposals[id].memeRequirement.amount;
        uint256 voterAmount = (requiredAmount * voterRate) / 10000 / 1e18;

        return voterAmount;
    }

   
    function invest(uint256 id, address token, uint amount) external {
        require(
            isVoteResultPassed(id) && block.timestamp < memeProposals[id].startVestingAt,
            "Investment period has ended"
        );

        require(isVoteResultPassed(id), "Vote result not passed");

        require(
            memeProposals[id].memeRequirement.token == token,
            "Invalid address"
        );

        // (uint minimumInvestmentAmount, uint maximumInvestmentAmount) = calculateInvestmentAmountPerAddress(memeProposals[id].memeRequirement.amount);
        // require(amount >= minimumInvestmentAmount && amount <= maximumInvestmentAmount, "Invalid amount");

        memeProposals[id].risedAmount += amount;
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        if (memeInvesterAmounts[id][msg.sender]==0){
            memeInvesterAddresses[id].push(msg.sender);
        }
        memeInvesterAmounts[id][msg.sender] += amount;

    }

    function vote(uint256 id, VoteResult result) external {
        require(
            block.timestamp >= memeProposals[id].startVotingAt &&
                block.timestamp < memeProposals[id].startInvestmentAt,
            "Voting period has ended"
        );

        require(!memeVoters[id][msg.sender], "Voting already done");

        if (result == VoteResult.YES) {
            memeProposals[id].voteYes++;
        } else {
            memeProposals[id].voteNo++;
        }

        memeVoters[id][msg.sender] = true;

        emit Vote(msg.sender, result == VoteResult.YES ? "YES" : "NO", id);
    }

    function createPool(address tokenA,address tokenB, uint256 amountADesired, uint256 amountBDesired) internal {

        IPancakeV3Factory(factoryAddress).createPool(tokenA, tokenB, FEE);
        address pool = IPancakeV3Factory(factoryAddress).getPool(
            tokenA,
            tokenB,
            FEE
        );

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

    function provideLP(address tokenA, address tokenB, uint256 amountADesired,uint256 amountBDesired) internal returns (uint256){
       

        IERC20(tokenA).approve(positionManagerAddress, amountADesired);
        IERC20(tokenB).approve(positionManagerAddress, amountBDesired);

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
            ,
            ,
             
        ) = INonfungiblePositionManager(positionManagerAddress).mint(params);



        //TODO: implement refund
        return tokenId;
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
    
}

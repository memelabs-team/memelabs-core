// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract MemeBuilder is AccessControl {
    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

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

    uint votePeriod = 1 weeks;
    uint investPeriod = 2 weeks;
    uint minimumVoter = 5;

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

        require(
            keccak256(bytes(memeProposals_[id].status)) ==
                keccak256(bytes("VOTING")),
            "Proposal is not voting"
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

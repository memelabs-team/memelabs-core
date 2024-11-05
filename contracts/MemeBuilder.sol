// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract MemeBuilder {
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
        string name;
        uint256 supply;
        string memeStory;
        string logo;
        string status;
        SocialChannel socialChannel;
        MemeRequirement memeRequirement;
    }

    struct SocialChannel {
        string X;
        string website;
    }

    mapping(address => MemeProposal[]) private memeProposals_;
    event NewMemeProposal(address indexed user, uint256 indexed index);

    // Function to create a new meme proposal
    function createMemeProposal(
        string memory _name,
        uint256 _supply,
        string memory _memeStory,
        string memory _logo,
        address _token,
        uint256 _minAmount,
        uint256 _platformFeeRate,
        uint256 _communityDropRate,
        uint256 _liquidityRate,
        uint256 _investorRate,
        uint256 _ownerRate,
        uint256 _communityTreasuryRate
    ) external {
        // Uncomment this line to use console.log
        // console.log("Creating Meme Proposal: Name = %s, Supply = %s", _name, _supply);

        MemeProposal[] storage proposals = memeProposals_[msg.sender];
        proposals.push(
            MemeProposal(
                proposals.length,  // Assuming id is the index in the array
                _name,
                _supply,
                _memeStory,
                _logo,
                "VOTING",
                SocialChannel("", ""),
                MemeRequirement(
                    _token,
                    _minAmount,
                    _platformFeeRate,
                    _communityDropRate,
                    _liquidityRate,
                    _investorRate,
                    _ownerRate,
                    _communityTreasuryRate
                )
            )
        );
    

        emit NewMemeProposal(msg.sender, proposals.length - 1);
    }

    // Function to retrieve meme proposals with a specific status
    function getMemeProposalsByStatus(string memory status) external view returns (MemeProposal[] memory) {
        // Uncomment this line to use console.log
        // console.log("Retrieving Meme Proposals with Status: %s", status);

        uint256 count = 0;
        for (uint256 i = 0; i < memeProposals_[msg.sender].length; i++) {
            if (keccak256(bytes(memeProposals_[msg.sender][i].status)) == keccak256(bytes(status))) {
                count++;
            }
        }

        MemeProposal[] memory proposals = new MemeProposal[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < memeProposals_[msg.sender].length; i++) {
            if (keccak256(bytes(memeProposals_[msg.sender][i].status)) == keccak256(bytes(status))) {
                proposals[index] = memeProposals_[msg.sender][i];
                index++;
                // Uncomment this line to use console.log
                // console.log("Meme Proposal Found: ID = %s", memeProposals_[msg.sender][i].id);
            }
        }
        return proposals;
    }
}


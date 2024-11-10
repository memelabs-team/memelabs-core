import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import hre from "hardhat";

describe("MemeLab", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployOneYearLockFixture() {
    // const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
    // const ONE_GWEI = 1_000_000_000;

    // const lockedAmount = ONE_GWEI;
    // const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS;

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const MemeBuilder = await hre.ethers.getContractFactory("MemeBuilder");
    const memeBuilder = await MemeBuilder.deploy();

    const TokenVesting = await hre.ethers.getContractFactory("TokenVesting");
    const tokenVesting = await TokenVesting.deploy();

    const MemeUSDT = await hre.ethers.getContractFactory("MemeUSDT");
    const memeUSDT = await MemeUSDT.deploy();

    const CommunityTreasury = await hre.ethers.getContractFactory("CommunityTreasury");
    const communityTreasury = await CommunityTreasury.deploy();
    

    const NonfungiblePositionManager = await hre.ethers.getContractFactory("MockNonfungiblePositionManager");
    const nonfungiblePositionManager = await NonfungiblePositionManager.deploy();

    const MockPancakeV3Factory = await hre.ethers.getContractFactory("MockPancakeV3Factory");
    const mockPancakeV3Factory = await MockPancakeV3Factory.deploy();


    const MockUniswapV3Pool = await hre.ethers.getContractFactory("MockUniswapV3Pool");
    const mockUniswapV3Pool = await MockUniswapV3Pool.deploy();
    
    const tokenVestingAddress = await tokenVesting.getAddress();


    //setVestingContract
    await memeBuilder.setVestingContract(tokenVestingAddress);
    await memeBuilder.setCommunityTreasuryContract(await communityTreasury.getAddress())
    await memeBuilder.setPositionManagerAddress(await nonfungiblePositionManager.getAddress())
    await memeBuilder.setFactoryAddress(await mockPancakeV3Factory.getAddress())
    await mockPancakeV3Factory.setMockPool(await mockUniswapV3Pool.getAddress())

    //grantRole
    await tokenVesting.grantRole(await tokenVesting.MEME_BUILDER_ROLE(), memeBuilder.getAddress())

    return { memeBuilder, tokenVesting, memeUSDT, owner, otherAccount, communityTreasury,nonfungiblePositionManager, mockPancakeV3Factory };
  }

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      const { memeBuilder, tokenVesting, owner, otherAccount } = await loadFixture(deployOneYearLockFixture);

      // expect(await lock.unlockTime()).to.equal(unlockTime);
    });
    it("Should create new proposal", async function () {

      const { memeBuilder,tokenVesting, memeUSDT, owner, otherAccount } = await loadFixture(deployOneYearLockFixture);

      const memeUSDTAddress = await memeUSDT.getAddress();
      const memeBuilderAddress = await memeBuilder.getAddress();

      // Set up the test data for createMemeProposal
      const proposalName = "Meme Token";
      const proposalSymbol = "MTK";
      const proposalSupply = hre.ethers.parseUnits("1000000", 18); // 100,000,000 with 18 decimals
      const memeStory = "This is a story of a meme token.";
      const logo = "logo_url";

      // SocialChannel structure
      const socialChannel = {
        X: "x_channel",
        website: "https://website.com",
        telegram: "https://t.me/channel",
      };

      // MemeRequirement structure
      const memeRequirement = {
        token: memeUSDTAddress, // Replace with actual token address if needed
        amount: hre.ethers.parseUnits("10000", 18), // Example required amount
        // platformFeeRate: 500, // Example fee rate (5%)
        // communityDropRate: 1000, // Example rate (10%)
        liquidityRate: 2000, // Example rate (20%)
        investorRate: 3000, // Example rate (30%)
        ownerRate: 1000, // Example rate (10%)
        communityTreasuryRate: 1000, // Example rate (10%)
      };

      // Call createMemeProposal and capture the event
      await expect(
        memeBuilder
          .connect(owner)
          .createMemeProposal(
            proposalName,
            proposalSymbol,
            proposalSupply,
            memeStory,
            logo,
            socialChannel,
            memeRequirement,

          )
      )
        .to.emit(memeBuilder, "NewMemeProposal")
        .withArgs(owner.address, 0); // Expect event with correct args (first proposal should have id 0)

      // Retrieve the proposal and verify details
      const proposalsByStatus = await memeBuilder.getMemeProposalsByStatus("IN-PROCESS");
      // console.log(proposalsByStatus)
      const createdProposal = proposalsByStatus[0];

      // Verify each field in the proposal
      expect(createdProposal.name).to.equal(proposalName);
      expect(createdProposal.symbol).to.equal(proposalSymbol);
      expect(createdProposal.supply).to.equal(proposalSupply);
      expect(createdProposal.memeStory).to.equal(memeStory);
      expect(createdProposal.logo).to.equal(logo);
      expect(createdProposal.status).to.equal("IN-PROCESS");
      expect(createdProposal.socialChannel.X).to.equal(socialChannel.X);
      expect(createdProposal.socialChannel.website).to.equal(socialChannel.website);
      expect(createdProposal.socialChannel.telegram).to.equal(socialChannel.telegram);
      expect(createdProposal.memeRequirement.token).to.equal(memeRequirement.token);
      expect(createdProposal.memeRequirement.amount).to.equal(memeRequirement.amount);
      //expect(createdProposal.memeRequirement.platformFeeRate).to.equal(memeRequirement.platformFeeRate);
      //expect(createdProposal.memeRequirement.communityDropRate).to.equal(memeRequirement.communityDropRate);
      expect(createdProposal.memeRequirement.liquidityRate).to.equal(memeRequirement.liquidityRate);
      expect(createdProposal.memeRequirement.investorRate).to.equal(memeRequirement.investorRate);
      expect(createdProposal.memeRequirement.ownerRate).to.equal(memeRequirement.ownerRate);
      expect(createdProposal.memeRequirement.communityTreasuryRate).to.equal(memeRequirement.communityTreasuryRate);

      //Vote
      console.log("getVotingProposals (1):", await memeBuilder.getVotingProposals(0,1))

      await memeBuilder.vote(0, 1);
      await hre.ethers.provider.send("evm_increaseTime", [5 * 60]);
      await hre.ethers.provider.send("evm_mine"); // Mine the next block with the new timestamp
      console.log("getVotingProposals (2):", await memeBuilder.getVotingProposals(0,1))

      //Approve
      console.log("Balance of owner:",await memeUSDT.balanceOf(owner.address))
      await memeUSDT.connect(owner).approve(memeBuilderAddress, hre.ethers.parseUnits("10000", 18));
      


      //Invest
      console.log("getInvestingProposals (1):", await memeBuilder.getInvestingProposals(0,1))
      await memeBuilder.connect(owner).invest(0, memeUSDTAddress, hre.ethers.parseUnits("10000", 18));


      await hre.ethers.provider.send("evm_increaseTime", [5 * 60]);
      await hre.ethers.provider.send("evm_mine"); // Mine the next block with the new timestamp

      console.log("getInvestingProposals (2):", await memeBuilder.getInvestingProposals(0,1))
      console.log(await memeUSDT.balanceOf(memeBuilderAddress))

      console.log(await memeBuilder.isVoteResultPassed(0))
      // console.log( await memeBuilder.getMemeProposalsByStatus("IN-PROCESS"))

      console.log("createdProposal:", createdProposal.id)
      await memeBuilder.connect(owner).mint([createdProposal.id])

      console.log(await memeUSDT.balanceOf(memeBuilderAddress))

      console.log("getMentedMemes (1):", await memeBuilder.getMentedMemes(0,1))




      ///Vesting phase
      await hre.ethers.provider.send("evm_increaseTime", [60 * 60 * 24 * 4]);
      await hre.ethers.provider.send("evm_mine"); // Mine the next block with the new timestamp


      console.log("ReleasableAmount(1):", await tokenVesting.getReleasableAmount(owner.address,createdProposal.id))
      const releaseable1 = await tokenVesting.getReleasableAmount(owner.address,createdProposal.id)

      await  tokenVesting.releaseTokens(createdProposal.id)
      console.log("ReleasableAmount(2):", await tokenVesting.getReleasableAmount(owner.address,createdProposal.id))


      await hre.ethers.provider.send("evm_increaseTime", [60 * 60 * 24 * 8]);
      await hre.ethers.provider.send("evm_mine"); // Mine the next block with the new timestamp

      console.log("ReleasableAmount(3):", await tokenVesting.getReleasableAmount(owner.address,createdProposal.id))
      const releaseable2 =  await tokenVesting.getReleasableAmount(owner.address,createdProposal.id)

      console.log("Total Release(4):",  releaseable2 + releaseable1)

     //getMyProposals
     console.log("getMyProposals:",await memeBuilder.getMyProposals(0,1,owner.address))
     console.log("getMyProposals:",await memeBuilder.getMyProposals(0,1,otherAccount.address))


     console.log("getVotedProposals:",await memeBuilder.getMyVotedProposals(0,1,owner.address))
     console.log("getVotedProposals:",await memeBuilder.getMyVotedProposals(0,1,otherAccount.address))

     console.log("getMyInvestedProposals:",await memeBuilder.getMyInvestedProposals(0,1,owner.address))
     console.log("getMyInvestedProposals:",await memeBuilder.getMyInvestedProposals(0,1,otherAccount.address))

    });

    // it("Should vote for the proposal", async function () {

    //   const { memeBuilder, memeUSDT, owner, otherAccount } = await loadFixture(deployOneYearLockFixture);

    //   const proposalsByStatus = await memeBuilder.getMemeProposalsByStatus("IN-PROCESS");

    //   console.log(proposalsByStatus)

    // });

    // it("Should fail if the unlockTime is not in the future", async function () {
    //   // We don't use the fixture here because we want a different deployment
    //   const latestTime = await time.latest();
    //   const Lock = await hre.ethers.getContractFactory("Lock");
    //   await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
    //     "Unlock time should be in the future"
    //   );
    // });
  });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});

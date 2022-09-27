import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import { deployContract } from "../scripts/deploy";
const getContract = () => loadFixture(deployContract);

describe("Bets", function () {

    describe("Min bet", () => {
      it("Should get MIN bet", async function () {
        const contract = await getContract()
  
        const bet = ethers.utils.parseEther("0.005")
        const minBet = await contract.getMinBet()
  
        expect(bet).to.be.equal(minBet)
      });

      it("Should set MIN bet", async function () {
        const contract = await getContract()
        
        const newMinBet = ethers.utils.parseEther("0.1")
        await contract.setMinBet(newMinBet)

        const actualBet = await contract.getMinBet()
  
        expect(newMinBet).to.be.equal(actualBet)
      });

      it("Should NOT set MIN bet to 0", async function () {
        const contract = await getContract()
        
        const newMinBet = ethers.utils.parseEther("0")

        await expect(contract.setMinBet(newMinBet)).to.be.revertedWith("The minimum bet must be higher than 0")
      });
    })

    describe("Max bet", () => {
      it("Should get MAX bet", async function () {
        const contract = await getContract()
  
        const bet = ethers.utils.parseEther("0.01")
        const maxBet = await contract.getMaxBet()
  
        expect(bet).to.be.equal(maxBet)
      });

      it("Should set MAX bet", async function () {
        const contract = await getContract()
        
        const newMaxBet = ethers.utils.parseEther("0.1")
        await contract.setMaxBet(newMaxBet)

        const actualBet = await contract.getMaxBet()
  
        expect(newMaxBet).to.be.equal(actualBet)
      });

      it("Should NOT set MAX bet lower than min bet", async function () {
        const contract = await getContract()
        
        const newMaxBet = ethers.utils.parseEther("0")

        await expect(contract.setMaxBet(newMaxBet)).to.be.revertedWith("The maximum bet must be higher than the minimum bet")
      });
      
    })
});

describe("Ownable", () => {
  it("Should NOT set MIN bet if is not an admin", async () => {
    const contract = await getContract()

    const newMin = ethers.utils.parseEther("0.0001")
    const [_owner, other] = await ethers.getSigners()

    await expect(contract.connect(other).setMinBet(newMin)).to.be.revertedWith("You are not an admin")

  })

  it("Should NOT set MAX bet if is not an admin", async () => {
    const contract = await getContract()

    const newMaxBet = ethers.utils.parseEther("0.0001")
    const [_owner, other] = await ethers.getSigners()

    await expect(contract.connect(other).setMaxBet(newMaxBet)).to.be.revertedWith("You are not an admin")

  })
})

describe("Bet", () => {
  it("Bet should be higher than minimum bet", async () => {
    const contract = await getContract()
    const bet = ethers.utils.parseEther("0.01")

    await expect(contract.bet(15, {value:bet})).to.be.eventually.ok
  })

  it("Should revert if bet is lower than minimum", async () => {
    const contract = await getContract()
    const bet = ethers.utils.parseEther("0")

    await expect(contract.bet(15, {value:bet})).to.be.revertedWith("The bet must be higher or equal than min bet")
  })

  it("Bet should be lower than maximum bet", async () => {
    const contract = await getContract()
    const bet = ethers.utils.parseEther("0.01")

    await expect(contract.bet(15, {value:bet})).to.be.eventually.ok
  })

  it("Should revert if bet is higher than maximum", async () => {
    const contract = await getContract()
    const bet = ethers.utils.parseEther("0.1")

    await expect(contract.bet(15, {value:bet})).to.be.revertedWith("The bet must be lower or equal than max bet")
  })

})
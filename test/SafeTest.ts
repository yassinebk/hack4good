import { assert, expect } from "chai";
import { Signer } from "ethers";
import { ethers } from "hardhat";
import deployTokens from "../scripts/00-tokens";
import { DecentralizedOrganisationManager, ExchangeToken, GovernanceToken, SafeDAO } from "../typechain-types";
import { CharityDAO } from "../typechain-types/contracts/CharityDAO.sol";




describe("Safe", function () {

    let deployedGOV: GovernanceToken;
    let deployedEXC: ExchangeToken;
    let deployedCharity: CharityDAO;
    let deployedDOM: DecentralizedOrganisationManager;
    let safeDAO: SafeDAO;
    let shareHolders;
    let signers: Signer[];
    this.beforeAll(async () => {
        signers = await ethers.getSigners();
        shareHolders = signers.slice(0, 3);
        console.log(signers.length);
        const deployedContracts = await deployTokens();
        deployedGOV = deployedContracts.deployedGOV;
        deployedEXC = deployedContracts.deployedEXC;
        deployedCharity = deployedContracts.deployedCharity as CharityDAO;
        deployedDOM = deployedContracts.deployedDOM as DecentralizedOrganisationManager;
    })
    describe("Governance Contract Testing", async function () {

        it("Contract is deployed", async () => {
            await expect(deployedDOM.deployed()).to.eq(true);
        });

        it("Contract is initialized", async () => {

            const governanceTokenAddress = await deployedDOM.getGovernanceToken();
            assert(governanceTokenAddress === deployedGOV.address);

            const exchangeTokenAddress = await deployedDOM.getExchangeToken();
            assert(exchangeTokenAddress === deployedEXC.address);
        }
        )

        it("Only owning parties can updateTokens", async () => {
            const connectedToOtherSigner = deployedDOM.connect(signers[4])
            await expect(connectedToOtherSigner.updateGovernanceToken(deployedGOV.address)).to.be.revertedWith("Only owning shareholders can update the governance token")
            await expect(connectedToOtherSigner.updateExchangeToken(deployedEXC.address)).to.be.revertedWith("Only owning shareholders can update the governance token")
            await expect(deployedDOM.updateGovernanceToken(deployedGOV.address)).to.emit(deployedDOM, "GovernanceTokenUpdated")
            await expect(deployedDOM.updateExchangeToken(deployedEXC.address)).to.be.emit(deployedDOM, "ExchangeTokenUpdated")

        })

        it("Create Group", async () => {

        })





    })

})
import { ethers, network, upgrades } from "hardhat";
import { developmentChains } from "../helper-hardhat-config";
import { DecentralizedOrganisationManager__factory, GovernanceToken__factory } from "../typechain-types";
import { CharityDAO } from "../typechain-types/contracts/CharityDAO.sol";
import { verify } from "../utils/verify";

export const deployTokens = async function () {

  const gas = await ethers.provider.getGasPrice()

  const signers = (await ethers.getSigners()).slice(0, 5);

  const GOVtokenFactory: GovernanceToken__factory = await ethers.getContractFactory("GovernanceToken");

  const deployedGOV = await (await GOVtokenFactory.deploy()).deployed();
  console.log("GOV deployed to:", deployedGOV.address);

  const EXCtokenFactory: GovernanceToken__factory = await ethers.getContractFactory("ExchangeToken");
  const deployedEXC = await (await EXCtokenFactory.deploy()).deployed();
  console.log("EXC deployed to:", deployedEXC.address);

  const domFactory: DecentralizedOrganisationManager__factory = await ethers.getContractFactory("DecentralizedOrganisationManager");
  const deployedDOM = await upgrades.deployProxy(domFactory, [deployedGOV.address, signers], {
    initializer: "initialize",
    unsafeAllow: ["delegatecall"],
  });

  console.log("DOM deployed to:", deployedDOM.address);


  const charityFactory = await ethers.getContractFactory("CharityDAO");

  const deployedCharity = await upgrades.deployProxy(charityFactory, [deployedDOM.address], {
    initializer: "initialize",
  });
  console.log("Charity deployed to:", deployedCharity.address);



  const safeFactory = await ethers.getContractFactory("SafeDAO");
  const safeDAO = await safeFactory.deploy(
    deployedGOV.address,
    deployedEXC.address,
    {
      gasPrice: gas,
      gasLimit: 30000000

    }
  );



  await safeDAO.deployed();

  console.log("DAO deployed to:", safeDAO.address);

  const balance = await deployedGOV.balanceOf(signers[0].address)
  console.log("Balance ", balance.toString())

  await deployedGOV.approve(safeDAO.address, balance);
  await deployedEXC.approve(safeDAO.address, balance);

  await deployedGOV.transfer(safeDAO.address, balance);
  await deployedEXC.transfer(safeDAO.address, balance);

  const balanceOfSafe = await deployedGOV.balanceOf(safeDAO.address)

  console.log(balanceOfSafe.toString())



  await safeDAO._setupShares([
    {
      amount: balance.div(4),
      target: deployedDOM.address,
      typeOfToken: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("GOV_TOKEN"))
    },
    {
      amount: balance.div(5),
      target: deployedDOM.address,
      typeOfToken: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EXC_TOKEN"))
    },
    {
      amount: balance.div(4),
      target: deployedCharity.address,
      typeOfToken: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("GOV_TOKEN"))
    },
    {
      amount: balance.div(4),
      target: deployedCharity.address,
      typeOfToken: ethers.utils.keccak256(ethers.utils.toUtf8Bytes("EXC_TOKEN"))
    },
  ], {
    gasLimit: 30000000,
    gasPrice: gas
  })

  if (!developmentChains.includes(network.name)) {
    let promises = [];
    promises.push(verify(deployedEXC.address, {}));
    promises.push(verify(deployedGOV.address, {}));
    promises.push(verify(deployedDOM.address, {}));
    promises.push(verify(deployedCharity.address, {}));
    Promise.all(promises).then(() => {
      console.log("All contracts verified!");
    }
    );
  }


  return {
    deployedGOV,
    deployedEXC,
    deployedCharity,
    deployedDOM
  }

};



deployTokens().then(x => console.log("Done!")).catch(e => console.log(e));
export default deployTokens
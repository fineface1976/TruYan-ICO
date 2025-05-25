const hre = require("hardhat");
require("dotenv").config();

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  
  // Deploy ICO contract (Replace with your BUSD, MZLx, and Chainlink addresses)
  const TruYanICO = await hre.ethers.getContractFactory("TruYanICO");
  const ico = await TruYanICO.deploy(
    "0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56", // BUSD
    "0xYourMZLxAddress", // MZLx Token
    "0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE" // Chainlink BNB/USD
  );

  console.log("ICO deployed to:", ico.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

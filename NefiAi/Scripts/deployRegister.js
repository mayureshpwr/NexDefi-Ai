const hre = require("hardhat");

async function main() {
  try {
    console.log("🚀 Starting deployment of ReferralManager...");

    // Get contract factory
    const ReferralManager = await hre.ethers.getContractFactory("ReferralManager");
    console.log("✅ Contract factory loaded...");

    // Deploy contract (no constructor arguments)
    const contract = await ReferralManager.deploy();
    console.log("⏳ Deploying contract...");
    await contract.deployed();
    console.log(`✅ Contract deployed at: ${contract.address}`);

    // Wait for a few confirmations (e.g., 6) before verifying
    console.log("⏳ Waiting for 6 confirmations...");
    await contract.deployTransaction.wait(6);

    // Verify the contract (no constructor arguments)
    console.log("🔍 Verifying contract...");
    await hre.run("verify:verify", {
      address: contract.address,
      constructorArguments: [],
    });

    console.log("✅ Contract verified successfully!");
  } catch (error) {
    console.error("🚨 Deployment failed:", error);
    process.exitCode = 1;
  }
}

main();

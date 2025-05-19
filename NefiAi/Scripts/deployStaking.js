const hre = require("hardhat");

async function main() {
  try {
    console.log("Deploying contract...");

    // Fetch the contract factory (Ensure this matches your contract name)
    const NefiAiStaking = await hre.ethers.getContractFactory("NefiaiStaking");
    console.log("Contract factory loaded...");
    
        // Replace these with your actual addresses (testnet/mock ones shown for now)

        const nefiaiToken = ""; // DEOD token address


        const contract = await NefiAiStaking.deploy(
          nefiaiToken
        );
    
        console.log("⏳ Deploying contract...");
        await contract.deployed();
        console.log(`✅ Contract deployed at: ${contract.address}`);
    
        // Wait for a few block confirmations before verifying
        console.log("⏳ Waiting for 6 confirmations...");
        await contract.deployTransaction.wait(6);
    
        console.log("🔍 Verifying contract...");
        await hre.run("verify:verify", {
          address: contract.address,
          constructorArguments: [
            nefiaiToken
          ],
        });
    
        console.log("✅ Contract verified successfully!");
      } catch (error) {
        console.error("🚨 Deployment failed:", error);
        process.exitCode = 1;
      }
    }
    
    main();
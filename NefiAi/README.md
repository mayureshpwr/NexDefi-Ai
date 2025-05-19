
# 🚀 Nefiai Smart Contract Deployment

This project uses [Hardhat](https://hardhat.org/) for compiling, deploying, and verifying smart contracts. It includes three main contracts:

- `NefiaiToken.sol` – The ERC20 token contract
- `ReferralManager.sol` – Handles referral registrations for token contract
- `NefiaiStaking.sol` –  staking contract for Nefiai tokens

---

## 📁 Project Structure

├── NefiAi/
├──TokenContract/
│   ├── NefiaiToken.sol
│   └── ReferralManager.sol
├──StakingContract/
│   └── NefiaiStaking.sol
├── Scripts/
│   ├── deployToken.js
│   ├── deployRegister.js
│   └── deployStaking.js
├── hardhat.config.js
└── README.md


## ⚙️ Prerequisites
Install dependencies:

```bash
npm install
```

---

## 🔨 Compile Contracts

Compile all contracts using:

```bash
npx hardhat compile
```

---

## 🚀 Deployment Instructions

> Replace `<network>` with your target network (e.g., `polygon`, `amoy`, `bscTestnet`, or `localhost`).

### 1. Deploy Nefiai Token

```bash
npx hardhat run Scripts/deployToken.js --network <network>
```

### 2. Deploy Referral Manager

```bash
npx hardhat run Scripts/deployRegister.js --network <network>
```

### 3. Deploy Nefiai Staking

Before running this step, make sure the constructor in `deployStaking.js` uses the correct deployed `Token`
```bash
npx hardhat run Scripts/deployStaking.js --network <network>
```

---

## 🔍 Contract Verification (Optional)

If not handled automatically, you can manually verify a deployed contract:

```bash
npx hardhat verify --network <network> <contract_address> <constructor_arguments>
```

Example:

```bash
npx hardhat verify --network amoy 0xYourContractAddress "0xTokenAddress" "0xReferralManager"
```

---

## 🧪 Local Deployment (For Testing)

Start a local Hardhat node:

```bash
npx hardhat node
```

Then deploy contracts using:

```bash
npx hardhat run Scripts/deployToken.js --network localhost
npx hardhat run Scripts/deployRegister.js --network localhost
npx hardhat run Scripts/deployStaking.js --network localhost
```

---

## 📝 Notes

* Ensure the deployer wallet has sufficient funds on the target network.
* Wait for enough confirmations (e.g., 6) before verifying a contract.
* Make sure constructor arguments are correctly passed in each deploy script.

---

## 📚 Resources

* [Hardhat Documentation](https://hardhat.org/docs)
* [Polygon Documentation](https://docs.polygon.technology/)
* [Etherscan API Docs](https://docs.etherscan.io/)

---

# 🧠 NefiAi Token (NEFIAI)

## Overview

**NefiAi** is an ERC20-based smart contract deployed on the BNB Smart Chain (BSC). It enables a robust ecosystem of token management, vesting, and referral rewards using DEOD tokens. The contract supports both admin-based vesting and dynamic user purchases, incorporating progressive pricing and multi-level referral systems.

---

## 📜 Contract Information

- **Token Name:** NefiAi
- **Symbol:** NEFIAI
- **Standard:** ERC20
- **Network:** BNB Smart Chain (BSC)
- **Creators:** [Mayuresh Pawar](#) & [Monish Nagre](#)

---

## ⚙️ Features

### 1. Admin Allotment (`adminAllotment`)

Allows admins to allocate NEFIAI tokens to users with a fixed monthly vesting schedule.

#### ✅ Validations:
- Rejects zero address.
- Allocation must be > 0.
- Ensures cumulative allocation does not exceed **PRE_ALLOTMENT** cap (9.2 million).

#### 🧮 Vesting Logic:
- Allocates 1% of total amount per month over 100 months.
- Stores each allotment as a `VestingSchedule`.

---

### 2. Claim Admin-Allotted Tokens (`claimtoken`)

Enables users to claim NEFIAI tokens based on their vesting schedule.

#### 💡 Functionality:
- Aggregates total claimable tokens.
- Updates claimed amount in schedule.
- Transfers tokens to user securely.

---

### 3. Buy NEFIAI with DEOD (`BuyNefi`)

Users can purchase NEFIAI tokens using DEOD. Price increases as more DEOD is spent.

#### 📈 Price Model:
- Starts at **100 DEOD = 1 NEFI**.
- Formula:  
  `currentPrice = initialPrice + totalDeodSpent / CAP`  
  where `CAP = 10,000`.

#### Example:
- If `totalDeodSpent = 50,000`  
  → `price = 100 + 50,000 / 10,000 = 105 DEOD`

#### 🧾 Purchase Breakdown:
- 88% goes to buyer (vested).
- 12% reserved for multi-level referral rewards.
- Enforces **POST_ALLOTMENT** cap (2.5 million NEFIAI).
- Transfers DEOD to a `NULL_ADDRESS`.

---

### 4. Referral Rewards (`distributeReferralRewards`)

Distributes 12% of purchase as vested rewards across up to 6 referral levels.

#### 🔗 Logic:
- Referrer chain is fetched from `referralManager`.
- Each level gets a % share from predefined array.
- Any leftover amount is sent to a `defaultReferrer`.

#### 📦 Storage:
- Rewards stored in `PurchaseVestingSchedule`.
- Claimed monthly at **4%** of total referral reward.

---

### 5. Claim Purchased Tokens (`claimPurchasedTokens`)

Lets users claim their vested NEFI tokens from purchases.

#### 🔐 Function:
- Fetches available claimable amounts.
- Updates vesting schedule.
- Transfers eligible tokens.

---

## 🧪 Deployment

### Requirements

- Node.js
- Hardhat
- MetaMask / BSC Wallet
- DEOD Token Contract deployed
- BSC testnet/mainnet endpoint

### Compile Contracts

```bash
npx hardhat compile

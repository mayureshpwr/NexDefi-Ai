Here’s a comprehensive `README.md` for the **NefiaiStaking** contract:

---

# 🛡️ NefiaiStaking Smart Contract

The `NefiaiStaking` contract is a secure and gas-efficient staking mechanism for the NEFIAI token. It supports:

* **Fixed 6-month lock staking**
* **Proportional daily rewards**
* **Referral rewards system (20%)**
* **Monthly dynamic reward pool**
* **Multiple stakes per user**
* **Secure architecture with admin/reward controls**

---

## 🧾 Features

* **Lock Period**: Each stake is locked for `180 days`.
* **Daily Rewards**: Distributed from a monthly reward cycle (1% of available rewards).
* **Referral System**: One-time registration, with 20% of a staker’s rewards going to the referrer (if staked).
* **Multiple Stakes**: Each user can have multiple concurrent stakes.
* **Claim Mechanics**:

  * Rewards accumulate daily and can be claimed anytime.
  * Principal is claimable only after the 180-day lock period.
* **Admin & Updater Roles**: Allows for decentralized control over reward cycles and token recovery.

---

## 📜 Contract Details

| Item                  | Value / Description                                                                     |
| --------------------- | --------------------------------------------------------------------------------------- |
| Token                 | ERC20-compliant NEFIAI token                                                            |
| Lock Period           | 180 days                                                                                |
| Daily Reward Rate     | 1% of available pool / 30 days                                                          |
| User Reward Share     | 80%                                                                                     |
| Referral Reward Share | 20%                                                                                     |
| Minimum Stake         | 1 NEFIAI (in `1e18` decimals)                                                           |
| Reward Updater        | Externally callable role to advance reward cycle                                        |
| Default Referrer      | `0xA317d8018E68871918f474f2042fbA50Cd75c844` (used if user doesn’t register a referrer) |

---

## 🛠️ Functions

### 👤 User Functions

#### `stake(uint256 amount)`

Stake NEFIAI tokens. Must be ≥ 1 token. Will auto-register with the default referrer if none is set.

#### `registerReferral(address referrer)`

One-time call to register a referrer. Must be a valid address that has already staked.

#### `availableReward(address user) → uint256`

View the user's available (claimable) reward.

#### `availablePrincipal(address user) → uint256`

View unlocked but unclaimed principal.

#### `claimReward()`

Claim accumulated rewards. 80% goes to the user; 20% to the referrer.

#### `claimPrincipal()`

Withdraw all unlocked stakes (after 180 days). Each stake is checked individually.

---

### 🔐 Admin Functions

#### `setAdmin(address)`

Set the admin address. Only callable by `owner`.

#### `setRewardUpdater(address)`

Set the reward updater address (who triggers reward updates).

#### `updateRewards()`

Advance the reward cycle. Callable only by `rewardUpdater` after 30 days.

#### `recoverTokens(address tokenAddress)`

Allows admin to recover non-NEFIAI tokens mistakenly sent to the contract.

---

## 🔄 Reward Cycle Logic

1. Every 30 days, a new reward cycle starts.
2. 1% of the **available NEFIAI tokens** (excluding user stakes) is added to the reward pool.
3. The daily reward is calculated as `cycleReward / 30`.
4. Users earn rewards based on their stake proportion relative to the total staked amount.
5. Rewards accumulate even if the user’s lock has ended—until they claim the principal.

---

## 🔁 Referral System

* Referrals must be registered before staking.
* Referrers must already be staked.
* Users can’t self-refer or create mutual referral loops.
* 20% of every claimed reward goes to the registered referrer.
* If no referrer is registered, rewards are directed to the default address.

---

## ⛓️ Deployment

```solidity
constructor(address _nefiai) Ownable(msg.sender)
```

* `_nefiai`: Address of the NEFIAI ERC20 token

---

## 📋 Events

| Event                                               | Description                    |
| --------------------------------------------------- | ------------------------------ |
| `Staked(user, amount)`                              | New stake added                |
| `PrincipalClaimed(user, amount)`                    | User claimed principal         |
| `RewardClaimed(user, userAmount, refAmount)`        | Reward claimed and distributed |
| `ReferralRewardClaimed(referrer, amount)`           | Referrer reward paid           |
| `Registered(user, referrer)`                        | Referral registered            |
| `RewardCycleStarted(dailyPool, reserved, cycleEnd)` | New cycle initiated            |
| `AdminChanged(newAdmin)`                            | Admin address updated          |
| `RewardUpdaterChanged(newRewardUpdater)`            | Reward updater updated         |
| `TokensRecovered(token, admin, balance)`            | Non-NEFIAI token recovered     |

---

## 🔒 Security Notes

* Uses `ReentrancyGuard` for protection against reentrancy attacks.
* Disallows contract-based staking via `notContract` modifier.
* Only externally-owned accounts (EOAs) can interact.
* Referrer cannot be in a mutual loop with referee.

---

## 🧪 Testing Considerations

* Fast-forward time to simulate lock expiry (`evm_increaseTime` or `evm_setNextBlockTimestamp`).
* Verify correct referral routing.
* Test with multiple overlapping stakes.
* Validate that rewards and principal are never double-claimed.



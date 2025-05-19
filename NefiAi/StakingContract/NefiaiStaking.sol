/**
   _  ______________  ___   ____   _____________   __ _______  _______
  / |/ / __/ __/  _/ / _ | /  _/  / __/_  __/ _ | / //_/  _/ |/ / ___/
 /    / _// _/_/ /  / __ |_/ /   _\ \  / / / __ |/ ,< _/ //    / (_ / 
/_/|_/___/_/ /___/ /_/ |_/___/  /___/ /_/ /_/ |_/_/|_/___/_/|_/\___/  

*/                                                                   

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

contract NefiaiStaking is Ownable, ReentrancyGuard {
    IERC20 public immutable nefiaiToken;
    address public immutable defaultAddress =
        0xA317d8018E68871918f474f2042fbA50Cd75c844;
    address public admin;
    address public rewardUpdater;
    uint256 public constant LOCK_PERIOD = 180 days;
    uint256 public constant DAY = 1 days;
    uint256 public constant MONTH = 30 days;
    uint256 private constant PRECISION = 1e18;
    uint256 public constant MIN_STAKE = 1;
    uint256 public totalStaked;
    uint256 public accRewardPerShare;
    uint256 public lastRewardTimestamp;
    uint256 public dailyPool;
    uint256 public cycleEnd;
    uint256 public reservedRewards;
    struct Stake {
        uint256 amount;
        uint256 startTime;
        bool principalClaimed;
        uint256 rewardDebt;
    }
    mapping(address => Stake[]) public stakes;
    mapping(address => uint256) public rewardPending;
    mapping(address => uint256) public nextToClaim;
    mapping(address => address) public referral;
    mapping(address => uint256) public totalReferralEarned;
    event AdminChanged(address indexed newAdmin);
    event RewardUpdaterChanged(address indexed newRewardUpdater);
    event RewardCycleStarted(
        uint256 dailyPool,
        uint256 reserved,
        uint256 cycleEnd
    );
    event Registered(address indexed user, address referrer);
    event Staked(address indexed user, uint256 amount);
    event PrincipalClaimed(address indexed user, uint256 amount);
    event RewardClaimed(
        address indexed user,
        uint256 userShare,
        uint256 refShare
    );
    event ReferralRewardClaimed(address indexed referrer, uint256 amount);
    event TokensRecovered(address tokenAddress, address admin, uint256 bal);
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }
    modifier onlyrewardUpdater() {
        require(msg.sender == rewardUpdater, "Not reward Updater");
        _;
    }
    modifier notContract() {
        require(
            (!_isContract(msg.sender)) && (msg.sender == tx.origin),
            "contract not allowed"
        );
        _;
    }
    modifier noReciprocalReferral(address _referrer) {
        require(
            referral[_referrer] != msg.sender,
            "Cannot set reciprocal referrer"
        );
        _;
    }

    constructor(address _nefiai) Ownable(msg.sender) {
        nefiaiToken = IERC20(_nefiai);
        _startNewCycle();
    }

    function _isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    /// @notice Sets a newAdmin address
    /// @param newAdmin The address of the new admin
    function setAdmin(address newAdmin) external onlyOwner {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
        emit AdminChanged(newAdmin);
    }

    /// @notice Sets the address allowed to update rewards
    /// @param newRewardUpdater The address of the reward updater
    function setRewardUpdater(address newRewardUpdater) external onlyOwner {
        require(newRewardUpdater != address(0), "Invalid controller");
        rewardUpdater = newRewardUpdater;
        emit RewardUpdaterChanged(newRewardUpdater);
    }

    /// @notice Admin calls once per cycle (after cycleEnd)
    function updateRewards() external onlyrewardUpdater {
        require(block.timestamp >= cycleEnd, "Cycle not ended");
        _updatePool();
    }

    function _startNewCycle() internal {
        uint256 balance = nefiaiToken.balanceOf(address(this));
        uint256 locked = totalStaked + reservedRewards;
        uint256 available = balance > locked ? balance - locked : 0;
        uint256 cycleReward = available / 100;
        reservedRewards += cycleReward;
        dailyPool = cycleReward / 30;
        cycleEnd = block.timestamp + MONTH;
        emit RewardCycleStarted(dailyPool, cycleReward, cycleEnd);
    }

    function _updatePool() internal {
        if (totalStaked == 0) {
            return;
        }
        uint256 upto = block.timestamp < cycleEnd ? block.timestamp : cycleEnd;
        uint256 elapsed = upto - lastRewardTimestamp;
        uint256 daysPassed = elapsed / DAY;
        if (daysPassed > 0 && totalStaked > 0) {
            uint256 reward = dailyPool * daysPassed;
            accRewardPerShare += (reward * PRECISION) / totalStaked;
            lastRewardTimestamp += daysPassed * DAY;
        }
        if (block.timestamp >= cycleEnd) {
            _startNewCycle();
            lastRewardTimestamp = block.timestamp;
        }
    }

    /// @notice Registers a referral relationship
    /// @param referrer The address of the referring user
    function registerReferral(address referrer)
        external
        noReciprocalReferral(referrer)
        notContract
    {
        require(stakes[referrer].length > 0, "Referrer has not staked");
        require(referrer != address(0), "Invalid referrer");
        require(referrer != msg.sender, "Cannot refer yourself");
        require(referral[msg.sender] == address(0), "Already registered");
        referral[msg.sender] = referrer;
        emit Registered(msg.sender, referrer);
    }

    /// @notice Stakes NEFIAI tokens into the contract
    /// @param amount Amount of NEFIAI tokens to stake
    function stake(uint256 amount) external notContract nonReentrant {
        if (totalStaked == 0) {
            lastRewardTimestamp = block.timestamp; // Start tracking rewards now
        }
        _updatePool();
        if (referral[msg.sender] == address(0)) {
            referral[msg.sender] = defaultAddress;
        }
        require(
            amount >= MIN_STAKE * PRECISION,
            "Minimum stake is 1 NEFIAI token"
        );
        stakes[msg.sender].push(
            Stake({
                amount: amount,
                startTime: block.timestamp,
                principalClaimed: false,
                rewardDebt: (amount * accRewardPerShare) / PRECISION
            })
        );
        totalStaked += amount;
        require(
            nefiaiToken.transferFrom(msg.sender, address(this), amount),
            "Stake Failed"
        );
        emit Staked(msg.sender, amount);
    }

    /// @notice Returns the total principal available for withdrawal (unlocked and not yet claimed)
    /// @param user The address of the staker
    /// @return sum The amount of principal available for withdrawal
    function availablePrincipal(address user)
        public
        view
        returns (uint256 sum)
    {
        for (uint256 i; i < stakes[user].length; i++) {
            Stake storage s = stakes[user][i];
            if (
                !s.principalClaimed &&
                block.timestamp >= s.startTime + LOCK_PERIOD
            ) sum += s.amount;
        }
    }

    /// @notice Returns the total reward available to the user (includes pending and accrued)
    /// @param user The address of the staker
    /// @return sum The amount of reward tokens the user can claim (80% of the total)
    function availableReward(address user) public view returns (uint256 sum) {
        sum = rewardPending[user];
        uint256 _acc = accRewardPerShare;
        uint256 _last = lastRewardTimestamp;
        uint256 _daily = dailyPool;
        uint256 _end = cycleEnd;
        uint256 _tot = totalStaked;
        if (_tot > 0) {
            uint256 upto = block.timestamp < _end ? block.timestamp : _end;
            uint256 daysPassed = (upto - _last) / DAY;
            if (daysPassed > 0) {
                _acc += (daysPassed * _daily * PRECISION) / _tot;
            }
        }
        Stake[] storage ss = stakes[user];
        for (uint256 i; i < ss.length; i++) {
            if (ss[i].principalClaimed) continue;
            uint256 owed = (ss[i].amount * _acc) / PRECISION;
            if (owed > ss[i].rewardDebt) {
                sum += owed - ss[i].rewardDebt;
            }
        }
    }

    /// @notice Claims unlocked principal for the user
    /// @dev This also updates rewardDebt and skips already claimed stakes
    function claimPrincipal() external nonReentrant {
        _updatePool();
        Stake[] storage ss = stakes[msg.sender];
        uint256 i = nextToClaim[msg.sender];
        uint256 toWithdraw;
        for (; i < ss.length; i++) {
            Stake storage s = ss[i];
            if (block.timestamp < s.startTime + LOCK_PERIOD) {
                // not ready yet → stop scanning
                break;
            }
            uint256 owed = (s.amount * accRewardPerShare) / PRECISION;
            owed = owed > s.rewardDebt ? owed - s.rewardDebt : 0;
            rewardPending[msg.sender] += owed;
            s.principalClaimed = true;
            toWithdraw += s.amount;
        }
        nextToClaim[msg.sender] = i; // next time, skip everything < i
        require(toWithdraw > 0, "None");
        totalStaked -= toWithdraw;
        require(
            nefiaiToken.transfer(msg.sender, toWithdraw),
            "Transfer failed"
        );
        emit PrincipalClaimed(msg.sender, toWithdraw);
    }

    /// @notice Claims staking rewards (80% to user, 20% to referrer)
    /// Transfers 80% of the pending reward to the user and 20% to their referrer..
    function claimReward() external nonReentrant {
        _updatePool();
        uint256 payout = availableReward(msg.sender);
        require(payout > 0, "None");
        // reset buffer and each stake’s debt
        rewardPending[msg.sender] = 0;
        Stake[] storage ss = stakes[msg.sender];
        for (uint256 i; i < ss.length; i++) {
            if (ss[i].principalClaimed) continue;
            ss[i].rewardDebt = (ss[i].amount * accRewardPerShare) / PRECISION;
        }
        reservedRewards -= payout;
        uint256 userShare = (payout * 80) / 100;
        uint256 refShare = payout - userShare;
        address referrer = referral[msg.sender];
        if (refShare > 0) {
            totalReferralEarned[referrer] += refShare;
            require(
                nefiaiToken.transfer(referrer, refShare),
                "Referral payout failed"
            );
            emit ReferralRewardClaimed(referrer, refShare);
        }
        require(
            nefiaiToken.transfer(msg.sender, userShare),
            "Claim Reward Failed"
        );
        emit RewardClaimed(msg.sender, userShare, refShare);
    }

    /// @notice Allows admin to recover non-Nefiai tokens sent to the contract.
    /// @param tokenAddress ERC-20 token address to recover.
    function recoverTokens(address tokenAddress) external onlyAdmin {
        require(
            tokenAddress != address(nefiaiToken),
            "Can't recover Nefiai tokens"
        );
        uint256 bal = IERC20(tokenAddress).balanceOf(address(this));
        require(bal > 0, "Nothing to recover");
        require(IERC20(tokenAddress).transfer(admin, bal), "Transfer failed");
        emit TokensRecovered(tokenAddress, admin, bal);
    }
// Created by Dev — https://github.com/mayureshpwr & https://github.com/monish-nagre
}

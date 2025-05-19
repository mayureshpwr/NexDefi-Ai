/** 
███    ██ ███████ ██   ██ ██████  ███████ ███████ ██      █████  ██ 
████   ██ ██       ██ ██  ██   ██ ██      ██      ██     ██   ██ ██ 
██ ██  ██ █████     ███   ██   ██ █████   █████   ██     ███████ ██ 
██  ██ ██ ██       ██ ██  ██   ██ ██      ██      ██     ██   ██ ██ 
██   ████ ███████ ██   ██ ██████  ███████ ██      ██     ██   ██ ██ 
**/

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

pragma solidity ^0.8.18;

interface IReferralManager {
    function referral(address user) external view returns (address);
}
contract NexDefiAi is ERC20, ReentrancyGuard {
    using SafeERC20 for IERC20;
    // Constants
    uint256 public constant MAX_SUPPLY = 14_000_000 * 1e18;
    uint256 public constant LIQUIDITY_RESERVE_ALLOCATION = 1_000_000 * 1e18;
    uint256 public constant REWARD_POOL = 500_000 * 1e18;
    uint256 public constant Airdrop = 300_000 * 1e18;
    uint256 public constant IDO = 500_000 * 1e18;
    uint256 public constant PRE_ALLOTMENT = 9_200_000 * 1e18;
    uint256 public constant POST_ALLOTMENT = 2_500_000 * 1e18;
    uint256 private constant MONTHLY_PERCENTAGE = 1;
    uint256 private constant VESTING_MONTHS = 100;
    uint256 private constant PURCHASE_VESTING_PERCENTAGE = 4;
    uint256 private constant PURCHASE_VESTING_MONTHS = 25;
    uint256 private constant CYCLE_DURATION = 30 days;
    uint256 private constant CAP = 10_000;
    // Token references
    IERC20 public immutable DEOD;
    // Key Addresses
    address public immutable NULL_ADDRESS =
        0x000000000000000000000000000000000000dEaD;
    address public immutable defaultReferrer =
        0xA317d8018E68871918f474f2042fbA50Cd75c844;
    address public admin;
    address public immutable liquidityReserveWallet;
    address public immutable RewardWallet;
    address public immutable idoWallet;
    address public immutable airdrop;
    IReferralManager public referralManager;
    // State trackers
    uint256 public totalAllocatedTokens;
    uint256 public totalAllocatedTokensForPurchase;
    uint256 public totalNefiAiBought;
    uint256 public totalDeodSpent;
    uint256 public totalNefiAiclaimed;
    uint256 public totalNefiAipurchasedClaimed;
    uint256 private immutable PRICE_CAP = 10000 * 1e18;
    uint256 private initialPrice = 88 * 1e18;
    uint256 private temp = 0;
    // Mappings
    mapping(address => uint256) public UsertotalNefiAiClaimed;
    mapping(address => uint256) public UsertotalPurchasedNefiAiClaimed;
    mapping(address => uint256) public UsertotaldeodStaked;
    mapping(address => uint256) public UsertotalNefiAiBought;
    mapping(address => uint256) public referralRewardsAccumulated;
    // Vesting Structures
    struct VestingSchedule {
        uint256 totalAllocated;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 monthlyReleaseAmount;
    }
    struct PurchaseVestingSchedule {
        uint256 totalAllocated;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 monthlyReleaseAmount;
    }
    struct ReferralPurchaseVestingSchedule {
        uint256 refAlloted;
        uint256 claimedAmount;
        uint256 startTime;
        uint256 monthlyReleaseAmount;
    }
    // Vesting Data
    mapping(address => VestingSchedule[]) public vestingSchedules;
    mapping(address => PurchaseVestingSchedule[])
        public PurchaseVestingSchedules;
    mapping(address => ReferralPurchaseVestingSchedule[])
        public ReferralVestingSchedules;
    // Referral system
    uint256[6] public referralRewards = [7, 1, 1, 1, 1, 1];
    // Events
    event VestingAssigned(
        address indexed user,
        uint256 totalAllocated,
        uint256 monthlyRelease
    );
    event Claimed(address indexed user, uint256 amount);
    event ReferralRegistered(address user, address referrer);
    event PurchaseVestingAssigned(
        address indexed user,
        uint256 totalAllocated,
        uint256 monthlyRelease
    );
    event PurchaseClaimed(address indexed user, uint256 amount);
    event NefiAiPurchased(
        address indexed user,
        uint256 nefiAiAmount,
        uint256 deodSpent,
        uint256 newPrice
    );
    // Constructor
    constructor(
        address _liquidityReserveWallet,
        address _RewardWallet,
        address _Airdrop,
        address _idoWallet,
        address _deodToken,
        address _referralManager
    ) ERC20("NexDefi Ai", "Nefi Ai") {
        liquidityReserveWallet = _liquidityReserveWallet;
        RewardWallet = _RewardWallet;
        airdrop = _Airdrop;
        idoWallet = _idoWallet;
        DEOD = IERC20(_deodToken);
        referralManager = IReferralManager(_referralManager);
        admin = msg.sender;
        _mint(_liquidityReserveWallet, LIQUIDITY_RESERVE_ALLOCATION);
        _mint(_RewardWallet, REWARD_POOL);
        _mint(_Airdrop, Airdrop);
        _mint(_idoWallet, IDO);
        _mint(address(this), PRE_ALLOTMENT + POST_ALLOTMENT);
    }
    // Admin-only modifier
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }
    // =========================== Admin Allocation ===========================
    function adminAllotment(address user, uint256 allocationAmount)
        external
        onlyAdmin
    {
        require(user != address(0), "Invalid user address");
        require(allocationAmount > 0, "Amount must be greater than zero");
        require(
            totalAllocatedTokens + allocationAmount <= PRE_ALLOTMENT,
            "Exceeds vesting allocation"
        );
        uint256 monthlyReleaseAmount = (allocationAmount * MONTHLY_PERCENTAGE) /
            100;
        vestingSchedules[user].push(
            VestingSchedule({
                totalAllocated: allocationAmount,
                claimedAmount: 0,
                startTime: block.timestamp,
                monthlyReleaseAmount: monthlyReleaseAmount
            })
        );
        totalAllocatedTokens += allocationAmount;
        emit VestingAssigned(user, allocationAmount, monthlyReleaseAmount);
    }
    function availableToClaim(address user)
        public
        view
        returns (uint256 totalClaimable, uint256[] memory claimableAmounts)
    {
        VestingSchedule[] storage schedules = vestingSchedules[user];
        claimableAmounts = new uint256[](schedules.length);
        for (uint256 i = 0; i < schedules.length; i++) {
            VestingSchedule storage vesting = schedules[i];
            uint256 monthsPassed = (block.timestamp - vesting.startTime) / CYCLE_DURATION;
            if (monthsPassed > VESTING_MONTHS) {
                monthsPassed = VESTING_MONTHS;
            }
            uint256 totalVested = vesting.monthlyReleaseAmount * monthsPassed;
            uint256 claimable = totalVested - vesting.claimedAmount;
            if (claimable + vesting.claimedAmount > vesting.totalAllocated) {
                claimable = vesting.totalAllocated - vesting.claimedAmount;
            }
            totalClaimable += claimable;
            claimableAmounts[i] = claimable;
        }
    }
    function claimTokens() external nonReentrant {
        (
            uint256 totalToClaim,
            uint256[] memory claimableAmounts
        ) = availableToClaim(msg.sender);
        require(totalToClaim > 0, "No tokens available to claim");
        VestingSchedule[] storage schedules = vestingSchedules[msg.sender];
        for (uint256 i = 0; i < schedules.length; i++) {
            if (claimableAmounts[i] > 0) {
                schedules[i].claimedAmount += claimableAmounts[i];
            }
        }
        UsertotalNefiAiClaimed[msg.sender] += totalToClaim;
        totalNefiAiclaimed += totalToClaim;
        _transfer(address(this), msg.sender, totalToClaim);
        emit Claimed(msg.sender, totalToClaim);
    }
    // =========================== Purchase Allocation ===========================
    function buyNefiAi(uint256 deodAmount) external nonReentrant {
        require(
            deodAmount >= 1000 * 1e18,
            "Amount must be greater then or equal to 1000 DEOD"
        );
        require(
            deodAmount <= 500000 * 1e18,
            "Amount must be smaller then or equal to 500000 DEOD"   
        );
        require(
            !isContract(msg.sender),
            "Contracts are not allowed to buy NefiAi"
        );
        uint256 currentPrice = initialPrice;
        uint256 nefiAiAmount = (deodAmount * 1e18) / currentPrice;
        uint256 referralAmount = (nefiAiAmount * 12) / 100;
        uint256 finalNefiAi =  nefiAiAmount - referralAmount;    
        require(
            totalAllocatedTokensForPurchase + nefiAiAmount <= POST_ALLOTMENT,    
            "Exceeds buy allocation"
        );
        require(
            nefiAiAmount > 0,
            "Minimum purchase not met"
        );
        require(
            finalNefiAi > 0,
            "Minimum purchase not met"   
        );

        uint256 tempLeft = temp;
        uint256 updatedTotal = tempLeft + nefiAiAmount;
        if (updatedTotal > PRICE_CAP) {
            updatedTotal = updatedTotal - PRICE_CAP;
            initialPrice += 1e18;
        }
        temp = updatedTotal;
        
        DEOD.safeTransferFrom(msg.sender, NULL_ADDRESS, deodAmount);
        totalDeodSpent += deodAmount;
        UsertotaldeodStaked[msg.sender] += deodAmount;
        UsertotalNefiAiBought[msg.sender] += finalNefiAi;
        totalNefiAiBought += nefiAiAmount;
        totalAllocatedTokensForPurchase += nefiAiAmount;
        address referrer = referralManager.referral(msg.sender);
        if (referrer == address(0)) referrer = defaultReferrer;
        distributeReferralRewards(referrer, referralAmount, nefiAiAmount);
        uint256 monthlyRelease = (finalNefiAi * PURCHASE_VESTING_PERCENTAGE) /
            100;
        PurchaseVestingSchedules[msg.sender].push(
            PurchaseVestingSchedule({
                totalAllocated: finalNefiAi,
                claimedAmount: 0,
                startTime: block.timestamp,
                monthlyReleaseAmount: monthlyRelease
            })
        );
        emit NefiAiPurchased(
            msg.sender,
            nefiAiAmount,
            deodAmount,
            initialPrice    
        );
    }
    function availableToClaimPurchased(address user)
        public
        view
        returns (
            uint256 totalClaimable,
            uint256[] memory purchaseClaimableAmounts,
            uint256[] memory referralClaimableAmounts
        )
    {
        // --- Purchase Vesting ---
        PurchaseVestingSchedule[] storage purchases = PurchaseVestingSchedules[
            user
        ];
        purchaseClaimableAmounts = new uint256[](purchases.length);
        for (uint256 i = 0; i < purchases.length; i++) {
            uint256 monthsPassed = (block.timestamp - purchases[i].startTime) /
                CYCLE_DURATION;
            if (monthsPassed > PURCHASE_VESTING_MONTHS)
                monthsPassed = PURCHASE_VESTING_MONTHS;
            uint256 totalVested = purchases[i].monthlyReleaseAmount *
                monthsPassed;
            uint256 claimable = totalVested - purchases[i].claimedAmount;
            totalClaimable += claimable;
            purchaseClaimableAmounts[i] = claimable;
        }
        // --- Referral Vesting ---
        ReferralPurchaseVestingSchedule[]
            storage referrals = ReferralVestingSchedules[user];
        referralClaimableAmounts = new uint256[](referrals.length);
        for (uint256 i = 0; i < referrals.length; i++) {
            uint256 monthsPassed = (block.timestamp - referrals[i].startTime) /
                CYCLE_DURATION;
            if (monthsPassed > PURCHASE_VESTING_MONTHS)
                monthsPassed = PURCHASE_VESTING_MONTHS;
            uint256 totalVested = referrals[i].monthlyReleaseAmount *
                monthsPassed;
            uint256 claimable = totalVested - referrals[i].claimedAmount;
            totalClaimable += claimable;
            referralClaimableAmounts[i] = claimable;
        }
    }
    function claimPurchasedTokens() external nonReentrant {
        (
            uint256 totalToClaim,
            uint256[] memory purchaseClaimableAmounts,
            uint256[] memory referralClaimableAmounts
        ) = availableToClaimPurchased(msg.sender);
        require(totalToClaim > 0, "No tokens available to claim");
        // Claim Purchase Vesting
        PurchaseVestingSchedule[] storage purchases = PurchaseVestingSchedules[
            msg.sender
        ];
        for (uint256 i = 0; i < purchases.length; i++) {
            if (purchaseClaimableAmounts[i] > 0) {
                purchases[i].claimedAmount += purchaseClaimableAmounts[i];
            }
        }
        // Claim Referral Vesting
        ReferralPurchaseVestingSchedule[]
            storage referrals = ReferralVestingSchedules[msg.sender];
        for (uint256 i = 0; i < referrals.length; i++) {
            if (referralClaimableAmounts[i] > 0) {
                referrals[i].claimedAmount += referralClaimableAmounts[i];
            }
        }
        UsertotalPurchasedNefiAiClaimed[msg.sender] += totalToClaim;
        totalNefiAipurchasedClaimed += totalToClaim;
        _transfer(address(this), msg.sender, totalToClaim);
        emit PurchaseClaimed(msg.sender, totalToClaim);
    }
    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
    }
 
    function getCurrentPrice() public view returns (uint256) {
        return initialPrice;
    }
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }
    function distributeReferralRewards(
        address referrer,
        uint256 totalReferralAmount,
        uint256 nefiAiAmount
    ) internal {
        address currentReferrer = referrer;
        uint256 remainingAmount = totalReferralAmount;
        for (uint256 i = 0; i < 6; i++) {
            if (currentReferrer == address(0)) break;
            uint256 refReward = (nefiAiAmount * referralRewards[i]) / 100;
            remainingAmount -= refReward;
            uint256 monthlyRelease = (refReward * PURCHASE_VESTING_PERCENTAGE) /
                100;
            ReferralVestingSchedules[currentReferrer].push(
                ReferralPurchaseVestingSchedule({
                    refAlloted: refReward,
                    claimedAmount: 0,
                    startTime: block.timestamp,
                    monthlyReleaseAmount: monthlyRelease
                })
            );
            referralRewardsAccumulated[currentReferrer] += refReward;
            currentReferrer = referralManager.referral(currentReferrer);
        }
        // Default fallback
        if (remainingAmount > 0) {
            uint256 monthlyRelease = (remainingAmount *
                PURCHASE_VESTING_PERCENTAGE) / 100;
            ReferralVestingSchedules[defaultReferrer].push(
                ReferralPurchaseVestingSchedule({
                    refAlloted: remainingAmount,
                    claimedAmount: 0,
                    startTime: block.timestamp,
                    monthlyReleaseAmount: monthlyRelease
                })
            );
            referralRewardsAccumulated[defaultReferrer] += remainingAmount;
        }
    }
// Created by Dev — https://github.com/mayureshpwr & https://github.com/monish-nagre
}
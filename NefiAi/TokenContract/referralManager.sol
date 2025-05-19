// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract ReferralManager {
    address public admin;

    event ReferralRegistered(address indexed user, address indexed referrer);

    mapping(address => address) public referral;
    mapping(address => uint256) public downlineCount;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }
     modifier noReciprocalReferral(address _referrer) {
        require(referral[_referrer] != msg.sender, "Cannot set reciprocal referrer");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerReferral(address referrer) external noReciprocalReferral(referrer) {
        require(referrer != address(0) && !isContract(referrer), "Invalid referrer");
        require(referrer != msg.sender, "Cannot refer yourself");
        require(referral[msg.sender] == address(0), "Already registered");
        

        referral[msg.sender] = referrer;
        unchecked { downlineCount[referrer]++; }


        emit ReferralRegistered(msg.sender, referrer);
    }

     function isContract(address addr) internal view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }


    function changeAdmin(address newAdmin) external onlyAdmin {
        require(newAdmin != address(0), "Invalid admin address");
        admin = newAdmin;
    }
}
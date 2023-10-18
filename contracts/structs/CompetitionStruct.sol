// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library CompetitionStruct {
    // In the first and second modes, voters can withdraw thier coins fully. 
    // If a competition is SHARE_PRO or PROPORTION mode, they will receive uncertain benefits(equal risk and benefit) 
    enum Mode{ 
        // only give rewards to players
        NORMAL,
        // share rewards
        SHARE,
        // share rewards and coins
        SHARE_PRO,
        // share total rewards by tickets proportion
        PROPORTION
    }

    struct Candidate{
        // usually, tickets equal coins, but not absolute
        uint256 tickets;
        uint256 coins;
        // who can withdraw rewards
        address player;
    }

    struct Events{
        address host;
        uint256 totalTickets;
        uint256[] rewards;
        address rewardCoin;
        address voteCoin;
        uint256 totalCoins;
        Mode mode;
        // 0 - 10000
        uint64 proportionToPlayer;
        // start time
        uint64 startTime;
        // end time
        uint64 endTime;
    }
}
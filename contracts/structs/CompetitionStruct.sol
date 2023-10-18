// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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
        uint256 tickets;
        // who can withdraw rewards
        address player;
    }

    struct Voter{
        uint256 tickets;
        bool isWithdraw;
    }

    struct Competition{
        address host;
        uint256 totalCoins;
        uint256[] rewards;
        uint256[] winners;
        IERC20 rewardCoin;
        IERC20 ticketCoin;
        uint256 totalCandidates;
        Mode mode;
        // 0 - 10000
        uint64 proportionToPlayer;
        // start time
        uint64 startTime;
        // end time
        uint64 endTime;
    }
}
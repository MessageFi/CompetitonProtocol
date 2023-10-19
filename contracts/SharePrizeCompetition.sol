// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./DefaultCompetition.sol";
import "hardhat/console.sol";

contract SharePrizeCompetition is DefaultCompetition{
    error InvalidProportion();

    mapping (uint256 => uint256) public proportionMapping;

    function setVoterProportion(uint256 id, uint256 proportion) external virtual nonReentrant onlyHost(competitionMapping[id]){
        if (competitionMapping[id].startTime < block.timestamp) {
            revert CompetitionStarted();
        }
        if (proportion > 10000){
            revert InvalidProportion();
        }
        proportionMapping[id] =  proportion;
    }

    function withdrawByPlayer(
        uint256 id,
        uint256 candidate,
        address to
    ) external virtual override nonReentrant {
        Structs.Competition memory c = competitionMapping[id];
        if (block.timestamp <= c.endTime) {
            revert CompetitionNotEnd();
        }
        if (rewardIsWithdraw[id][candidate]) {
            revert DuplicateWithdraw();
        }
        for (uint i = 0; i < c.winners.length; ++i) {
            if (candidate == c.winners[i]) {
                if (_msgSender() != candidateMapping[id][candidate].player) {
                    revert NoAccess();
                }
                uint realRewards = c.rewards[i] * (10000 - proportionMapping[id]) /
                    10000;
                SafeERC20.safeTransfer(c.rewardCoin, to, realRewards);

                emit WithdrawByPlayer(id, candidate, to, realRewards, 0);

                rewardIsWithdraw[id][candidate] = true;
                break;
            }
        }
    }

    function withdrawByVoter(
        uint256 id,
        uint256 candidate,
        address to
    ) external virtual override nonReentrant {
        
        Structs.Competition memory c = competitionMapping[id];
        if (block.timestamp <= c.endTime) {
            revert CompetitionNotEnd();
        }
        if (voterMapping[_msgSender()][id][candidate].isWithdraw) {
            revert DuplicateWithdraw();
        }
        uint tickets = voterMapping[_msgSender()][id][candidate].tickets;
        if (tickets == 0) {
            revert NoAccess();
        }
        voterMapping[_msgSender()][id][candidate].isWithdraw = true;
        SafeERC20.safeTransfer(c.ticketCoin, to, tickets);
        uint rewards = 0;
        for (uint i = 0; i < c.winners.length; ++i) {
            if (candidate == c.winners[i]) {
                rewards = c.rewards[i] * proportionMapping[id] / 10000;
                rewards = rewards * tickets / candidateMapping[id][candidate].tickets;
                SafeERC20.safeTransfer(c.rewardCoin, to, rewards);
                break;
            }
        }

        emit WithdrawByVoter(id, candidate, to, rewards, tickets);
    }

}
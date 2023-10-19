// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./SharePrizeCompetition.sol";
import "hardhat/console.sol";

contract SharePrizeAndTicketCompetition is SharePrizeCompetition{

    mapping (uint256 => uint256) totalTicketsMapping;

    function vote(
        uint256 id,
        uint256 candidate,
        uint256 tickets
    ) external override virtual nonReentrant ongoing(competitionMapping[id]) {
        if (tickets < 1) {
            revert InvalidTickets();
        }
        if (candidateMapping[id][candidate].player == address(0)) {
            revert InvalidCandidate();
        }
        uint real = realTickets(id, tickets);
        if (real == 0) {
            revert InvalidTickets();
        }
        SafeERC20.safeTransferFrom(
            competitionMapping[id].ticketCoin,
            _msgSender(),
            address(this),
            tickets
        );

        candidateMapping[id][candidate].tickets += tickets;
        _orderCandidates(
            id,
            candidate,
            candidateMapping[id][candidate].tickets
        );

        totalTicketsMapping[id] += tickets;

        voterMapping[_msgSender()][id][candidate].tickets = tickets;
        emit Vote(id, candidate, _msgSender(), tickets);
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

                uint256 proportion = _rewardProportion(
                    c.rewards,
                    c.rewards[i]
                );
                uint sharedCoins = totalTicketsMapping[id] *
                    proportion * (10000 - proportionMapping[id]) / 1e8;
                 SafeERC20.safeTransfer(c.ticketCoin, to, sharedCoins);

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

        for (uint i = 0; i < c.winners.length; ++i) {
            if (candidate == c.winners[i]) {
                uint rewards = c.rewards[i] * proportionMapping[id] / 10000;
                rewards = rewards * tickets / candidateMapping[id][candidate].tickets;
                SafeERC20.safeTransfer(c.rewardCoin, to, rewards);
                // calculate proportion
                uint256 proportion = _rewardProportion(
                    c.rewards,
                    c.rewards[i]
                );

                uint sharedCoins = totalTicketsMapping[id] * (10000 - proportion) * 10000;
                
                sharedCoins = sharedCoins * tickets / candidateMapping[id][candidate].tickets;
                SafeERC20.safeTransfer(c.ticketCoin, to, sharedCoins);

                emit WithdrawByVoter(id, candidate, to, rewards, tickets);
                break;
            }
        }
    }
}
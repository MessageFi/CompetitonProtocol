// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./structs/CompetitionStruct.sol";
import "./interfaces/ICompetitionProtocol.sol";
import "./interfaces/ITicketCalculator.sol";
import "hardhat/console.sol";

contract CompetitionProtocol is
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    ICompetitionProtocol
{
    modifier OnlyHost(CompetitionStruct.Competition storage competition) {
        if (_msgSender() != competition.host) {
            revert NotHost();
        }
        _;
    }

    modifier CompetitionOngoing(
        CompetitionStruct.Competition storage competition
    ) {
        if (
            competition.startTime > block.timestamp ||
            competition.endTime < block.timestamp
        ) {
            revert CompetitionNotOngoing();
        }
        _;
    }

    uint256 public totalCompetitions;
    // id => competition details
    mapping(uint256 => CompetitionStruct.Competition) public competitionMapping;
    // id => calculator
    mapping(uint256 => ITicketCalculator) public calculatorMapping;
    mapping(uint256 => uint256) private totalTicketsMapping;
    // competition => candidate => details
    mapping(uint256 => mapping(uint256 => CompetitionStruct.Candidate))
        public candidateMapping;
    // address => competition => candidate => coins;
    mapping(address => mapping(uint256 => mapping(uint256 => CompetitionStruct.Voter))) voterMapping;
    // white coins list
    mapping(address => bool) public whiteCoins;
    // competition => candidate => reward status
    mapping(uint256 => mapping(uint256 => bool)) public rewardIsWithdraw;

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // create a competition
    function create(
        address ticketCoin,
        address rewardCoin,
        uint256[] calldata rewards,
        uint64 startTime,
        uint64 endTime,
        CompetitionStruct.Mode mode,
        uint64 proportionToPlayer
    ) external nonReentrant returns (uint256 id) {
        ++totalCompetitions;
        if (endTime <= block.timestamp) {
            revert InvalidTime();
        }
        if(startTime == 0){
            startTime = uint64(block.timestamp);
        }
        // if (!whiteCoins[rewardCoin]){
        //     revert InvalidRewards();
        // }
        if (rewards.length == 0 || rewards[0] == 0) {
            revert EmptyRewards();
        }
        if (rewards.length > 1 && mode == CompetitionStruct.Mode.PROPORTION) {
            revert MutipleRewards();
        }

        uint256 totalRewards = _totalRewards(rewards);
        console.log("totalRewards: ", totalRewards);
        SafeERC20.safeTransferFrom(
            IERC20(rewardCoin),
            _msgSender(),
            address(this),
            totalRewards
        );
        CompetitionStruct.Competition memory c;
        c.host = _msgSender();
        c.ticketCoin = IERC20(ticketCoin);
        c.rewardCoin = IERC20(rewardCoin);
        c.rewards = rewards;
        c.startTime = startTime;
        c.endTime = endTime;
        c.mode = mode;
        c.proportionToPlayer = proportionToPlayer;
        if (mode != CompetitionStruct.Mode.PROPORTION) {
            c.winners = new uint256[](rewards.length);
        }

        competitionMapping[totalCompetitions] = c;

        emit NewCompetition(totalCompetitions, _msgSender());
        return totalCompetitions;
    }

    function setTicketCalculator(
        uint256 id,
        address calculator
    ) external OnlyHost(competitionMapping[id]) {
        if (competitionMapping[id].startTime < block.timestamp) {
            revert CompetitionStarted();
        }

        if (!isCalculator(calculator)) {
            revert InvalidCalculator();
        }
        calculatorMapping[id] = ITicketCalculator(calculator);
    }

    function registerCandidate(
        uint256 id,
        address player
    )
        external
        OnlyHost(competitionMapping[id])
        CompetitionOngoing(competitionMapping[id])
        returns (uint256 candidateId)
    {
        candidateId = ++competitionMapping[id].totalCandidates;
        candidateMapping[id][candidateId].player = player;
        ++competitionMapping[id].totalCandidates;

        emit NewCandidate(id, candidateId, player);
        return candidateId;
    }

    function vote(
        uint256 id,
        uint256 candidate,
        uint256 tickets
    ) external nonReentrant CompetitionOngoing(competitionMapping[id]) {
        if (tickets < 1) {
            revert InvalidTickets();
        }
        if (candidateMapping[id][candidate].player == address(0)) {
            revert InvalidCandidate();
        }
        uint real = realTickets(id, tickets);
        if (real < 1) {
            revert InvalidTickets();
        }
        SafeERC20.safeTransferFrom(
            competitionMapping[id].ticketCoin,
            _msgSender(),
            address(this),
            tickets
        );

        CompetitionStruct.Competition storage c = competitionMapping[id];

        if (
            c.mode == CompetitionStruct.Mode.PROPORTION &&
            address(calculatorMapping[id]) != address(0)
        ) {
            // proportion mode
            uint totalTickets = totalTicketsMapping[id];
            totalTickets -= realTickets(
                id,
                candidateMapping[id][candidate].tickets
            );
            candidateMapping[id][candidate].tickets += tickets;
            totalTickets += realTickets(
                id,
                candidateMapping[id][candidate].tickets
            );
            totalTicketsMapping[id] = totalTickets;
        } else {
            candidateMapping[id][candidate].tickets += tickets;
            _orderCandidates(
                id,
                candidate,
                candidateMapping[id][candidate].tickets
            );
        }
        c.totalCoins += tickets;
        voterMapping[_msgSender()][id][candidate].tickets = tickets;
        emit Vote(id, candidate, _msgSender(), tickets);
    }

    function realTickets(
        uint256 id,
        uint256 coins
    ) public view returns (uint256) {
        if (address(calculatorMapping[id]) != address(0)) {
            return calculatorMapping[id].calculateTickets(coins);
        }
        return coins;
    }

    function _orderCandidates(
        uint256 id,
        uint256 candidate,
        uint256 tickets
    ) internal {
        uint256[] memory winnerArray = competitionMapping[id].winners;
        for (uint i = 0; i < winnerArray.length; ++i) {
            if (winnerArray[i] == 0) {
                winnerArray[i] = candidate;
                emit WinnerChanged(id);
                break;
            }
            if (
                realTickets(id, tickets) >
                realTickets(id, candidateMapping[id][winnerArray[i]].tickets)
            ) {
                // insert and move
                for (uint j = i; j < winnerArray.length; ++j) {
                    uint cj = winnerArray[j];
                    winnerArray[j] = candidate;
                    candidate = cj;
                }
                emit WinnerChanged(id);
                break;
            }
        }
        competitionMapping[id].winners = winnerArray;
    }

    function withdrawByPlayer(
        uint256 id,
        uint256 candidate,
        address to
    ) external nonReentrant {
        CompetitionStruct.Competition memory c = competitionMapping[id];
        if (block.timestamp <= c.endTime) {
            revert CompetitionNotEnd();
        }
        if (rewardIsWithdraw[id][candidate]){
            revert DuplicateWithdraw();
        }
        for (uint i = 0; i < c.winners.length; ++i) {
            if (candidate == c.winners[i]) {
                if (_msgSender() != candidateMapping[id][candidate].player) {
                    revert NoAccess();
                }
                uint realRewards = (c.rewards[i] * c.proportionToPlayer) /
                    10000;
                SafeERC20.safeTransfer(c.rewardCoin, to, realRewards);
                if (c.mode == CompetitionStruct.Mode.SHARE_PRO) {
                    uint256 proportion = _rewardProportion(
                        c.rewards,
                        c.rewards[i]
                    );
                    uint sharedCoins = (c.totalCoins *
                        proportion *
                        c.proportionToPlayer) / 1e8;
                    SafeERC20.safeTransfer(c.ticketCoin, to, sharedCoins);
                    emit WithdrawByPlayer(
                        id,
                        candidate,
                        to,
                        realRewards,
                        sharedCoins
                    );
                } else {
                    emit WithdrawByPlayer(id, candidate, to, realRewards, 0);
                }
                rewardIsWithdraw[id][candidate] = true;
                break;
            }
        }
    }

    function withdrawByVoter(
        uint256 id,
        uint256 candidate,
        address to
    ) external nonReentrant {
        CompetitionStruct.Competition memory c = competitionMapping[id];
        if (block.timestamp <= c.endTime) {
            revert CompetitionNotEnd();
        }
        if (voterMapping[_msgSender()][id][candidate].isWithdraw){
            revert DuplicateWithdraw();
        }
        uint tickets = voterMapping[_msgSender()][id][candidate].tickets;
        if(tickets == 0){
            revert NoAccess();
        }
        voterMapping[_msgSender()][id][candidate].isWithdraw = true;
        if(c.mode == CompetitionStruct.Mode.PROPORTION){

        } else if (c.mode == CompetitionStruct.Mode.SHARE_PRO){
            for (uint i = 0; i < c.winners.length; ++i) {
                if (candidate == c.winners[i]) {
                    uint rewards = c.rewards[i] * (10000 - c.proportionToPlayer) /
                        10000;
                    SafeERC20.safeTransfer(c.rewardCoin, to, rewards);
                    // calculate proportion
                    uint256 proportion = _rewardProportion(
                        c.rewards,
                        c.rewards[i]
                    );

                    uint sharedCoins = (c.totalCoins *
                        proportion *
                        (10000 - c.proportionToPlayer)) / 1e8;
                    
                    sharedCoins = sharedCoins * tickets / candidateMapping[id][candidate].tickets;
                    
                    SafeERC20.safeTransfer(c.ticketCoin, to, sharedCoins);

                    emit WithdrawByVoter(id, candidate, to, rewards, tickets);
                    break;
                }
            }
        }else{
            SafeERC20.safeTransfer(c.ticketCoin, to, tickets);
            if(c.mode == CompetitionStruct.Mode.SHARE){
                for (uint i = 0; i < c.winners.length; ++i) {
                    if (candidate == c.winners[i]) {
                        uint rewards = c.rewards[i] * (10000 - c.proportionToPlayer) /
                            10000;
                        SafeERC20.safeTransfer(c.rewardCoin, to, rewards);
                        emit WithdrawByVoter(id, candidate, to, rewards, tickets);
                        break;
                    }
                }
            }
        }
    }

    function _rewardProportion(
        uint[] memory rewards,
        uint reward
    ) internal pure returns (uint256 proportion) {
        proportion = (reward * 10000) / _totalRewards(rewards);
    }

    function _totalRewards(
        uint[] memory rewards
    ) internal pure returns (uint256 totalRewards) {
        for (uint i = 0; i < rewards.length; ++i) {
            totalRewards += rewards[i];
        }
    }


    function isCalculator(address _address) public view returns (bool) {
        // Check if the given address has the required ITicketCalculator functions
        try ITicketCalculator(_address).calculateTickets(1) returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }

    function setWhiteCoin(address coin, bool available) external onlyRole(DEFAULT_ADMIN_ROLE){
        whiteCoins[coin] = available;
        emit UpdateWhiteCoin(coin, available);
    }
}
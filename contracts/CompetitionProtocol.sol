// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./structs/CompetitionStruct.sol";
import "./interfaces/ICompetitionProtocol.sol";
import "./interfaces/ITicketCalculator.sol";

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
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) voterMapping;
    // white coins list
    mapping(address => bool) public whiteCoins;

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
        if (startTime < block.timestamp || endTime < startTime) {
            revert InvalidTime();
        }
        // if (!whiteCoins[rewardCoin]){
        //     revert InvalidRewards();
        // }
        if (rewards.length == 0 || rewards[0] == 0) {
            revert EmptyRewards();
        }

        uint256 totalRewards;
        for (uint i = 0; i < rewards.length; ++i) {
            totalRewards += rewards[i];
        }
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
        if(mode != CompetitionStruct.Mode.PROPORTION){
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

        emit Vote(id, candidate, _msgSender(), tickets);
    }

    function realTickets(uint256 id, uint256 coins) public view returns (uint256) {
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
        for (uint i = 0; i < winnerArray.length; i++) {
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
                for (uint j = i; j < winnerArray.length; j++) {
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

    function winners(
        uint256 id
    ) external view returns (CompetitionStruct.Candidate[] memory) {}

    function withdrawRewards(uint256 id, uint256 candidate) external {}

    function isCalculator(address _address) public view returns (bool) {
        // Check if the given address has the required ITicketCalculator functions
        try ITicketCalculator(_address).calculateTickets(1) returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }
}
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IBaseCompetition.sol";
import "./interfaces/ITeller.sol";
import "hardhat/console.sol";

library Structs{
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
        uint256[] rewards;
        uint256[] winners;
        IERC20 rewardCoin;
        IERC20 ticketCoin;
        uint256 totalCandidates;
        // start time
        uint64 startTime;
        // end time
        uint64 endTime;
    }
}

contract DefaultCompetition is
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable,
    IBaseCompetition
{
    modifier OnlyHost(Structs.Competition storage competition) {
        if (_msgSender() != competition.host) {
            revert NotHost();
        }
        _;
    }

    modifier CompetitionOngoing(Structs.Competition storage competition) {
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
    mapping(uint256 => Structs.Competition) public competitionMapping;
    // id => calculator
    mapping(uint256 => ITeller) public calculatorMapping;
    mapping(uint256 => uint256) private totalTicketsMapping;
    // competition => candidate => details
    mapping(uint256 => mapping(uint256 => Structs.Candidate))
        public candidateMapping;
    // address => competition => candidate => coins;
    mapping(address => mapping(uint256 => mapping(uint256 => Structs.Voter))) voterMapping;

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
        uint64 endTime
    ) external nonReentrant returns (uint256 id) {
        ++totalCompetitions;
        if (endTime <= block.timestamp) {
            revert InvalidTime();
        }
        if (startTime == 0) {
            startTime = uint64(block.timestamp);
        }
        // if (!whiteCoins[rewardCoin]){
        //     revert InvalidRewards();
        // }
        if (rewards.length == 0 || rewards[0] == 0) {
            revert EmptyRewards();
        }
        uint256 totalRewards = _totalRewards(rewards);
        console.log("totalRewards: ", totalRewards);
        SafeERC20.safeTransferFrom(
            IERC20(rewardCoin),
            _msgSender(),
            address(this),
            totalRewards
        );
        Structs.Competition memory c;
        c.host = _msgSender();
        c.ticketCoin = IERC20(ticketCoin);
        c.rewardCoin = IERC20(rewardCoin);
        c.rewards = rewards;
        c.startTime = startTime;
        c.endTime = endTime;
        c.winners = new uint256[](rewards.length);

        competitionMapping[totalCompetitions] = c;

        emit NewCompetition(totalCompetitions, _msgSender());
        return totalCompetitions;
    }

    function setTicketCalculator(
        uint256 id,
        address calculator
    ) external {
        if (competitionMapping[id].startTime < block.timestamp) {
            revert CompetitionStarted();
        }

        if (!isCalculator(calculator)) {
            revert InvalidCalculator();
        }
        calculatorMapping[id] = ITeller(calculator);
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

                SafeERC20.safeTransfer(c.rewardCoin, to, c.rewards[i]);

                emit WithdrawByPlayer(id, candidate, to, c.rewards[i], 0);

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
        emit WithdrawByVoter(id, candidate, to, 0, tickets);
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
        // Check if the given address has the required ITeller functions
        try ITeller(_address).calculateTickets(1) returns (uint256) {
            return true;
        } catch {
            return false;
        }
    }

    function details(
        uint256 id
    )
        external
        view
        override
        returns (
            address host,
            uint256[] memory rewards,
            uint256[] memory winners,
            address rewardCoin,
            address ticketCoin,
            uint256 totalCandidates,
            uint64 startTime,
            uint64 endTime
        )
    {
        Structs.Competition memory c = competitionMapping[id];
        host = c.host;
        rewards = c.rewards;
        winners = c.winners;
        rewardCoin = address(c.rewardCoin);
        ticketCoin = address(c.ticketCoin);
        totalCandidates = c.totalCandidates;
        startTime = startTime;
        endTime = endTime;
    }
}
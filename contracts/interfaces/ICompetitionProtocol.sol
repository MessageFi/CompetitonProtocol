// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/CompetitionStruct.sol";

interface ICompetitionProtocol{

    error InvalidCandidate();
    error InvalidCalculator();
    error EmptyRewards();
    error NotHost();
    error InvalidTickets();
    error InvalidRewards();
    error InvalidTime();
    error BlockedCoin();
    error CompetitionNotOngoing();
    error CompetitionStarted();
    error CompetitionEnded();

    event NewCompetition(uint256 indexed id, address host);

    event NewCandidate(uint256 indexed id, uint256 candidate, address player);

    event UpdateWhiteCoinList(address coin, bool available);

    event Vote(uint256 indexed id, uint256 candidate, address voter, uint256 tickets);

    event WinnerChanged(uint256 indexed id);

    // create a competition
    function create(address ticketCoin, address rewardCoin, uint256[] calldata rewards,
     uint64 startTime, uint64 endTime, CompetitionStruct.Mode mode, uint64 proportionToPlayer) external returns(uint256 id);

    function setTicketCalculator(uint256 id, address calculator) external;

    function registerCandidate(uint256 id, address player) external returns (uint256 candidateId) ;

    function vote(uint256 id, uint256 candidate, uint256 tickets) external;

    function winners(uint256 id) view external returns (CompetitionStruct.Candidate[] memory);

    function withdrawRewards(uint256 id, uint256 candidate) external;
}
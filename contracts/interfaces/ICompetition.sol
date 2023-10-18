// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../structs/CompetitionStruct.sol";

interface ICompetition{
    event NewEvent(uint256 indexed id, address indexed host);

    // create a competition
    function create(address voteCoin, address rewardsCoin, uint256 rewardAmount,
     uint64 startTime, uint64 endTime) external returns(uint256 id);

    function setTicketCalculator(address calculator) external;

    function registerCandidate(address player) external returns (uint256 candidateId) ;

    function vote(uint256 competition, uint256 candidate, address voter, uint256 tickets) external;

    function getVotes(uint256 competition, uint256 candidate) external returns(uint256);

    function winners(uint256 competition) view external returns (CompetitionStruct.Candidate[] memory);

    function withdrawRewards(uint256 competition, uint256 candidate) external;
}
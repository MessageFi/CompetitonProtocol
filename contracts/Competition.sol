// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./structs/CompetitionStruct.sol";
import "./interfaces/ICompetition.sol";

contract Competition is AccessControlUpgradeable, ReentrancyGuardUpgradeable, ICompetition{

    // modifier OnlyOrigin {
    //     if (_msgSender() != tx.origin) {
    //         revert CallFromOutside();
    //     }
    //     _;
    // }
    uint256 public totalCompetition;
    // id => competition details
    mapping(uint256 => CompetitionStruct.Events) public competitionMapping;
    // id => calculator
    mapping(uint256 => address) public calculatorMapping;
    // competition => candidate => details
    mapping(uint256 => mapping(uint256 => CompetitionStruct.Candidate)) public candidateMapping;
    // competition => winners
    mapping(uint256 => uint256[]) winnerMapping;

    function initialize() public initializer {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }
    
    // create a competition
    function create(address voteCoin, address rewardsCoin, uint256 rewardAmount,
     uint64 startTime, uint64 endTime) external returns(uint256 id){
        ++totalCompetition;
        competitionMapping[totalCompetition].host = _msgSender();
        return totalCompetition;
    }



    function setTicketCalculator(address calculator) external{

    }

    function registerCandidate(address player) external returns (uint256 candidateId){

    }

    function vote(uint256 competition, uint256 candidate, address voter, uint256 tickets) external{

    }

    function getVotes(uint256 competition, uint256 candidate) external returns(uint256){

    }

    function winners(uint256 competition) view external returns (CompetitionStruct.Candidate[] memory){

    }

    function withdrawRewards(uint256 competition, uint256 candidate) external{

    }
}
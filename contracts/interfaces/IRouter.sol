// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IRouter{
    function protocolContrat(uint256 protocol) view external returns(address);

    function createCompetition(uint256 protocol, address ticketCoin, address rewardCoin,
     uint256[] calldata rewards,
     uint64 startTime, uint64 endTime, bytes memory params) external returns(uint256);

    function createZkCompetition(address rewardCoin,
     uint256[] calldata rewards,
     uint64 startTime, uint64 endTime, bytes memory params) external returns(uint256);
}
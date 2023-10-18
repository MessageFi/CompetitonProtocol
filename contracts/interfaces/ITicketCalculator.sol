// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITicketCalculator {
    // use zk to avoid changes on calculator
    function getTickets(uint256 amount) external view returns(uint256);
}
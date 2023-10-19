// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITeller {
    function calculateTickets(uint256 amount) external view returns(uint256);
}
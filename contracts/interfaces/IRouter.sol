// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// manage protocol, white coins and tellers
interface IRouter{

    error BlockedCoin();

    event UpdateWhiteCoin(address coin, bool available);

    function protocolContrat(uint256 protocol) view external returns(address);

    // function setWhiteCoin(address coin, bool available) external onlyRole(DEFAULT_ADMIN_ROLE){
    //     whiteCoins[coin] = available;
    //     emit UpdateWhiteCoin(coin, available);
    // }
}
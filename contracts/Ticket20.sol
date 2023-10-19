// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Ticket20 is ERC20 {

    constructor() ERC20("Ticket Coin", "Ticket") {
        _mint(_msgSender(), 1e9);
    }

    function mint() external{
        _mint(_msgSender(), 100);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
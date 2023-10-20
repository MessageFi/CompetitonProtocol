// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Reward20 is ERC20 {

    constructor() ERC20("Reward Coin", "Reward") {
        _mint(_msgSender(), 1e10);
    }

    function mint() external{
        _mint(_msgSender(), 100);
    }

    function decimals() public view virtual override returns (uint8) {
        return 0;
    }
}
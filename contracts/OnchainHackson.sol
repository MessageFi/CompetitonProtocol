// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./interfaces/ITeller.sol";
import "./interfaces/IBaseCompetition.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

contract OnchainHackson is ITeller{

    struct Team {
        string name;
        address player;
        string product;
        string logo;
        string description;
    }

    IBaseCompetition public competitionProtocol;
    string public competitionName = "Onchain Hackson";
    uint256 public id;
    mapping (uint256 => Team) public teamMapping;

    constructor(address protocol){
        competitionProtocol = IBaseCompetition(protocol);
    }

    function init(address ticketCoin, address rewardCoin, uint64 period) external{
        require(id == 0);
        uint256[] memory rewards = new uint256[](3);
        rewards[0] = 10000;
        rewards[1] = 5000;
        rewards[2] = 2000;
        SafeERC20.safeTransferFrom(
            IERC20(rewardCoin),
            msg.sender,
            address(this),
            17000
        );
        SafeERC20.safeApprove(IERC20(rewardCoin), address(competitionProtocol), 1e9);
        id = competitionProtocol.create(ticketCoin, rewardCoin, rewards, uint64(block.timestamp + 1), uint64(block.timestamp + period));
        competitionProtocol.setTicketCalculator(id, address(this));
    }

    function register(string calldata name) external returns (uint256 teamId){
        require(bytes(name).length > 0 && bytes(name).length < 256);
        teamId = competitionProtocol.registerCandidate(id, msg.sender);
        teamMapping[teamId].name = name;
        teamMapping[teamId].player = msg.sender;
    }

    function reset() external {
        (, , , , ,uint256 totalCandidates, ,) = competitionProtocol.details(id);
        id = 0;
        for (uint i = 1; i <= totalCandidates; i++) {
            delete teamMapping[i];
        }
    }

    function submitWorks(uint256 teamId,
        string calldata product,
        string calldata logo,
        string calldata description) external{

        (, , , , , , , uint64 endtime) = competitionProtocol.details(id);
        
        require(block.timestamp <= endtime, "Competition ended");

        Team storage team = teamMapping[teamId];
        team.logo = logo;
        team.product = product;
        team.description = description;
    }

    function winners() external view returns(uint256[] memory){
        (, ,uint256[] memory teamIds, , , , ,uint64 endtime) = competitionProtocol.details(id);
        require(block.timestamp > endtime, "Competition not ended");
        return teamIds;
    }

    function calculateTickets(uint256 amount) external pure returns(uint256 tickets){
        return amount/10;
    }
}
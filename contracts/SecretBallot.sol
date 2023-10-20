// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../zokrates/verifier.sol";

contract SecretBallot{

    // Voters
    address[4] public voters;

    // Vote options
    uint256[2] public options;

    Verifier public verifier;
    
    uint64 public startTime;
    uint64 public endTime;

    // VOTE PHASE
    mapping(uint256 => uint256) public voteTally;

    mapping(bytes32 => bool) public proofIsUsed;

    constructor(
        address[4] memory voters_,
        uint256 [2] memory options_,
        uint64 startTime_,
        uint64 endTime_
    ) {
        require(endTime_ > startTime_);
        voters = voters;
        options = options_;
        startTime = startTime_;
        endTime = endTime_;
        verifier = new Verifier();
    }

    function vote(
        uint256 option,
        uint256[4] memory input, 
        Verifier.Proof memory proof
    ) external {
        require(block.timestamp > startTime && block.timestamp < endTime, "Not ongoing");
        require(option == options[0] || option == options[1], "Invalid option");
        require(verifier.verifyTx(proof, input), "Verify Failed");
        bytes32 digest = keccak256(abi.encode(proof));
        require(!proofIsUsed[digest], "Proof is used");
        voteTally[option]++;
    }
}
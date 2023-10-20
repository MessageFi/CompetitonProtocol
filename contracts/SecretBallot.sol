// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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
        uint[2] calldata proof_a,
        uint[2][2] calldata proof_b,
        uint[2] calldata proof_c
    ) external {
        require(block.timestamp > startTime && block.timestamp < endTime, "Not ongoing");
        require(option == options[0] || option == options[1], "Invalid option");
        Verifier.Proof memory proof;
        proof.a = Pairing.G1Point(proof_a[0], proof_a[1]);
        proof.b = Pairing.G2Point(proof_b[0], proof_b[1]);
        proof.c = Pairing.G1Point(proof_c[0], proof_c[1]);
        require(verifier.verifyTx(proof, input), "Verify Failed");
        bytes32 digest = keccak256(abi.encode(proof));
        require(!proofIsUsed[digest], "Proof is used");
        voteTally[option]++;
    }
}
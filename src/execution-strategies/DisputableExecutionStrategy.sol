// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { IArbitratorV1 } from "../interfaces/execution-strategies/kleros/IArbitratorV1.sol";
import { IArbitrableV1 } from "../interfaces/execution-strategies/kleros/IArbitrableV1.sol";
import { IEvidenceV1 } from "../interfaces/execution-strategies/kleros/IEvidenceV1.sol";
import { SimpleQuorumExecutionStrategy } from "./SimpleQuorumExecutionStrategy.sol";
import { MetaTransaction, Proposal, ProposalStatus } from "../types.sol";

/// @title Disputable Execution Strategy
/// @notice
/// @dev
contract DisputableExecutionStrategy is SimpleQuorumExecutionStrategy, IArbitrableV1, IEvidenceV1 {
    struct ProposalDispute {
        uint256 proposalId;
        uint256 ruling;
        bool disputed;
    }

    address public target;
    address public arbitrator;
    bytes public arbitratorExtraData;
    uint256 public metaEvidenceID;
    uint256 public disputableDuration; // blocks from proposal.startBlockNumber
    mapping(uint256 => ProposalDispute) public disputeIDToDispute;
    mapping(uint256 => uint256) public proposalIDToDisputeID;

    /// @notice Constructor
    /// @param _owner Address of the owner of this contract.
    /// @param _target Address of the avatar that this module will pass transactions to.
    /// @param _spaces Array of whitelisted space contracts.
    /// @param _quorum The quorum required to execute a proposal.
    /// @param _arbitrator The address of the arbitrator contract.
    /// @param _arbitratorExtraData The extra data used to raise a dispute in the arbitrator contract.
    /// @param _metaEvidence The meta-evidence for the arbitrator contract.
    /// @param _disputableDuration The number of blocks that a proposal is disputable for.
    constructor(
        address _owner,
        address _target,
        address[] memory _spaces,
        uint256 _quorum,
        address _arbitrator,
        bytes memory _arbitratorExtraData,
        string memory _metaEvidence,
        uint256 _disputableDuration
    ) {
        bytes memory initParams = abi.encode(
            _owner,
            _target,
            _spaces,
            _quorum,
            _arbitrator,
            _arbitratorExtraData,
            _metaEvidence,
            _disputableDuration
        );
        setUp(initParams);
    }

    /// @notice Initialization function, should be called immediately after deploying a new proxy to this contract.
    /// @param initParams ABI encoded parameters, in the same order as the constructor.
    function setUp(bytes memory initParams) public initializer {
        (
            address _owner,
            address _target,
            address[] memory _spaces,
            uint256 _quorum,
            address _arbitrator,
            bytes memory _arbitratorExtraData,
            string memory _metaEvidence,
            uint256 _disputableDuration
        ) = abi.decode(initParams, (address, address, address[], uint256, address, bytes, string, uint256));
        __Ownable_init();
        transferOwnership(_owner);
        __SpaceManager_init(_spaces);
        __SimpleQuorumExecutionStrategy_init(_quorum);
        target = _target;
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
        disputableDuration = _disputableDuration;
        emit MetaEvidence(metaEvidenceID, _metaEvidence);
    }

    function setMetaEvidence(string calldata _metaEvidence) external onlyOwner {
        emit MetaEvidence(++metaEvidenceID, _metaEvidence);
    }

    function createDispute(uint256 _proposalId) external payable {
        uint256 disputeID = IArbitratorV1(arbitrator).createDispute{ value: msg.value }(2, arbitratorExtraData);
        disputeIDToDispute[_proposalId] = ProposalDispute({ proposalId: _proposalId, ruling: 0, disputed: true });
        proposalIDToDisputeID[_proposalId] = disputeID;
        emit Dispute(arbitrator, disputeID, metaEvidenceID, _proposalId);
    }

    function submitEvidence(string memory _evidence, uint256 _proposalID) external {
        uint256 disputeID = proposalIDToDisputeID[_proposalID];
        if (disputeID == 0) revert NoDisputeIDForProposalID();
        emit Evidence(arbitrator, disputeID, msg.sender, _evidence);
    }

    function rule(uint256 _disputeID, uint256 _ruling) external override {
        if (msg.sender != arbitrator) revert ArbitratorOnly();
        emit Ruling(msg.sender, _disputeID, _ruling);
    }

    /// @notice Executes a proposal from the avatar contract if the proposal outcome is accepted.
    ///         Must be called by a whitelisted space contract.
    /// @param proposal The proposal to execute.
    /// @param votesFor The number of votes in favor of the proposal.
    /// @param votesAgainst The number of votes against the proposal.
    /// @param votesAbstain The number of abstaining votes.
    /// @param payload The encoded transactions to execute.
    function execute(
        uint256 _proposalId,
        Proposal memory proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        uint256 votesAbstain,
        bytes memory payload
    ) external override onlySpace {
        ProposalStatus proposalStatus = getProposalStatus(proposal, votesFor, votesAgainst, votesAbstain);
        if ((proposalStatus != ProposalStatus.Accepted) && (proposalStatus != ProposalStatus.VotingPeriodAccepted)) {
            revert InvalidProposalStatus(proposalStatus);
        }
        _execute(_proposalId, payload);
    }

    /// @notice Decodes and executes a batch of transactions from the avatar contract.
    /// @param payload The encoded transactions to execute.
    function _execute(uint256 _proposalId, bytes memory payload) internal {
        uint256 disputeID = proposalIDToDisputeID[_proposalId];
        ProposalDispute storage proposalDispute = disputeIDToDispute[disputeID];
        if (proposalDispute.disputed) {
            if (proposalDispute.ruling != 1) {
                // 0 = RFA or invalid dispute
                // 2 = invalid proposal
                return;
            }
        } else if (block.number < proposalDispute.proposalId + disputableDuration) {
            // The disputable period has not passed, do nothing.
            return;
        }
        (bool success, ) = target.call(payload);
        if (!success) revert ExecutionFailed();
    }

    /// @notice Returns the trategy type string.
    function getStrategyType() external pure override returns (string memory) {
        return "DisputableExecutionStrategy";
    }

    error NoDisputeIDForProposalID();
    error ArbitratorOnly();
}

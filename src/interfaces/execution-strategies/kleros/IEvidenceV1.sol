// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @title IMetaEvidence
/// ERC-1497: Evidence Standard excluding evidence emission as it will be handled by the arbitrator.
interface IEvidenceV1 {
    /// @dev To be emitted when meta-evidence is submitted.
    /// @param _metaEvidenceID Unique identifier of meta-evidence.
    /// @param _evidence IPFS path to metaevidence, example: '/ipfs/Qmarwkf7C9..cJjMFH/metaevidence.json'
    event MetaEvidence(uint256 indexed _metaEvidenceID, string _evidence);

    /// @dev To be raised when evidence is submitted.
    /// @param _arbitrator The arbitrator of the contract.
    /// @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
    /// @param _party The address of the party submiting the evidence with 0x0 referring to evidence not submitted by any party.
    /// @param _evidence IPFS path to evidence, example: '/ipfs/Qmarwkf7C9..zx78acJjMFH/evidence.json'
    event Evidence(
        address indexed _arbitrator,
        uint256 indexed _evidenceGroupID,
        address indexed _party,
        string _evidence
    );

    /// @dev To be emitted when a dispute is created to link the correct meta-evidence to the disputeID.
    /// @param _arbitrator The arbitrator of the contract.
    /// @param _disputeID ID of the dispute in the Arbitrator contract.
    /// @param _metaEvidenceID Unique identifier of meta-evidence.
    /// @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
    event Dispute(
        address indexed _arbitrator,
        uint256 indexed _disputeID,
        uint256 _metaEvidenceID,
        uint256 _evidenceGroupID
    );
}

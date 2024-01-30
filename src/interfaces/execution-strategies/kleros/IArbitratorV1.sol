// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/// @title Arbitrator
/// Arbitrator abstract contract  compliant with ERC-792.
/// When developing arbitrator contracts we need to:
/// - Define the functions for dispute creation (createDispute) and appeal (appeal).
///   Don't forget to store the arbitrated contract and the disputeID (which should be unique, may nbDisputes).
/// - Define the functions for cost display (arbitrationCost and appealCost).
/// - Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
interface IArbitratorV1 {
    /// @dev Create a dispute. Must be called by the arbitrable contract.
    /// Must be paid at least arbitrationCost(_extraData).
    /// @param _choices Amount of choices the arbitrator can make in this dispute.
    /// @param _extraData Can be used to give additional info on the dispute to be created.
    /// @return disputeID ID of the dispute created.
    function createDispute(uint256 _choices, bytes calldata _extraData) external payable returns (uint256 disputeID);
}

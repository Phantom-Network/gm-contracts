// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title gm.co Event
 * @author projectPXN
 * @custom:coauthor bldr
 * @notice gm.co is a Business-to-Consumer (B2C) and Peer-to-Peer (P2P) marketplace
 *         using blockchain technology for proof of transactions and allow users
 *         to buy and sell real world goods using cryptocurrency.
 */
contract GreyMarketEvent {
    event NewProofSigner(address newProofSigner);

    event OrderCreated(bytes32 id, address indexed buyer, address indexed seller, uint8 paymentType, uint8 orderType, uint256 blockTimestamp, uint256 amount);

    event OrderCancelled(bytes32 id, address indexed buyer, address indexed seller, uint256 blockTimestamp);

    event OrderCompleted(bytes32 id, address indexed buyer, address indexed seller, uint256 blockTimestamp);






    event WithdrawAdminFee(address caller, address recipient, address token, uint256 amount);

    event NewTransactionFee(uint256 newTransactionFee);
}

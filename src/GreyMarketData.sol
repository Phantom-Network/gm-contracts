// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

string constant CONTRACT_NAME = "GreyMarket Contract";
    
bytes32 constant CREATE_ORDER_TYPEHASH = 
    keccak256(
        "Create(bytes32 id,address buyer,address seller,address paymentToken,uint8 orderType,uint256 amount)"
    );

bytes32 constant CLAIM_ORDER_TYPEHASH = 
    keccak256(
        "Claim(bytes32 id,address buyer,address seller,uint256 amount,address paymentToken,uint8 orderType,uint8 orderStatus)"
    );
    
bytes32 constant WITHDRAW_ORDER_TYPEHASH = 
    keccak256(
        "Withdraw(bytes32 id,address buyer,address seller,address paymentToken,uint256 amount,uint8 orderStatus)"
    );

bytes32 constant RELEASE_DISPUTED_ORDER_TYPEHASH = 
    keccak256(
        "Release(bytes32 id,address buyer,address seller,address paymentToken,address winner,uint8 orderStatus)"
    );

uint256 constant MAX_TRANSACTION_FEE = 10000;
uint256 constant MAX_ESCROW_FEE = 5000;
uint256 constant MAX_ESCROW_PENDING_PERIOD = 6 * 30 days;
uint256 constant MIN_ESCROW_PENDING_PERIOD = 7 days;
uint256 constant REQUIRED_SIGNATURE_COUNT = 2;
uint256 constant MAX_ESCROW_LOCK_PERIOD = 12 * 30 days;
uint256 constant MIN_ESCROW_LOCK_PERIOD = 6 * 30 days;

/*enum OrderType {
    DIRECT == 0
    ESCROW == 1
}*/


/*enum PaymentType {
    PAYMENT_ETH,
    PAYMENT_ERC20
}*/

/*enum OrderStatus {
    ORDER_NONE, // 0
    ORDER_CREATED, // 1
    ORDER_PENDING, // 2
    ORDER_TRANSIT, // 3
    ORDER_DELIVERED, // 4
    ORDER_COMPLETED, // 5
    ORDER_CANCELLED, // 6
    ORDER_DISPUTE, // 7
    ORDER_DISPUTE_HANDLED, // 8
    ORDER_ADMIN_WITHDRAWN // 9
}*/

struct Sig {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

string constant CONTRACT_NAME = "GreyMarket Contract";
    
bytes32 constant DOMAIN_TYPEHASH = 
    keccak256(
        "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
     );
    
bytes32 constant CREATE_ORDER_TYPEHASH = 
    keccak256(
        "Create(bytes32 id,address buyer,address seller,address paymentToken,uint256 orderType,uint256 amount)"
    );

bytes32 constant CLAIM_ORDER_TYPEHASH = 
    keccak256(
        "Claim(bytes32 id,address buyer,address seller,uint256 orderStatus)"
    );
    
bytes32 constant WITHDRAW_ORDER_TYPEHASH = 
    keccak256(
        "Withdraw(bytes32 id,address buyer,address seller,uint256 orderStatus)"
    );

bytes32 constant RELEASE_DISPUTED_ORDER_TYPEHASH = 
    keccak256(
        "Release(bytes32 id,address buyer,address seller,uint256 orderStatus,address winner)"
    );

uint256 constant MAX_TRANSACTION_FEE = 10000;
uint256 constant MAX_ESCROW_FEE = 5000;
uint256 constant MAX_ESCROW_PENDING_PERIOD = 6 * 30 days;
uint256 constant MIN_ESCROW_PENDING_PERIOD = 7 days;
uint256 constant REQUIRED_SIGNATURE_COUNT = 2;
uint256 constant MAX_ESCROW_LOCK_PERIOD = 12 * 30 days;
uint256 constant MIN_ESCROW_LOCK_PERIOD = 6 * 30 days;

enum PaymentType {
    PAYMENT_ETH,
    PAYMENT_ERC20
}

enum OrderStatus {
    ORDER_NONE,
    ORDER_CREATED,
    ORDER_PENDING,
    ORDER_TRANSIT,
    ORDER_DELIVERED,
    ORDER_COMPLETED,
    ORDER_CANCELLED,
    ORDER_DISPUTE,
    ORDER_DISPUTE_HANDLED,
    ORDER_ADMIN_WITHDRAWN
}

enum OrderType {
    ESCROW,
    DIRECT,
    COUNT
}

struct Order {
    bytes32 id;
    address buyer;
    address seller;
    OrderStatus status;
    PaymentType paymentType;
    address paymentToken;
    uint256 amount;
    OrderType orderType;
    bytes sellerSignature;
    uint128 createdAt;
    uint128 cancelledAt;
    uint128 completedAt;
    uint128 disputedAt;
}

struct Sig {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

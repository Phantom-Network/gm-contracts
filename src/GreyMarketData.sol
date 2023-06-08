// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

string constant CONTRACT_NAME = "GreyMarket Contract";
    
bytes32 constant CREATE_ORDER_TYPEHASH = 
    keccak256(
        "Create(bytes32 id,address buyer,address seller,address paymentToken,uint8 orderType,uint256 amount)"
    );

bytes32 constant CLAIM_ORDER_TYPEHASH = 
    keccak256(
        "Claim(bytes32 id,address buyer,address seller,uint256 amount,address paymentToken,uint8 orderType)"
    );
    
bytes32 constant WITHDRAW_ORDER_TYPEHASH = 
    keccak256(
        "Withdraw(bytes32 id,address buyer,address seller,address paymentToken,uint256 amount)"
    );

bytes32 constant RELEASE_DISPUTED_ORDER_TYPEHASH = 
    keccak256(
        "Release(bytes32 id,address buyer,address seller,address paymentToken,address winner,uint8 orderStatus)"
    );

uint256 constant MAX_TRANSACTION_FEE = 10000;
uint256 constant MAX_ESCROW_FEE = 5000;
struct Sig {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

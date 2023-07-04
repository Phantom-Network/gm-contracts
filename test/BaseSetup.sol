//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "forge-std/Test.sol";
import "../src/GreyMarket.sol";
import "../src/MockERC20.sol";
import "./Utils/Utilities.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract BaseSetup is Test {
    Utilities internal utils;
    MockERC20 internal mockERC20;
    GreyMarket internal greyMarket;
    MockERC20 internal unsupportedMockERC20;

    address payable[] internal users;
    address internal owner;
    address internal buyer;
    address internal seller;
    address internal signer;
    uint256 internal signerPrivateKey;
    address internal signer2;
    uint256 internal signerPrivateKey2;

    function setUp() public virtual {
        // generate fake users
        utils = new Utilities();
        users = utils.createUsers(3);
        owner = users[0];
        seller = users[1];
        buyer = users[2];
        
        signerPrivateKey = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        signer = vm.addr(signerPrivateKey);
        
        signerPrivateKey2 = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, block.number)));
        signer2 = vm.addr(signerPrivateKey2);

        mockERC20 = new MockERC20(buyer);
        unsupportedMockERC20 = new MockERC20(buyer);
        
        vm.startPrank(owner);
        greyMarket = new GreyMarket(signer);
        vm.stopPrank();
    }

    function randomOrderID() public view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, block.difficulty));
    }

    function generateOrderDigest(bytes32 orderId, uint8 orderType, address paymentToken) public view returns(bytes32) {
        bytes32 digest = greyMarket.hash(keccak256(abi.encode(
                CREATE_ORDER_TYPEHASH,
                orderId,
                buyer,
                seller,
                paymentToken,
                orderType,
                1000000
        )));

        return digest;
    }

    function generateOrderClaimDigest(bytes32 orderId, uint256 amount, address paymentToken, uint8 orderType) public view returns(bytes32) {
        bytes32 digest = greyMarket.hash(keccak256(abi.encode(
                CLAIM_ORDER_TYPEHASH,
                orderId,
                seller,
                amount,
                paymentToken,
                orderType
        )));

        return digest;
    }

    function generateWithdrawDigest(bytes32 orderId, uint256 amount, address paymentToken) public view returns(bytes32) {
        bytes32 digest = greyMarket.hash(keccak256(abi.encode(
                WITHDRAW_ORDER_TYPEHASH,
                orderId,
                buyer,
                seller,
                paymentToken,
                amount
        )));

        return digest;
    }
}
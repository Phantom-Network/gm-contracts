//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "forge-std/Test.sol";
import "../src/GreyMarket.sol";
import "../src/MockERC20.sol";
import "./Utils/Utilities.sol";
import "./BaseSetup.sol";

contract Orders is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testCreateOrderNativePaymentEscrow() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                greyMarket.domainSeperator(),
                keccak256(
                    abi.encode(
                        greyMarket.CREATE_ORDER_TYPEHASH(),
                        orderId,
                        buyer,
                        seller,
                        nativeEthPaymentToken,
                        OrderType.ESCROW,
                        testAmount
                    )
                )
            )
        );

        vm.startPrank(buyer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, digest);
        
        greyMarket.createOrder{value: testAmount}(
            orderId, 
            seller, 
            nativeEthPaymentToken, 
            OrderType.ESCROW, 
            testAmount, 
            Sig(v, r, s)
        );

        vm.stopPrank();
        
        OrderInfo memory order = greyMarket.getOrderInfo(orderId);
        assertEq(order.buyer, buyer);
        assertEq(order.seller, seller);
        assertEq(order.paymentToken, nativeEthPaymentToken);
        assertEq(order.amount, testAmount);
    }

    function testCreateOrderNativePaymentDirect() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                greyMarket.domainSeperator(),
                keccak256(
                    abi.encode(
                        greyMarket.CREATE_ORDER_TYPEHASH(),
                        orderId,
                        buyer,
                        seller,
                        nativeEthPaymentToken,
                        OrderType.DIRECT,
                        testAmount
                    )
                )
            )
        );

        vm.startPrank(buyer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, digest);
        
        greyMarket.createOrder{value: testAmount}(
            orderId, 
            seller, 
            nativeEthPaymentToken, 
            OrderType.DIRECT, 
            testAmount,
            Sig(v, r, s)
        );

        vm.stopPrank();

        OrderInfo memory order = greyMarket.getOrderInfo(orderId);
        assertEq(order.buyer, buyer);
        assertEq(order.seller, seller);
        assertEq(order.paymentToken, nativeEthPaymentToken);
        assertEq(order.amount, testAmount);
    }

    function testCreateOrderNativePaymentWrongSigner() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                greyMarket.domainSeperator(),
                keccak256(
                    abi.encode(
                        greyMarket.CREATE_ORDER_TYPEHASH(),
                        orderId,
                        buyer,
                        seller,
                        nativeEthPaymentToken,
                        OrderType.ESCROW,
                        testAmount
                    )
                )
            )
        );

        vm.startPrank(buyer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        
        vm.expectRevert("createOrder: invalid signature");
        greyMarket.createOrder{value: testAmount}(
            orderId, 
            seller, 
            nativeEthPaymentToken, 
            OrderType.ESCROW, 
            testAmount, 
            Sig(v, r, s)
        );

        vm.stopPrank();
    }

    function testClaimOrderEscrow() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                greyMarket.domainSeperator(),
                keccak256(
                    abi.encode(
                        greyMarket.CREATE_ORDER_TYPEHASH(),
                        orderId,
                        buyer,
                        seller,
                        nativeEthPaymentToken,
                        OrderType.ESCROW,
                        testAmount
                    )
                )
            )
        );

        vm.startPrank(buyer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, digest);
        
        greyMarket.createOrder{value: testAmount}(
            orderId, 
            seller, 
            nativeEthPaymentToken, 
            OrderType.ESCROW, 
            testAmount, 
            Sig(v, r, s)
        );

        vm.stopPrank();

        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                greyMarket.domainSeperator(),
                keccak256(
                    abi.encode(
                        greyMarket.CLAIM_ORDER_TYPEHASH(),
                        orderId,
                        buyer,
                        seller,
                        OrderStatus.ORDER_DELIVERED
                    )
                )
            )
        );

        vm.startPrank(seller);
        (v, r, s) = vm.sign(sellerPrivateKey, digest);
        greyMarket.claimOrder(orderId, buyer, seller, Sig(v, r, s));
    }
}
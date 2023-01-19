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

    function testWithdrawDirectOrder() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.DIRECT, address(0));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        
        vm.prank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(0), 
            OrderType.DIRECT, 
            1000000, 
            Sig(v, r, s)
        );

        uint256 buyerBalanceBefore = address(buyer).balance;

        digest = generateWithdrawDigest(orderId);

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.withdrawOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );

        Order memory order = greyMarket.getOrderInfo(orderId);

        assertEq(uint256(order.status), uint256(OrderStatus.ORDER_CANCELLED));
        assertEq(address(buyer).balance, buyerBalanceBefore + 1000000);
    }

    function testWithdrawEscrowOrder() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.ESCROW, address(0));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        
        vm.prank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(0), 
            OrderType.ESCROW, 
            1000000, 
            Sig(v, r, s)
        );

        uint256 buyerBalanceBefore = address(buyer).balance;

        digest = generateWithdrawDigest(orderId);

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.withdrawOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );

        Order memory order = greyMarket.getOrderInfo(orderId);

        assertEq(uint256(order.status), uint256(OrderStatus.ORDER_CANCELLED));
        assertEq(address(buyer).balance, buyerBalanceBefore + 1000000);
    }

    function testWithdrawERC20DirectOrder() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.DIRECT, address(mockERC20));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        
        vm.startPrank(buyer);
        mockERC20.approve(address(greyMarket), 1000000);  
        greyMarket.createOrder(
            orderId, 
            seller,
            address(mockERC20), 
            OrderType.DIRECT, 
            1000000, 
            Sig(v, r, s)
        );
        vm.stopPrank();

        uint256 buyerBalanceBefore = mockERC20.balanceOf(buyer);

        digest = generateWithdrawDigest(orderId);

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.withdrawOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );

        Order memory order = greyMarket.getOrderInfo(orderId);

        assertEq(uint256(order.status), uint256(OrderStatus.ORDER_CANCELLED));
        assertEq(mockERC20.balanceOf(buyer), buyerBalanceBefore + 1000000);
    }

    function testWithdrawERC20EscrowOrder() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.ESCROW, address(mockERC20));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        
        vm.startPrank(buyer);
        mockERC20.approve(address(greyMarket), 1000000);     
        greyMarket.createOrder(
            orderId, 
            seller, 
            address(mockERC20), 
            OrderType.ESCROW, 
            1000000, 
            Sig(v, r, s)
        );
        vm.stopPrank();

        uint256 buyerBalanceBefore = mockERC20.balanceOf(buyer);

        digest = generateWithdrawDigest(orderId);

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.withdrawOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );

        Order memory order = greyMarket.getOrderInfo(orderId);

        assertEq(uint256(order.status), uint256(OrderStatus.ORDER_CANCELLED));
        assertEq(mockERC20.balanceOf(buyer), buyerBalanceBefore + 1000000);
    }

    function testWithdrawDirectOrderWithInvalidSignature() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.DIRECT, address(0));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);
        
        vm.prank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(0), 
            OrderType.DIRECT, 
            1000000, 
            Sig(v, r, s)
        );

        vm.warp(1000);
        digest = generateWithdrawDigest(randomOrderID());

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        vm.expectRevert("withdrawOrder: invalid signature");
        greyMarket.withdrawOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );
    }
}
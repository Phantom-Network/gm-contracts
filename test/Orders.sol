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

    function testCreateOrderERC20TokenEscrow() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.ESCROW, address(mockERC20));

        uint256 balanceBefore = address(buyer).balance;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);
        mockERC20.approve(address(greyMarket), 1000000);     
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(mockERC20),
            OrderType.ESCROW, 
            1000000, 
            Sig(v, r, s)
        );

        Order memory order = greyMarket.getOrderInfo(orderId);
        assertEq(order.buyer, buyer);
        assertEq(order.seller, seller);
        assertEq(order.paymentToken, address(mockERC20));
        assertEq(order.amount, 1000000);
        assertEq(address(buyer).balance, balanceBefore - 1000000);
    }

    function testCreateOrderNativeTokenDirect() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.DIRECT, address(0));

        uint256 balanceBefore = address(buyer).balance;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(0), 
            OrderType.DIRECT, 
            1000000,
            Sig(v, r, s)
        );

        vm.stopPrank();

        Order memory order = greyMarket.getOrderInfo(orderId);
        assertEq(order.buyer, buyer);
        assertEq(order.seller, seller);
        assertEq(order.paymentToken, address(0));
        assertEq(order.amount, 1000000);
        assertEq(address(buyer).balance, balanceBefore - 1000000);
    }

    function testCreateOrderWrongSigner() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.DIRECT, address(0));

        vm.startPrank(buyer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        
        vm.expectRevert("createOrder: invalid signature");
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(0), 
            OrderType.ESCROW, 
            1000000, 
            Sig(v, r, s)
        );

        vm.stopPrank();
    }

    function testCreateOrderERC20Token() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.DIRECT, address(mockERC20));

        uint256 balanceBefore = mockERC20.balanceOf(buyer);
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

        assertEq(mockERC20.balanceOf(address(greyMarket)), 1000000);
        assertEq(mockERC20.balanceOf(buyer), balanceBefore - 1000000);
        vm.stopPrank();
    }

    function testCreateOrderUnsupportedOrderType() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.COUNT, address(mockERC20));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);  
        mockERC20.approve(address(greyMarket), 1000000);
        vm.expectRevert("createOrder: invalid order type");     
        greyMarket.createOrder(
            orderId, 
            seller, 
            address(mockERC20), 
            OrderType.COUNT, 
            1000000, 
            Sig(v, r, s)
        );
    }

    function testCreateOrderUnsupportedERC20Token() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, OrderType.DIRECT, address(unsupportedMockERC20));
        
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);  
        unsupportedMockERC20.approve(address(greyMarket), 1000000);
        vm.expectRevert("createOrder: invalid payment token");     
        greyMarket.createOrder(
            orderId, 
            seller, 
            address(unsupportedMockERC20), 
            OrderType.DIRECT, 
            1000000, 
            Sig(v, r, s)
        );
    }

    function testCreateCompletedOrder() public {
        bytes32 orderId = randomOrderID();
        bytes32 createDigest = generateOrderDigest(orderId, OrderType.ESCROW, address(0));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, createDigest);
        
        vm.prank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(0), 
            OrderType.ESCROW, 
            1000000, 
            Sig(v, r, s)
        );

        bytes32 claimDigest = generateOrderClaimDigest(orderId);
        (v, r, s) = vm.sign(signerPrivateKey, claimDigest);

        vm.prank(seller);
        greyMarket.claimOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );

        (v, r, s) = vm.sign(signerPrivateKey, createDigest);

        vm.prank(buyer);
        vm.expectRevert("createOrder: invalid status");
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(0), 
            OrderType.ESCROW, 
            1000000, 
            Sig(v, r, s)
        );
    }
}
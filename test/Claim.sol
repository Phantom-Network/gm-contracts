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

    function testClaimOrderEscrow() public {
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

        Order memory order = greyMarket.getOrderInfo(orderId);
        uint256 sellerBalanceBefore = address(seller).balance;

        digest = generateOrderClaimDigest(orderId);
        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(seller);
        greyMarket.claimOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );

        uint256 defaultOrderFee = order.amount * greyMarket.transactionFee() / 100000;
        uint256 escrowFee = order.amount * greyMarket.defaultEscrowFee() / 100000;
        uint256 pxnEscrowFee = escrowFee * 10 / 100;
        uint256 sellerEscrowFee = escrowFee * 90 / 100;

        assertEq(greyMarket.getAdminFeeAmount(order.paymentToken), defaultOrderFee + pxnEscrowFee);
        assertEq(address(seller).balance, sellerBalanceBefore + order.amount - defaultOrderFee + sellerEscrowFee);
        assertEq(greyMarket.escrowFees(address(seller), order.paymentToken), sellerEscrowFee);
    }

    function testClaimIfSellerIsNotSeller() public {
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

        digest = generateOrderClaimDigest(orderId);
        (v, r, s) = vm.sign(signerPrivateKey, digest);
        
        vm.prank(buyer);
        vm.expectRevert("claimOrder: invalid seller");
        greyMarket.claimOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );
    }

    function testBulkClaimDirect() public {
        bytes32[] memory orderIds = new bytes32[](2);
        orderIds[0] = randomOrderID();
        vm.warp(10000);
        orderIds[1] = randomOrderID();

        bytes32 digest = generateOrderDigest(orderIds[0], OrderType.DIRECT, address(0));
        bytes32 digest2 = generateOrderDigest(orderIds[1], OrderType.DIRECT, address(0));

        address[] memory buyers = new address[](2);
        buyers[0] = buyer;
        buyers[1] = buyer;

        address[] memory sellers = new address[](2);
        sellers[0] = seller;
        sellers[1] = seller;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderIds[0], 
            seller, 
            address(0), 
            OrderType.DIRECT, 
            1000000, 
            Sig(v, r, s)
        );

        (v, r, s) = vm.sign(signerPrivateKey, digest2);

        greyMarket.createOrder{value: 1000000}(
            orderIds[1], 
            seller, 
            address(0), 
            OrderType.DIRECT, 
            1000000, 
            Sig(v, r, s)
        );

        vm.stopPrank();

        bytes32 claimDigest = generateOrderClaimDigest(orderIds[0]);
        bytes32 claimDigest2 = generateOrderClaimDigest(orderIds[1]);

        Sig[] memory sigs = new Sig[](2);
        (v, r, s) = vm.sign(signerPrivateKey, claimDigest);
        sigs[0] = Sig(v, r, s);
        (v, r, s) = vm.sign(signerPrivateKey, claimDigest2);
        sigs[1] = Sig(v, r, s);

        vm.prank(seller);
        greyMarket.claimOrders(orderIds, buyers, sellers, sigs);
        assertEq(uint256(greyMarket.getOrderInfo(orderIds[0]).status), 5);
        assertEq(uint256(greyMarket.getOrderInfo(orderIds[1]).status), 5);

        uint256 transactionFee = 2000000 * greyMarket.transactionFee() / 100000;
        assertEq(greyMarket.getAdminFeeAmount(address(0)), transactionFee);
    }

    function testBulkClaimEscrow() public {
        bytes32[] memory orderIds = new bytes32[](2);
        orderIds[0] = randomOrderID();
        vm.warp(10000);
        orderIds[1] = randomOrderID();

        bytes32 digest = generateOrderDigest(orderIds[0], OrderType.ESCROW, address(0));
        bytes32 digest2 = generateOrderDigest(orderIds[1], OrderType.ESCROW, address(0));

        address[] memory buyers = new address[](2);
        buyers[0] = buyer;
        buyers[1] = buyer;

        address[] memory sellers = new address[](2);
        sellers[0] = seller;
        sellers[1] = seller;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        uint256 balanceBefore = address(seller).balance;

        vm.startPrank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderIds[0], 
            seller, 
            address(0), 
            OrderType.ESCROW, 
            1000000, 
            Sig(v, r, s)
        );

        (v, r, s) = vm.sign(signerPrivateKey, digest2);

        greyMarket.createOrder{value: 1000000}(
            orderIds[1], 
            seller, 
            address(0), 
            OrderType.ESCROW, 
            1000000, 
            Sig(v, r, s)
        );

        vm.stopPrank();

        bytes32 claimDigest = generateOrderClaimDigest(orderIds[0]);
        bytes32 claimDigest2 = generateOrderClaimDigest(orderIds[1]);

        Sig[] memory sigs = new Sig[](2);
        (v, r, s) = vm.sign(signerPrivateKey, claimDigest);
        sigs[0] = Sig(v, r, s);
        (v, r, s) = vm.sign(signerPrivateKey, claimDigest2);
        sigs[1] = Sig(v, r, s);

        vm.prank(seller);
        greyMarket.claimOrders(orderIds, buyers, sellers, sigs);
        assertEq(uint256(greyMarket.getOrderInfo(orderIds[0]).status), 5);
        assertEq(uint256(greyMarket.getOrderInfo(orderIds[1]).status), 5);

        uint256 transactionFee = 2000000 * greyMarket.transactionFee() / 100000;
        uint256 escrowFee = 2000000 * 2900 / 100000;
        uint256 pxnEscrowFee = escrowFee * 10 / 100;
        uint256 sellerEscrowFee = escrowFee - pxnEscrowFee;
        // 5% fee x 2 orders, plus 0.29% escrow fee, 10% for PXN x 2 orders
        assertEq(greyMarket.getAdminFeeAmount(address(0)), transactionFee + escrowFee / 10);
        // 0.29% escrow fee, 90% for seller x 2 orders, 100000 for each order, 200000 total
        assertEq(address(seller).balance, balanceBefore + 2000000 - transactionFee + sellerEscrowFee);
    }
}
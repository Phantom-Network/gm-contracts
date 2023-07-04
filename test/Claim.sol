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
        bytes32 digest = generateOrderDigest(orderId, 1, address(0));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId,
            seller,
            address(0),
            1,
            1000000,
            Sig(v, r, s)
        );

        digest = generateOrderClaimDigest(orderId, 1000000, address(0), 1);
        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(seller);
        greyMarket.claimOrder(
            orderId,
            seller,
            1000000,
            1,
            address(0),
            Sig(v, r, s)
        );
    }

    function testClaimIfSellerIsNotSeller() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, 1, address(0));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId,
            seller,
            address(0),
            1,
            1000000,
            Sig(v, r, s)
        );

        digest = generateOrderClaimDigest(orderId, 1000000, address(0), 0);
        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        vm.expectRevert();
        greyMarket.claimOrder(
            orderId,
            seller,
            1000000,
            1,
            address(0),
            Sig(v, r, s)
        );
    }

    function testBulkClaimDirect() public {
        Order[] memory orders = new Order[](2);
        for (uint256 i = 0; i < 2; i++) {
            orders[i].id = randomOrderID();
            orders[i].seller = seller;
            orders[i].amount = 1000000;
            orders[i].orderType = 0;
            orders[i].paymentToken = address(0);
            vm.warp(10000);
        }
        bytes32 digest = generateOrderDigest(orders[0].id, 0, address(0));
        bytes32 digest2 = generateOrderDigest(orders[1].id, 0, address(0));

        address[] memory sellers = new address[](2);
        sellers[0] = seller;
        sellers[1] = seller;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orders[0].id,
            seller,
            address(0),
            0,
            1000000,
            Sig(v, r, s)
        );

        (v, r, s) = vm.sign(signerPrivateKey, digest2);

        greyMarket.createOrder{value: 1000000}(
            orders[1].id,
            seller,
            address(0),
            0,
            1000000,
            Sig(v, r, s)
        );

        vm.stopPrank();

        bytes32 claimDigest = generateOrderClaimDigest(
            orders[0].id,
            1000000,
            address(0),
            0
        );
        bytes32 claimDigest2 = generateOrderClaimDigest(
            orders[1].id,
            1000000,
            address(0),
            0
        );

        Sig[] memory sigs = new Sig[](2);
        (v, r, s) = vm.sign(signerPrivateKey, claimDigest);
        sigs[0] = Sig(v, r, s);
        (v, r, s) = vm.sign(signerPrivateKey, claimDigest2);
        sigs[1] = Sig(v, r, s);

        vm.prank(seller);
        greyMarket.claimOrders(orders, sigs);
        // assertEq(uint256(greyMarket.orders(orderIds[0])), true);
        // assertTrue(uint256(greyMarket.orders(orderIds[1])), true);
        // uint256 transactionFee = (2000000 * greyMarket.transactionFee()) /100000;
        // assertEq(greyMarket.getAdminFeeAmount(address(0)), transactionFee);
    }
}

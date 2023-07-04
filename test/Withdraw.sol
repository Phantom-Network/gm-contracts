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
        bytes32 digest = generateOrderDigest(orderId, 0, address(0));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId,
            seller,
            address(0),
            0,
            1000000,
            Sig(v, r, s)
        );

        uint256 buyerBalanceBefore = address(buyer).balance;

        digest = generateWithdrawDigest(
            orderId,
            1000000,
            address(0)
        );

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.withdrawOrder(
            orderId,
            buyer,
            seller,
            address(0),
            1000000,
            Sig(v, r, s)
        );

        assertEq(address(buyer).balance, buyerBalanceBefore + 1000000);
    }

    function testWithdrawEscrowOrder() public {
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

        uint256 buyerBalanceBefore = address(buyer).balance;

        digest = generateWithdrawDigest(
            orderId,
            1000000,
            address(0)
        );

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.withdrawOrder(
            orderId,
            buyer,
            seller,
            address(0),
            1000000,
            Sig(v, r, s)
        );

        assertEq(address(buyer).balance, buyerBalanceBefore + 1000000);
    }

    function testWithdrawERC20DirectOrder() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, 0, address(mockERC20));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);
        mockERC20.approve(address(greyMarket), 1000000);
        greyMarket.createOrder(
            orderId,
            seller,
            address(mockERC20),
            0,
            1000000,
            Sig(v, r, s)
        );
        vm.stopPrank();

        uint256 buyerBalanceBefore = mockERC20.balanceOf(buyer);

        digest = generateWithdrawDigest(
            orderId,
            1000000,
            address(mockERC20)
        );

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.withdrawOrder(
            orderId,
            buyer,
            seller,
            address(mockERC20),
            1000000,
            Sig(v, r, s)
        );

        assertEq(mockERC20.balanceOf(buyer), buyerBalanceBefore + 1000000);
    }

    function testWithdrawERC20EscrowOrder() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, 1, address(mockERC20));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);
        mockERC20.approve(address(greyMarket), 1000000);
        greyMarket.createOrder(
            orderId,
            seller,
            address(mockERC20),
            1,
            1000000,
            Sig(v, r, s)
        );
        vm.stopPrank();

        uint256 buyerBalanceBefore = mockERC20.balanceOf(buyer);

        digest = generateWithdrawDigest(
            orderId,
            1000000,
            address(mockERC20)
        );

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.withdrawOrder(
            orderId,
            buyer,
            seller,
            address(mockERC20),
            1000000,
            Sig(v, r, s)
        );

        assertEq(mockERC20.balanceOf(buyer), buyerBalanceBefore + 1000000);
    }

    function testWithdrawDirectOrderWithInvalidSignature() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, 0, address(0));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId,
            seller,
            address(0),
            0,
            1000000,
            Sig(v, r, s)
        );

        vm.warp(1000);
        digest = generateWithdrawDigest(
            randomOrderID(),
            1000000,
            address(0)
        );

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        vm.expectRevert();
        greyMarket.withdrawOrder(
            orderId,
            buyer,
            seller,
            address(0),
            1000000,
            Sig(v, r, s)
        );
    }

    function testWithdrawDirectOrderReplayAttack() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, 0, address(0));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.prank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId,
            seller,
            address(0),
            0,
            1000000,
            Sig(v, r, s)
        );

        digest = generateWithdrawDigest(
            orderId,
            250000,
            address(0)
        );

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(seller);
        greyMarket.withdrawOrder(
            orderId,
            buyer,
            seller,
            address(0),
            250000,
            Sig(v, r, s)
        );
        vm.prank(seller);
        vm.expectRevert();
        greyMarket.withdrawOrder(
            orderId,
            buyer,
            seller,
            address(0),
            250000,
            Sig(v, r, s)
        );
    }
}

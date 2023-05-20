//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "forge-std/Test.sol";
import "../src/GreyMarket.sol";
import "../src/MockERC20.sol";
import "./Utils/Utilities.sol";
import "./BaseSetup.sol";

contract Settings is BaseSetup {
    function setUp() public override {
        super.setUp();
    }

    function testAddPaymentToken() public {
        vm.prank(owner);
        greyMarket.addOrRemovePaymentToken(address(mockERC20), true);
        assertEq(greyMarket.paymentTokens(address(mockERC20)), true);
    }

    function testRemovePaymentToken() public {
        vm.startPrank(owner);
        greyMarket.addOrRemovePaymentToken(address(mockERC20), true);
        greyMarket.addOrRemovePaymentToken(address(mockERC20), false);
        assertEq(greyMarket.paymentTokens(address(mockERC20)), false);
    }

    function testAddPaymentTokenNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket.addOrRemovePaymentToken(address(mockERC20), true);
    }

    function testSetTransactionFee() public {
        vm.prank(owner);
        greyMarket.setTransactionFee(1000);
        assertEq(greyMarket.transactionFee(), 1000);
    }

    function testSetTransactionFeeOutOfRange() public {
        vm.prank(owner);
        vm.expectRevert("invalid fee range");
        greyMarket.setTransactionFee(100000);
    }

    function testSetTransactionFeeNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket.setTransactionFee(0);
    }

    function testSetEscrowFee() public {
        vm.prank(owner);
        greyMarket.setEscrowFee(1000);
        assertEq(greyMarket.defaultEscrowFee(), 1000);
    }

    function testSetEscrowFeeOutOfRange() public {
        vm.prank(owner);
        vm.expectRevert("invalid fee range");
        greyMarket.setEscrowFee(100000);
    }

    function testSetEscrowFeeNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket.setEscrowFee(0);
    }

    function testSetEscrowPendingPeriod() public {
        vm.prank(owner);
        greyMarket.setEscrowPendingPeriod(10 days);
        assertEq(greyMarket.escrowPendingPeriod(), 10 days);
    }

    function testSetEscrowPendingPeriodOutOfRangeMax() public {
        vm.prank(owner);
        vm.expectRevert("pending period must not exceed maximum period");
        greyMarket.setEscrowPendingPeriod(100000 days);
    }

    function testSetEscrowPendingPeriodOutOfRangeMin() public {
        vm.prank(owner);
        vm.expectRevert("pending period must exceed minimum period");
        greyMarket.setEscrowPendingPeriod(0 days);
    }

    function testSetEscrowPendingPeriodNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket.setEscrowPendingPeriod(0 days);
    }

    function testSetEscrowLockPeriod() public {
        vm.prank(owner);
        greyMarket.setEscrowLockPeriod(10 * 30 days);
        assertEq(greyMarket.escrowLockPeriod(), 10 * 30 days);
    }

    function testSetEscrowLockPeriodOutOfRangeMax() public {
        vm.prank(owner);
        vm.expectRevert("lock period must not exceed maximum period");
        greyMarket.setEscrowLockPeriod(100000 days);
    }

    function testSetEscrowLockPeriodOutOfRangeMin() public {
        vm.prank(owner);
        vm.expectRevert("lock period must exceed minimum period");
        greyMarket.setEscrowLockPeriod(0 days);
    }

    function testSetEscrowLockPeriodNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket.setEscrowLockPeriod(0 days);
    }

    function testWithdrawLockedFundNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket.withdrawLockedFunds(
            randomOrderID(), 
            owner,
            0,
            block.timestamp,
            0,
            address(0)
        );
    }

    function testWithdrawAdminFeeNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket.withdrawAdminFee(owner, address(0), 1000000);
    }

    function testWithdrawAdminFee() public {
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

        digest = generateOrderClaimDigest(orderId, 1000000, address(0), 0);
        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(seller);
        greyMarket.claimOrder(
            orderId, 
            buyer, 
            seller,
            1000000,
            0,
            address(0),
            Sig(v, r, s)
        );

        uint256 previousBalance = address(owner).balance;

        vm.startPrank(owner);
        greyMarket.withdrawAdminFee(owner, address(0), 1000000 * greyMarket.transactionFee() / 100000);
        assertEq(address(owner).balance, previousBalance + 1000000 * greyMarket.transactionFee() / 100000);
    }

    function testWithdrawAdminFeeERC20() public {
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

        digest = generateOrderClaimDigest(orderId, 1000000, address(mockERC20), 1);
        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(seller);
        greyMarket.claimOrder(
            orderId, 
            buyer, 
            seller,
            1000000,
            1,
            address(mockERC20),
            Sig(v, r, s)
        );

        uint256 previousBalance = mockERC20.balanceOf(address(owner));

        vm.startPrank(owner);
        greyMarket.withdrawAdminFee(owner, address(mockERC20), 1000000 * greyMarket.transactionFee() / 100000);
        assertEq(mockERC20.balanceOf(address(owner)), previousBalance + 1000000 * greyMarket.transactionFee() / 100000);
    }
}
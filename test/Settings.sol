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
        greyMarket._addOrRemovePaymentToken(address(mockERC20), true);
        assertEq(greyMarket.paymentTokens(address(mockERC20)), true);
    }

    function testRemovePaymentToken() public {
        vm.startPrank(owner);
        greyMarket._addOrRemovePaymentToken(address(mockERC20), true);
        greyMarket._addOrRemovePaymentToken(address(mockERC20), false);
        assertEq(greyMarket.paymentTokens(address(mockERC20)), false);
    }

    function testAddPaymentTokenNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket._addOrRemovePaymentToken(address(mockERC20), true);
    }

    function testSetTransactionFee() public {
        vm.prank(owner);
        greyMarket._setTransactionFee(1000);
        assertEq(greyMarket.transactionFee(), 1000);
    }

    function testSetTransactionFeeOutOfRange() public {
        vm.prank(owner);
        vm.expectRevert("invalid fee range");
        greyMarket._setTransactionFee(100000);
    }

    function testSetTransactionFeeNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket._setTransactionFee(0);
    }

    function testSetEscrowFee() public {
        vm.prank(owner);
        greyMarket._setEscrowFee(1000);
        assertEq(greyMarket.defaultEscrowFee(), 1000);
    }

    function testSetEscrowFeeOutOfRange() public {
        vm.prank(owner);
        vm.expectRevert("invalid fee range");
        greyMarket._setEscrowFee(100000);
    }

    function testSetEscrowFeeNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket._setEscrowFee(0);
    }

    function testSetEscrowPendingPeriod() public {
        vm.prank(owner);
        greyMarket._setEscrowPendingPeriod(10 days);
        assertEq(greyMarket.escrowPendingPeriod(), 10 days);
    }

    function testSetEscrowPendingPeriodOutOfRangeMax() public {
        vm.prank(owner);
        vm.expectRevert("pending period must not exceed maximum period");
        greyMarket._setEscrowPendingPeriod(100000 days);
    }

    function testSetEscrowPendingPeriodOutOfRangeMin() public {
        vm.prank(owner);
        vm.expectRevert("pending period must exceed minimum period");
        greyMarket._setEscrowPendingPeriod(0 days);
    }

    function testSetEscrowPendingPeriodNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket._setEscrowPendingPeriod(0 days);
    }

    function testSetEscrowLockPeriod() public {
        vm.prank(owner);
        greyMarket._setEscrowLockPeriod(10 * 30 days);
        assertEq(greyMarket.escrowLockPeriod(), 10 * 30 days);
    }

    function testSetEscrowLockPeriodOutOfRangeMax() public {
        vm.prank(owner);
        vm.expectRevert("lock period must not exceed maximum period");
        greyMarket._setEscrowLockPeriod(100000 days);
    }

    function testSetEscrowLockPeriodOutOfRangeMin() public {
        vm.prank(owner);
        vm.expectRevert("lock period must exceed minimum period");
        greyMarket._setEscrowLockPeriod(0 days);
    }

    function testSetEscrowLockPeriodNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket._setEscrowLockPeriod(0 days);
    }

    function testWithdrawLockedFundNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket._withdrawLockedFund(randomOrderID(), owner);
    }

    function testWithdrawAdminFeeNotOwner() public {
        vm.expectRevert("Ownable: caller is not the owner");
        greyMarket._withdrawAdminFee(owner, address(0), 1000000);
    }

    function testWithdrawAdminFee() public {
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

        digest = generateOrderClaimDigest(orderId);
        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(seller);
        greyMarket.claimOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );

        uint256 previousBalance = address(owner).balance;

        vm.startPrank(owner);
        greyMarket._withdrawAdminFee(owner, address(0), 1000000 * greyMarket.transactionFee() / 100000);
        assertEq(address(owner).balance, previousBalance + 1000000 * greyMarket.transactionFee() / 100000);
    }

    function testWithdrawAdminFeeERC20() public {
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

        digest = generateOrderClaimDigest(orderId);
        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(seller);
        greyMarket.claimOrder(
            orderId, 
            buyer, 
            seller, 
            Sig(v, r, s)
        );

        uint256 previousBalance = mockERC20.balanceOf(address(owner));

        vm.startPrank(owner);
        greyMarket._withdrawAdminFee(owner, address(mockERC20), 1000000 * greyMarket.transactionFee() / 100000);
        assertEq(mockERC20.balanceOf(address(owner)), previousBalance + 1000000 * greyMarket.transactionFee() / 100000);
    }
}
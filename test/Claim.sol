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

        uint256 sellerBalanceBefore = address(seller).balance;
        digest = generateOrderClaimDigest(orderId, 1000000, address(0), 1, greyMarket.usedNonces(seller));
        (v, r, s) = vm.sign(signerPrivateKey, digest);

        vm.prank(seller);
        greyMarket.claimOrder(
            orderId, 
            buyer, 
            seller,
            1000000,
            1,
            address(0), 
            Sig(v, r, s)
        );

        uint256 defaultOrderFee = 1000000 * greyMarket.transactionFee() / 100000;
        uint256 escrowFee = 1000000 * greyMarket.defaultEscrowFee() / 100000;
        uint256 sellerEscrowFee = escrowFee * 90 / 100;
        assertEq(address(seller).balance, sellerBalanceBefore + 1000000 - defaultOrderFee + sellerEscrowFee);
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

        digest = generateOrderClaimDigest(orderId, 100000, address(0), 1,greyMarket.usedNonces(seller));
        (v, r, s) = vm.sign(signerPrivateKey, digest);
        
        vm.prank(buyer);
        vm.expectRevert();
        greyMarket.claimOrder(
            orderId, 
            buyer, 
            seller,
            1000000,
            1,
            address(0),
            Sig(v, r, s)
        );
    }
}
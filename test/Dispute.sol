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

    /*function testReleaseDisputedOrderBuyerWins() public {
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

        uint256 winnerBalanceBefore = address(buyer).balance;

        address[] calldata admins = new address[](2);
        admins[0] = address(signer);
        admins[1] = address(signer2);
        greyMarket._setNewAdmins(admins);

        digest = generateDisputeDigest(orderId);

        (v, r, s) = vm.sign(signerPrivateKey, digest);

        Sig[] calldata sigs = new Sig[](2);
        sigs[0] = Sig(v, r, s);
        (v, r, s) = vm.sign(signerPrivateKey2, digest);
        sigs[1] = Sig(v, r, s);

        vm.prank(buyer);
        greyMarket.releaseDisputedOrder(
            orderId,
            buyer,
            seller,
            buyer,
            sigs
        );

        Order memory order = greyMarket.getOrderInfo(orderId);
        assertEq(uint256(order.status), uint256(OrderStatus.ORDER_DISPUTE_HANDLED));
        assertEq(address(buyer).balance, winnerBalanceBefore + 1000000);
    }*/
}
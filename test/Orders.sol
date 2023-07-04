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
        bytes32 digest = generateOrderDigest(orderId, 0, address(mockERC20));

        uint256 balanceBefore = address(buyer).balance;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);
        mockERC20.approve(address(greyMarket), 1000000);     
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(mockERC20),
            0, 
            1000000, 
            Sig(v, r, s)
        );

        assertEq(address(buyer).balance, balanceBefore - 1000000);
    }

    function testCreateOrderNativeTokenDirect() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, 1, address(0));

        uint256 balanceBefore = address(buyer).balance;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digest);

        vm.startPrank(buyer);
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(0), 
            1, 
            1000000,
            Sig(v, r, s)
        );

        vm.stopPrank();
        assertEq(address(buyer).balance, balanceBefore - 1000000);
    }

    function testCreateOrderWrongSigner() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, 0, address(0));

        vm.startPrank(buyer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(1, digest);
        
        vm.expectRevert();
        greyMarket.createOrder{value: 1000000}(
            orderId, 
            seller, 
            address(0), 
            1, 
            1000000, 
            Sig(v, r, s)
        );

        vm.stopPrank();
    }

    function testCreateOrderERC20Token() public {
        bytes32 orderId = randomOrderID();
        bytes32 digest = generateOrderDigest(orderId, 1, address(mockERC20));

        uint256 balanceBefore = mockERC20.balanceOf(buyer);
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

        assertEq(mockERC20.balanceOf(address(greyMarket)), 1000000);
        assertEq(mockERC20.balanceOf(buyer), balanceBefore - 1000000);
        vm.stopPrank();
    }
}
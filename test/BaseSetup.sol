//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "forge-std/Test.sol";
import "../src/GreyMarket.sol";
import "../src/MockERC20.sol";
import "./Utils/Utilities.sol";

contract BaseSetup is Test {
    Utilities internal utils;
    MockERC20 internal mockERC20;
    GreyMarket internal greyMarket;

    address payable[] internal users;
    address internal owner;
    uint256 internal buyerPrivateKey;
    address internal buyer;
    uint256 internal sellerPrivateKey;
    address internal seller;
    address internal signer;
    address internal nativeEthPaymentToken = 0x0000000000000000000000000000000000000000;
    uint256 internal testAmount = 10000000000000000;
        

    function setUp() public virtual {
        // generate fake users
        utils = new Utilities();
        users = utils.createUsers(2);
        owner = users[0];
        signer = users[1];

        buyerPrivateKey = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        buyer = vm.addr(buyerPrivateKey);

        sellerPrivateKey = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        seller = vm.addr(sellerPrivateKey);

        mockERC20 = new MockERC20(buyer);

        vm.startPrank(owner);
        greyMarket = new GreyMarket(address(mockERC20));
        greyMarket.initialize(buyer);
        vm.stopPrank();

        vm.deal(buyer, 100 ether);
    }

    /*function hash(bytes32 memory data) public view returns(bytes32) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                greyMarket.domainSeperator,
                keccak256(data)
            )
        );
    }*/

    function randomOrderID() public view returns (bytes32) {
        return keccak256(abi.encodePacked(block.timestamp, block.difficulty));
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "forge-std/Vm.sol";
import "../src/GreyMarket.sol";
import "../src/GreyMarketProxy.sol";

contract Deploy is Script {
    address deployer;

     function run() external {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        vm.startBroadcast(deployer);

        GreyMarket gm = new GreyMarket();
        console.log("Grey Market contract deployed at address: ", address(gm));

        
        GreyMarketProxy proxy = new GreyMarketProxy(
            address(gm), 
            deployer,
            abi.encodeWithSignature("initialize(address,address)", 
            address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48),
            vm.envAddress("PROOF_SIGNER"))
        );

        console.log("Grey Market Proxy contract deployed at address: ", address(proxy));
        vm.stopBroadcast();
    }
}

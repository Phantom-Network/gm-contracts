// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "forge-std/Vm.sol";
import "../src/GreyMarket.sol";
import "../src/MockERC20.sol";

contract Deploy is Script {
    address deployer;

     function run() external {
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        vm.startBroadcast(deployer);

        GreyMarket gm = new GreyMarket(vm.envAddress("PROOF_SIGNER"));
        console.log("Grey Market contract deployed at address: ", address(gm));
        
        vm.stopBroadcast();
    }
}

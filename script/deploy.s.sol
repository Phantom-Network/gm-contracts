// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import "forge-std/Vm.sol";
import "../src/GreyMarket.sol";
import "../src/GreyMarketProxy.sol";
import "../src/MockERC20.sol";

contract Deploy is Script {
    address deployer;

     function run() external {
        console.log("Deploying Mock USDC Contract");
        deployer = vm.envAddress("DEPLOYER_ADDRESS");
        vm.startBroadcast(deployer);

        //MockERC20 usdc = new MockERC20(deployer);
        //console.log("USDC contract deployed at address: ", address(usdc));

        GreyMarket gm = new GreyMarket(address(0x7D7DFd9686B0eCc19ee5FF3D9FD5c08e1C870076));
        console.log("Grey Market contract deployed at address: ", address(gm));

        /*GreyMarketProxy proxy = new GreyMarketProxy(
            address(gm), 
            deployer,
            abi.encodeWithSignature("initialize(address)", vm.envAddress("PROOF_SIGNER"))
        );

        console.log("Grey Market Proxy contract deployed at address: ", address(proxy));*/
        vm.stopBroadcast();
    }
}
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {VaultManager} from "../src/VaultManager.sol";

contract DeployScript is Script {
    VaultManager public vaultManager;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        vaultManager = new VaultManager();
        
        console2.log("VaultManager deployed to:", address(vaultManager));
        console2.log("Deployer address:", vm.addr(deployerPrivateKey));

        vm.stopBroadcast();
    }
}

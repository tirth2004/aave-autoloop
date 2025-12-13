// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {AutoLooper} from "../src/aave/AutoLooper.sol";

contract DeployAutoLooperSepolia is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        console.log("Deploying AutoLooper to Sepolia...");
        console.log("Deployer address:", vm.addr(deployerPrivateKey));

        vm.startBroadcast(deployerPrivateKey);

        AutoLooper looper = new AutoLooper();

        console.log("AutoLooper deployed at:", address(looper));

        vm.stopBroadcast();
    }
}

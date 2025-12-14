// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {AutoLooperHelper} from "../src/aave/AutoLooperHelper.sol";
import {AutoLooper} from "../src/aave/AutoLooper.sol";

contract DeployAutoLooperHelper is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying AutoLooperHelper to Sepolia...");
        console.log("Deployer address:", deployer);

        address autoLooperAddress = vm.envOr("AUTOLOOPER_ADDRESS", address(0));

        address owner = vm.envOr("OWNER_ADDRESS", deployer);
        address recipient = vm.envOr("RECIPIENT_ADDRESS", deployer);

        vm.startBroadcast(deployerPrivateKey);

        AutoLooper autoLooper;
        if (autoLooperAddress == address(0)) {
            console.log(
                "AutoLooper address not provided, deploying new one..."
            );
            autoLooper = new AutoLooper();
            autoLooperAddress = address(autoLooper);
            console.log("AutoLooper deployed at:", autoLooperAddress);
        } else {
            console.log("Using existing AutoLooper at:", autoLooperAddress);
            autoLooper = AutoLooper(autoLooperAddress);
        }

        AutoLooperHelper helper = new AutoLooperHelper(
            autoLooperAddress,
            owner,
            recipient
        );

        console.log("\n=== Deployment Successful ===");
        console.log("AutoLooperHelper deployed at:", address(helper));
        console.log("AutoLooper address:", autoLooperAddress);
        console.log("Owner:", owner);
        console.log("Recipient:", recipient);
        console.log("\n=== Next Steps ===");
        console.log("1. Set HELPER_CONTRACT env var to:", address(helper));
        console.log("2. Set AUTOLOOPER_ADDRESS env var to:", autoLooperAddress);
        console.log("3. Approve WETH to helper contract for opening positions");
        console.log(
            "4. Approve USDC to helper contract for unwinding positions"
        );
        console.log("5. Deploy AutoLooperReactive contract");

        vm.stopBroadcast();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import {AutoLooperReactive} from "../src/reactive/AutoLooperReactive.sol";
import {AutoLooper} from "../src/aave/AutoLooper.sol";

contract DeployAutoLooperReactive is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying AutoLooperReactive to Reactive Network...");
        console.log("Deployer address:", deployer);

        uint256 originChainId = vm.envOr("ORIGIN_CHAIN_ID", uint256(11155111)); // Default: Sepolia
        address originFeed = vm.envAddress("ORIGIN_FEED");

        uint256 destinationChainId = vm.envOr(
            "DESTINATION_CHAIN_ID",
            uint256(11155111)
        );

        address helperContract = vm.envAddress("HELPER_CONTRACT");

        address autoLooper = vm.envAddress("AUTOLOOPER_ADDRESS");

        address owner = vm.envOr("OWNER_ADDRESS", deployer);
        address recipient = vm.envOr("RECIPIENT_ADDRESS", deployer);

        AutoLooper.OpenParams memory openParams = AutoLooper.OpenParams({
            initialCollateralWeth: vm.envOr(
                "INITIAL_COLLATERAL_WETH",
                uint256(0.01 ether)
            ),
            loops: uint8(vm.envOr("LOOPS", uint256(2))),
            borrowBps: uint16(vm.envOr("BORROW_BPS", uint256(7000))), // 70%
            minHealthFactor: vm.envOr("MIN_HEALTH_FACTOR", uint256(1.3e18)), // 1.3
            minSwapOut: vm.envOr("MIN_SWAP_OUT", uint256(0))
        });

        console.log("\n=== Configuration ===");
        console.log("Origin Chain ID:", originChainId);
        console.log("Origin Feed:", originFeed);
        console.log("Destination Chain ID:", destinationChainId);
        console.log("Helper Contract:", helperContract);
        console.log("AutoLooper:", autoLooper);
        console.log("Owner:", owner);
        console.log("Recipient:", recipient);
        console.log("\n=== Open Params ===");
        console.log(
            "Initial Collateral WETH:",
            openParams.initialCollateralWeth
        );
        console.log("Loops:", openParams.loops);
        console.log("Borrow BPS:", openParams.borrowBps);
        console.log("Min Health Factor:", openParams.minHealthFactor);
        console.log("Min Swap Out:", openParams.minSwapOut);

        require(originFeed != address(0), "ORIGIN_FEED not set");
        require(helperContract != address(0), "HELPER_CONTRACT not set");
        require(autoLooper != address(0), "AUTOLOOPER_ADDRESS not set");

        vm.startBroadcast(deployerPrivateKey);

        AutoLooperReactive reactive = new AutoLooperReactive(
            originFeed,
            originChainId,
            destinationChainId,
            helperContract,
            autoLooper,
            owner,
            recipient,
            openParams
        );

        console.log("\n=== Deployment Successful ===");
        console.log("AutoLooperReactive deployed at:", address(reactive));
        console.log("\n=== Next Steps ===");
        console.log(
            "1. Ensure owner has approved WETH and USDC to helper contract"
        );
        console.log("2. Monitor Reactive Network for price feed updates");
        console.log(
            "3. Position will open automatically on first price update"
        );

        vm.stopBroadcast();
    }
}

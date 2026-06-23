// SPDX-License-Identifier: SEE LICENSE IN LICENSE
// script/DeployDcentraclMart.s.sol
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {DcentraclMart} from "../src/DcentraclMart.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeployDcentraclMart is Script {
    function run() external returns (DcentraclMart, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);

        vm.startBroadcast(config.account);

        DcentraclMart dcentraclMart = new DcentraclMart(config.platformFeePercent);

        vm.stopBroadcast();

        console.log("DcentraclMart deployed at:", address(dcentraclMart));
        console.log("Platform fee (bps):", config.platformFeePercent);

        return (dcentraclMart, helperConfig);
    }
}

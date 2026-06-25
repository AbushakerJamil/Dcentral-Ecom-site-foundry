// SPDX-License-Identifier: SEE LICENSE IN LICENSE
// script/HelperConfig.s.sol
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__InvalidChainId();

    struct NetworkConfig {
        uint256 platformFeePercent;
        address account;
    }

    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    uint256 public constant ETH_MAINNET_CHAIN_ID = 1;
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;

    NetworkConfig public activeNetworkConfig;

    mapping(uint256 => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_MAINNET_CHAIN_ID] = getMainnetConfig();
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaConfig();
        activeNetworkConfig = getConfigByChainId(block.chainid);
    }

    function getConfigByChainId(uint256 chainId) public view returns (NetworkConfig memory) {
        if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilConfig();
        } else if (networkConfigs[chainId].account != address(0)) {
            return networkConfigs[chainId];
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({platformFeePercent: 250, account: msg.sender});
    }

    function getSepoliaConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({platformFeePercent: 250, account: msg.sender});
    }

    function getOrCreateAnvilConfig() public view returns (NetworkConfig memory) {
        if (activeNetworkConfig.account != address(0)) {
            return activeNetworkConfig;
        }

        NetworkConfig memory anvilConfig =
            NetworkConfig({platformFeePercent: 250, account: vm.addr(DEFAULT_ANVIL_PRIVATE_KEY)});

        return anvilConfig;
    }
}

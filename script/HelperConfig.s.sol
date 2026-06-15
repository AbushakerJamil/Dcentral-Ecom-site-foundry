// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.19;

// import {Script, console2} from "forge-std/Script.sol";

// abstract contract CodeConstants {
//     /*//////////////////////////////////////////////////////////////
//                                CHAIN IDS
//     //////////////////////////////////////////////////////////////*/
//     uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
//     uint256 public constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
//     uint256 public constant LOCAL_CHAIN_ID = 31337;
// }

// contract HelperConfig is CodeConstants, Script {
//     /*//////////////////////////////////////////////////////////////
//                                  ERRORS
//     //////////////////////////////////////////////////////////////*/
//     error HelperConfig__InvalidChainId();

//     /*//////////////////////////////////////////////////////////////
//                                  TYPES
//     //////////////////////////////////////////////////////////////*/
//     struct NetworkConfig {
//     }

//     /*//////////////////////////////////////////////////////////////
//                             STATE VARIABLES
//     //////////////////////////////////////////////////////////////*/
//     // Local network state variables
//     NetworkConfig public localNetworkConfig;
//     mapping(uint256 chainId => NetworkConfig) public networkConfigs;

//     /*//////////////////////////////////////////////////////////////
//                                FUNCTIONS
//     //////////////////////////////////////////////////////////////*/
//     constructor() {
//         networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
//         networkConfigs[ZKSYNC_SEPOLIA_CHAIN_ID] = getZkSyncSepoliaConfig();
//         // Note: We skip doing the local config
//     }

//     function getConfigByChainId(uint256 chainId) public returns (NetworkConfig memory) {

//     }

//     /*//////////////////////////////////////////////////////////////
//                                 CONFIGS
//     //////////////////////////////////////////////////////////////*/
//     function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {

//     }

//     function getZkSyncSepoliaConfig() public pure returns (NetworkConfig memory) {

//     }

//     /*//////////////////////////////////////////////////////////////
//                               LOCAL CONFIG
//     //////////////////////////////////////////////////////////////*/
//     function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory) {
//         // Check to see if we set an active network config

//     }
// }

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DcentraclMart} from "../src/DcentralMart_ecom.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployDcentraclMart} from "../script/DeployDSCMart.s.sol";

contract DeploymentTest is Test {
    DcentraclMart DCMart;
    DeployDcentraclMart deployer;
    HelperConfig helperConfig;
    address OWNER = makeAddr("owner");

    address SELLER = makeAddr("seller");
    address BUYER = makeAddr("buyer");
    address STRANGER = makeAddr("stranger");

    function setUp() external {
        deployer = new DeployDcentraclMart();
        (DCMart, helperConfig) = deployer.run();
        vm.deal(SELLER, 100 ether);
        vm.deal(BUYER, 100 ether);
        vm.deal(STRANGER, 100 ether);
    }

    function test_PlatformFeeSetCorrectly() public view {
        assertEq(DCMart.platformFeePercent(), 250);
    }

    function test_ProductIdCounterStartsAtZero() public view {
        assertEq(DCMart.productIdCounter(), 0);
    }

    function test_OwnerSetCorrectly() public view {
        HelperConfig.NetworkConfig memory config = helperConfig.getConfigByChainId(block.chainid);
        assertEq(DCMart.owner(), config.account);
    }

    function test_OrderIdCounterStarts__Zero() public view {
        assertEq(DCMart.getTotalOrders(), 0);
    }

    function test_PlatformEarningsStarts__Zero() public view {
        assertEq(DCMart.platformErnings(), 0);
    }

    // RegisterSellerTest

    function testRegisterSeller__Fun() public {
        vm.prank(SELLER);
        DCMart.registerSeller("My Shope", "BOOK");
        uint256[] memory products = DCMart.getSellerProductIds(SELLER);

        assertEq(products.length, 0);
    }

    function testIsRegisterSeller__AlradySeller() public {
        vm.startPrank(SELLER);
        DCMart.registerSeller("Shope", "BOOK");

        vm.expectRevert(DcentraclMart.AlreadySeller.selector);
        // vm.prank(SELLER);
        DCMart.registerSeller("Shope", "BOOK");
        vm.stopPrank();
    }

    function test_RegisterSeller_Revert_EmptyShopName() public {
        vm.expectRevert(DcentraclMart.InvalidShopName.selector);
        vm.prank(SELLER);
        DCMart.registerSeller("", "shop");
    }
}

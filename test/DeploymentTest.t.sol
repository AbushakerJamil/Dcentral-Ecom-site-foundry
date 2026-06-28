// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {DcentraclMart} from "../src/DcentralMart_ecom.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {DeployDcentraclMart} from "../script/DeployDSCMart.s.sol";

contract DcentraclMartTest is Test {
    DcentraclMart mart;

    address owner;
    address seller = makeAddr("seller");
    address buyer = makeAddr("buyer");
    address stranger = makeAddr("stranger");

    uint256 constant PLATFORM_FEE = 250;
    uint256 constant PRODUCT_PRICE = 1 ether;
    uint256 constant PRODUCT_QTY = 10;

    // ─────────────────────────────────────────
    // Events
    // ─────────────────────────────────────────
    event SellerRegistered(address indexed seller, string shopName, uint256 timestamp);
    event ProductListed(
        uint256 indexed productId, address indexed seller, string name, uint256 price, uint256 quantity
    );
    event ProductUpdated(uint256 indexed productId, uint256 price, uint256 quantity, bool isActive);
    event OrderPlaced(
        uint256 indexed orderId,
        uint256 indexed productId,
        address indexed buyer,
        address seller,
        uint256 quantity,
        uint256 totalPrice
    );
    event OrderStatusChanged(
        uint256 indexed orderId,
        DcentraclMart.OrderStatus oldStatus,
        DcentraclMart.OrderStatus newStatus,
        uint256 timestamp
    );
    event DeliveryConfirmed(uint256 indexed orderId, address indexed buyer, uint256 timestamp);
    event EarningsWithdrawn(address indexed seller, uint256 amount, uint256 timestamp);
    event RefundRequest(uint256 indexed orderId, address indexed buyer, string reason, uint256 timestamp);
    event DisputeRaised(uint256 indexed orderId, address indexed complaint, string description, uint256 timestamp);

    function setUp() public {
        DeployDcentraclMart deployer = new DeployDcentraclMart();
        (mart,) = deployer.run();
        owner = mart.owner();

        vm.deal(buyer, 100 ether);
        vm.deal(stranger, 100 ether);
    }

    // ─────────────────────────────────────────
    // Helper functions
    // ─────────────────────────────────────────
    function _registerSeller() internal {
        vm.prank(seller);
        mart.registerSeller("My Shop", "Best shop");
    }

    function _listProduct() internal returns (uint256 productId) {
        vm.prank(seller);
        productId = mart.listProduct("Phone", "Nice phone", "Electronics", PRODUCT_PRICE, PRODUCT_QTY);
    }

    function _purchaseProduct(uint256 productId, uint256 qty) internal returns (uint256 orderId) {
        vm.prank(buyer);
        orderId = mart.purchaseProduct{value: PRODUCT_PRICE * qty}(productId, qty);
    }

    function _shipOrder(uint256 orderId) internal {
        vm.prank(seller);
        mart.markAsShipped(orderId);
    }

    function _confirmDelivery(uint256 orderId) internal {
        vm.prank(buyer);
        mart.confirmDelivery(orderId);
    }

    // ═════════════════════════════════════════
    // 1. DEPLOYMENT TESTS
    // ═════════════════════════════════════════

    function test_Deploy_PlatformFeeSetCorrectly() public view {
        assertEq(mart.platformFeePercent(), PLATFORM_FEE);
    }

    function test_Deploy_OwnerSetCorrectly() public view {
        assertEq(mart.owner(), owner);
    }

    function test_Deploy_ProductCounterStartsAtZero() public view {
        assertEq(mart.getTotalProducts(), 0);
    }

    function test_Deploy_OrderCounterStartsAtZero() public view {
        assertEq(mart.getTotalOrders(), 0);
    }

    function test_Deploy_PlatformEarningsStartsAtZero() public view {
        assertEq(mart.platformErnings(), 0);
    }

    // ═════════════════════════════════════════
    // 2. REGISTER SELLER TESTS
    // ═════════════════════════════════════════

    function test_RegisterSeller_Success() public {
        vm.prank(seller);
        // mart.registerSeller("My Shop", "Best shop");

        uint256[] memory products = mart.getSellerProductIds(seller);
        assertEq(products.length, 0);
    }

    function test_RegisterSeller_EmitEvent() public {
        vm.expectEmit(true, false, false, true);
        emit SellerRegistered(seller, "My Shop", block.timestamp);

        vm.prank(seller);
        mart.registerSeller("My Shop", "Best shop");
    }

    function test_RegisterSeller_Revert_AlreadySeller() public {
        _registerSeller();

        vm.expectRevert(DcentraclMart.AlreadySeller.selector);
        vm.prank(seller);
        mart.registerSeller("My Shop", "Best shop");
    }

    function test_RegisterSeller_Revert_EmptyShopName() public {
        vm.expectRevert(DcentraclMart.InvalidShopName.selector);
        vm.prank(seller);
        mart.registerSeller("", "Best shop");
    }

    function test_RegisterSeller_Revert_EmptyDescription() public {
        vm.expectRevert(DcentraclMart.InvalidShopDescription.selector);
        vm.prank(seller);
        mart.registerSeller("My Shop", "");
    }

    // ═════════════════════════════════════════
    // 3. LIST PRODUCT TESTS
    // ═════════════════════════════════════════

    function test_ListProduct_Success() public {
        _registerSeller();
        uint256 productId = _listProduct();

        assertEq(productId, 1);
        assertEq(mart.getTotalProducts(), 1);
    }

    function test_ListProduct_SellerProductMappingUpdated() public {
        _registerSeller();
        _listProduct();

        uint256[] memory products = mart.getSellerProductIds(seller);
        assertEq(products.length, 1);
        assertEq(products[0], 1);
    }

    function test_ListProduct_EmitEvent() public {
        _registerSeller();

        vm.expectEmit(true, true, false, true);
        emit ProductListed(1, seller, "Phone", PRODUCT_PRICE, PRODUCT_QTY);

        vm.prank(seller);
        mart.listProduct("Phone", "Nice phone", "Electronics", PRODUCT_PRICE, PRODUCT_QTY);
    }

    function test_ListProduct_Revert_NotSeller() public {
        vm.expectRevert(DcentraclMart.NotASeller.selector);
        vm.prank(stranger);
        mart.listProduct("Phone", "Nice phone", "Electronics", PRODUCT_PRICE, PRODUCT_QTY);
    }

    function test_ListProduct_Revert_EmptyName() public {
        _registerSeller();

        vm.expectRevert(DcentraclMart.InvalidProductName.selector);
        vm.prank(seller);
        mart.listProduct("", "Nice phone", "Electronics", PRODUCT_PRICE, PRODUCT_QTY);
    }

    function test_ListProduct_Revert_ZeroPrice() public {
        _registerSeller();

        vm.expectRevert(DcentraclMart.InvalidPrice.selector);
        vm.prank(seller);
        mart.listProduct("Phone", "Nice phone", "Electronics", 0, PRODUCT_QTY);
    }

    function test_ListProduct_Revert_ZeroQuantity() public {
        _registerSeller();

        vm.expectRevert(DcentraclMart.InvalidQuantity.selector);
        vm.prank(seller);
        mart.listProduct("Phone", "Nice phone", "Electronics", PRODUCT_PRICE, 0);
    }

    // ═════════════════════════════════════════
    // 4. UPDATE PRODUCT TESTS
    // ═════════════════════════════════════════

    function test_UpdateProduct_Success() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.prank(seller);
        mart.updateProduct(productId, 2 ether, 5, true);
    }

    function test_UpdateProduct_EmitEvent() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.expectEmit(true, false, false, true);
        emit ProductUpdated(productId, 2 ether, 5, true);

        vm.prank(seller);
        mart.updateProduct(productId, 2 ether, 5, true);
    }

    function test_UpdateProduct_Revert_ProductNotFound() public {
        _registerSeller();

        vm.expectRevert(DcentraclMart.ProductNotFound.selector);
        vm.prank(seller);
        mart.updateProduct(99, PRODUCT_PRICE, PRODUCT_QTY, true);
    }

    function test_UpdateProduct_Revert_NotProductOwner() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.prank(stranger);
        mart.registerSeller("Stranger Shop", "Another shop");

        vm.expectRevert(DcentraclMart.NotProductOwner.selector);
        vm.prank(stranger);
        mart.updateProduct(productId, 2 ether, 5, true);
    }

    function test_UpdateProduct_Revert_ZeroPrice() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.expectRevert(DcentraclMart.InvalidPrice.selector);
        vm.prank(seller);
        mart.updateProduct(productId, 0, PRODUCT_QTY, true);
    }

    function test_UpdateProduct_SetInactive() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.prank(seller);
        mart.updateProduct(productId, PRODUCT_PRICE, PRODUCT_QTY, false);

        // inactive product kinte gele revert hobe
        vm.expectRevert(DcentraclMart.ProductNotActive.selector);
        vm.prank(buyer);
        mart.purchaseProduct{value: PRODUCT_PRICE}(productId, 1);
    }

    // ═════════════════════════════════════════
    // 5. PURCHASE PRODUCT TESTS
    // ═════════════════════════════════════════

    function test_PurchaseProduct_Success() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);

        assertEq(orderId, 1);
        assertEq(mart.getTotalOrders(), 1);
    }

    function test_PurchaseProduct_StockDeducted() public {
        _registerSeller();
        uint256 productId = _listProduct();
        _purchaseProduct(productId, 3);

        vm.prank(buyer);
        mart.purchaseProduct{value: PRODUCT_PRICE * 7}(productId, 7);
        vm.expectRevert(DcentraclMart.InsufficientStock.selector);
        vm.prank(buyer);
        mart.purchaseProduct{value: PRODUCT_PRICE}(productId, 1);
    }

    function test_PurchaseProduct_BuyerOrdersUpdated() public {
        _registerSeller();
        uint256 productId = _listProduct();
        _purchaseProduct(productId, 1);

        uint256[] memory orders = mart.getBuyerOrderIds(buyer);
        assertEq(orders.length, 1);
        assertEq(orders[0], 1);
    }

    function test_PurchaseProduct_EmitEvent() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.expectEmit(true, true, true, true);
        emit OrderPlaced(1, productId, buyer, seller, 1, PRODUCT_PRICE);

        vm.prank(buyer);
        mart.purchaseProduct{value: PRODUCT_PRICE}(productId, 1);
    }

    function test_PurchaseProduct_Revert_OwnProduct() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.deal(seller, 10 ether);
        vm.expectRevert(DcentraclMart.CannotBuyOwnProduct.selector);
        vm.prank(seller);
        mart.purchaseProduct{value: PRODUCT_PRICE}(productId, 1);
    }

    function test_PurchaseProduct_Revert_ZeroQuantity() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.expectRevert(DcentraclMart.InvalidQuantity.selector);
        vm.prank(buyer);
        mart.purchaseProduct{value: 0}(productId, 0);
    }

    function test_PurchaseProduct_Revert_InsufficientStock() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.expectRevert(DcentraclMart.InsufficientStock.selector);
        vm.prank(buyer);
        mart.purchaseProduct{value: PRODUCT_PRICE * 99}(productId, 99);
    }

    function test_PurchaseProduct_Revert_IncorrectPayment() public {
        _registerSeller();
        uint256 productId = _listProduct();

        vm.expectRevert(DcentraclMart.IncorrectPayment.selector);
        vm.prank(buyer);
        mart.purchaseProduct{value: 0.5 ether}(productId, 1);
    }

    function test_PurchaseProduct_Revert_ProductNotFound() public {
        vm.expectRevert(DcentraclMart.ProductNotFound.selector);
        vm.prank(buyer);
        mart.purchaseProduct{value: PRODUCT_PRICE}(99, 1);
    }

    // ═════════════════════════════════════════
    // 6. MARK AS SHIPPED TESTS
    // ═════════════════════════════════════════

    function test_MarkAsShipped_Success() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);
    }

    function test_MarkAsShipped_EmitEvent() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);

        vm.expectEmit(true, false, false, true);
        emit OrderStatusChanged(
            orderId, DcentraclMart.OrderStatus.Pending, DcentraclMart.OrderStatus.Shipped, block.timestamp
        );

        vm.prank(seller);
        mart.markAsShipped(orderId);
    }

    function test_MarkAsShipped_Revert_NotSeller() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);

        vm.expectRevert(DcentraclMart.NotTheOrderSeller.selector);
        vm.prank(buyer);
        mart.markAsShipped(orderId);
    }

    function test_MarkAsShipped_Revert_InvalidStatus() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);

        vm.expectRevert(DcentraclMart.InvalidOrderStatus.selector);
        vm.prank(seller);
        mart.markAsShipped(orderId);
    }

    function test_MarkAsShipped_Revert_OrderNotFound() public {
        vm.expectRevert(DcentraclMart.OrderNotFound.selector);
        vm.prank(seller);
        mart.markAsShipped(99);
    }

    // ═════════════════════════════════════════
    // 7. CONFIRM DELIVERY TESTS
    // ═════════════════════════════════════════

    function test_ConfirmDelivery_Success() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);
        _confirmDelivery(orderId);
    }

    function test_ConfirmDelivery_PlatformFeeCorrect() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);
        _confirmDelivery(orderId);

        uint256 expectedFee = (PRODUCT_PRICE * PLATFORM_FEE) / 10000;
        assertEq(mart.platformErnings(), expectedFee);
    }

    function test_ConfirmDelivery_SellerEarningsCorrect() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);
        _confirmDelivery(orderId);

        uint256 platformFee = (PRODUCT_PRICE * PLATFORM_FEE) / 10000;
        uint256 expectedEarnings = PRODUCT_PRICE - platformFee;

        uint256 balanceBefore = seller.balance;
        vm.prank(seller);
        mart.withdrawEarnings();
        assertEq(seller.balance - balanceBefore, expectedEarnings);
    }

    function test_ConfirmDelivery_EmitEvent() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);

        vm.expectEmit(true, true, false, true);
        emit DeliveryConfirmed(orderId, buyer, block.timestamp);

        vm.prank(buyer);
        mart.confirmDelivery(orderId);
    }

    function test_ConfirmDelivery_Revert_NotBuyer() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);

        vm.expectRevert(DcentraclMart.NotTheBuyer.selector);
        vm.prank(stranger);
        mart.confirmDelivery(orderId);
    }

    function test_ConfirmDelivery_Revert_NotShipped() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        // ship na kore directly confirm korar cheshta

        vm.expectRevert(DcentraclMart.InvalidOrderStatus.selector);
        vm.prank(buyer);
        mart.confirmDelivery(orderId);
    }

    // ═════════════════════════════════════════
    // 8. WITHDRAW EARNINGS TESTS
    // ═════════════════════════════════════════

    function test_WithdrawEarnings_Success() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);
        _confirmDelivery(orderId);

        uint256 balanceBefore = seller.balance;
        vm.prank(seller);
        mart.withdrawEarnings();

        assert(seller.balance > balanceBefore);
    }

    function test_WithdrawEarnings_EarningsZeroAfterWithdraw() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);
        _confirmDelivery(orderId);

        vm.prank(seller);
        mart.withdrawEarnings();

        vm.expectRevert(DcentraclMart.NothingToWithdraw.selector);
        vm.prank(seller);
        mart.withdrawEarnings();
    }

    function test_WithdrawEarnings_EmitEvent() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);
        _confirmDelivery(orderId);

        uint256 platformFee = (PRODUCT_PRICE * PLATFORM_FEE) / 10000;
        uint256 expectedAmount = PRODUCT_PRICE - platformFee;

        vm.expectEmit(true, false, false, true);
        emit EarningsWithdrawn(seller, expectedAmount, block.timestamp);

        vm.prank(seller);
        mart.withdrawEarnings();
    }

    function test_WithdrawEarnings_Revert_NotSeller() public {
        vm.expectRevert(DcentraclMart.NotASeller.selector);
        vm.prank(stranger);
        mart.withdrawEarnings();
    }

    function test_WithdrawEarnings_Revert_NothingToWithdraw() public {
        _registerSeller();

        vm.expectRevert(DcentraclMart.NothingToWithdraw.selector);
        vm.prank(seller);
        mart.withdrawEarnings();
    }

    // ═════════════════════════════════════════
    // 9. REQUEST REFUND TESTS
    // ═════════════════════════════════════════

    function test_RequestRefund_Success() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);

        vm.prank(buyer);
        mart.requestRefund(orderId, "Item not needed");
    }

    function test_RequestRefund_EmitEvent() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);

        vm.expectEmit(true, true, false, true);
        emit RefundRequest(orderId, buyer, "Item not needed", block.timestamp);

        vm.prank(buyer);
        mart.requestRefund(orderId, "Item not needed");
    }

    function test_RequestRefund_Revert_NotBuyer() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);

        vm.expectRevert(DcentraclMart.NotTheBuyer.selector);
        vm.prank(stranger);
        mart.requestRefund(orderId, "reason");
    }

    function test_RequestRefund_Revert_InvalidStatus() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);

        vm.expectRevert(DcentraclMart.InvalidOrderStatus.selector);
        vm.prank(buyer);
        mart.requestRefund(orderId, "reason");
    }

    function test_RequestRefund_Revert_EmptyReason() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);

        vm.expectRevert(DcentraclMart.EmptyString.selector);
        vm.prank(buyer);
        mart.requestRefund(orderId, "");
    }

    // ═════════════════════════════════════════
    // 10. RAISE DISPUTE TESTS
    // ═════════════════════════════════════════

    // function test_RaiseDispute_BuyerSuccess() public {
    //     _registerSeller();
    //     uint256 productId = _listProduct();
    //     uint256 orderId = _purchaseProduct(productId, 1);

    //     vm.prank(buyer);
    //     mart.raiseDispute(orderId, "Item not received");
    // }

    // function test_RaiseDispute_SellerSuccess() public {
    //     _registerSeller();
    //     uint256 productId = _listProduct();
    //     uint256 orderId = _purchaseProduct(productId, 1);

    //     vm.prank(seller);
    //     mart.raiseDispute(orderId, "Buyer not responding");
    // }

    // function test_RaiseDispute_EmitEvent() public {
    //     _registerSeller();
    //     uint256 productId = _listProduct();
    //     uint256 orderId = _purchaseProduct(productId, 1);

    //     vm.expectEmit(true, true, false, true);
    //     emit DisputeRaised(orderId, buyer, "Item not received", block.timestamp);

    //     vm.prank(buyer);
    //     mart.raiseDispute(orderId, "Item not received");
    // }

    // function test_RaiseDispute_Revert_Unauthorized() public {
    //     _registerSeller();
    //     uint256 productId = _listProduct();
    //     uint256 orderId = _purchaseProduct(productId, 1);

    //     vm.expectRevert(DcentraclMart.Unauthorized.selector);
    //     vm.prank(stranger);
    //     mart.raiseDispute(orderId, "reason");
    // }

    // function test_RaiseDispute_Revert_AlreadyExists() public {
    //     _registerSeller();
    //     uint256 productId = _listProduct();
    //     uint256 orderId = _purchaseProduct(productId, 1);

    //     vm.prank(buyer);
    //     mart.raiseDispute(orderId, "First dispute");

    //     vm.expectRevert(DcentraclMart.DisputeAlreadyExists.selector);
    //     vm.prank(buyer);
    //     mart.raiseDispute(orderId, "Second dispute");
    // }

    // function test_RaiseDispute_Revert_OrderNotDisputable() public {
    //     _registerSeller();
    //     uint256 productId = _listProduct();
    //     uint256 orderId = _purchaseProduct(productId, 1);
    //     _shipOrder(orderId);
    //     _confirmDelivery(orderId);

    //     vm.expectRevert(DcentraclMart.OrderNotDisputable.selector);
    //     vm.prank(buyer);
    //     mart.raiseDispute(orderId, "reason");
    // }

    // function test_RaiseDispute_Revert_EmptyDescription() public {
    //     _registerSeller();
    //     uint256 productId = _listProduct();
    //     uint256 orderId = _purchaseProduct(productId, 1);

    //     vm.expectRevert(DcentraclMart.EmptyString.selector);
    //     vm.prank(buyer);
    //     mart.raiseDispute(orderId, "");
    // }

    // ═════════════════════════════════════════
    // 11. ADMIN TESTS
    // ═════════════════════════════════════════

    function test_UpdatePlatformFee_Success() public {
        vm.prank(owner);
        mart.updatePlatformFee(500);
        assertEq(mart.platformFeePercent(), 500);
    }

    function test_UpdatePlatformFee_Revert_NotOwner() public {
        vm.expectRevert();
        vm.prank(stranger);
        mart.updatePlatformFee(500);
    }

    function test_WithdrawPlatformFees_Success() public {
        _registerSeller();
        uint256 productId = _listProduct();
        uint256 orderId = _purchaseProduct(productId, 1);
        _shipOrder(orderId);
        _confirmDelivery(orderId);

        uint256 balanceBefore = owner.balance;
        vm.prank(owner);
        mart.withdrawPlatformFees();

        assert(owner.balance > balanceBefore);
    }

    function test_WithdrawPlatformFees_Revert_NothingToWithdraw() public {
        vm.expectRevert(DcentraclMart.NothingToWithdraw.selector);
        vm.prank(owner);
        mart.withdrawPlatformFees();
    }

    function test_WithdrawPlatformFees_Revert_NotOwner() public {
        vm.expectRevert();
        vm.prank(stranger);
        mart.withdrawPlatformFees();
    }
}

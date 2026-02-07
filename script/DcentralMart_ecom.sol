// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract DcentraclMart is ReentrancyGuard, Ownable {
    ///////////////////
    // Errors
    ///////////////////
    error NotASeller();
    error AlreadySeller();
    error InvalidShopName();
    error InvalidShopDescription();
    error InvalidProductName();
    error InvalidPrice();
    error InvalidQuantity();
    error ProductNotFound();
    error NotProductOwner();
    error CannotBuyOwnProduct();
    error InsufficientStock();
    error IncorrectPayment();
    error OrderNotFound();
    error ProductNotActive();
    error NotTheBuyer();
    error InvalidOrderStatus();
    error TransferFailed();
    error NothingToWithdraw();
    error EmptyString();
    error DisputeAlreadyExists();
    error OrderNotDisputable();
    error Unauthorized();
    error NotTheOrderSeller();

    ///////////////////
    // Event
    ///////////////////

    event OrderPlaced(
        uint256 indexed orderId,
        uint256 indexed productId,
        address indexed buyer,
        address seller,
        uint256 quantity,
        uint256 totalPrice
    );

    event SellerRegistered(address indexed seller, string shopName, uint256 timestamp);

    event SellerUpdate(address indexed seller, string shopName, uint256 timestamp);

    event ProductListed(
        uint256 indexed productId, address indexed seller, string name, uint256 price, uint256 quantity
    );

    event ProductUpdated(uint256 indexed productId, uint256 price, uint256 quantity, bool isActive);

    event OrderStatusChanged(uint256 indexed orderId, OrderStatus oldStatus, OrderStatus newStatus, uint256 timestamp);

    event EarningsWithdrawn(address indexed seller, uint256 amount, uint256 timestamp);

    event DeliveryConfirmed(uint256 indexed orderId, address indexed buyer, uint256 timestamp);

    event RefundRequest(uint256 indexed orderId, address indexed buyer, string reason, uint256 timestamp);

    event RefundProcessed(uint256 indexed orderId, address indexed buyer, uint256 amount, uint256 timestamp);

    event DisputeRaised(uint256 indexed orderId, address indexed complaint, string description, uint256 timestamp);

    ///////////////////
    // Errors
    ///////////////////

    uint256 public productIdCounter;
    uint256 public ordderIdCount;
    uint256 public platformFeePercent;
    uint256 public platformErnings;

    ///////////////////
    // enum
    ///////////////////

    enum OrderStatus {
        Pending,
        Shipped,
        Delivered,
        Cancelled,
        Refunded,
        Disputed
    }

    enum DisputeStatus {
        None,
        Open,
        UnderReview,
        ResolvedBuyer,
        ResolvedSeller
    }

    ///////////////////
    // struct
    ///////////////////
    struct SellerStruct {
        string shopName;
        string shopDescription;
        address sellerAddress;
        uint256 totalSales;
        uint256 earnings;
        bool isActive;
        uint256 registeredAt;
    }

    struct ProductStruct {
        uint256 id;
        string name;
        string description;
        uint256 price;
        uint256 quantity;
        string category;
        address seller;
        bool isActive;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct OrderStruct {
        uint256 id;
        uint256 productId;
        address buyer;
        address seller;
        uint256 quantity;
        uint256 totalPrice;
        OrderStatus status;
        DisputeStatus disputeStatus;
        uint256 createdAt;
        uint256 updatedAt;
    }

    struct Dispute {
        uint256 orderId;
        address complainant;
        string description;
        DisputeStatus status;
        uint256 createdAt;
        uint256 resolvedAt;
    }

    ///////////////////
    // mapping
    ///////////////////

    mapping(address => SellerStruct) private sellerMap;
    mapping(uint256 => ProductStruct) private productMap;
    mapping(uint256 => OrderStruct) private orderMap;
    mapping(address => uint256[]) private buyerOrders;
    mapping(address => uint256[]) private sellerOrders;
    mapping(address => uint256[]) public sellerProduct;
    mapping(uint256 => Dispute) public disputes;

    ///////////////////
    // modifier
    ///////////////////

    modifier onlySeller() {
        if (!sellerMap[msg.sender].isActive) {
            revert NotASeller();
        }
        _;
    }

    modifier validOrder(uint256 orderId) {
        if (orderId == 0 || orderId > ordderIdCount) {
            revert OrderNotFound();
        }
        _;
    }

    modifier validProduct(uint256 productId) {
        if (productId == 0 || productId > productIdCounter) {
            revert ProductNotFound();
        }

        if (!productMap[productId].isActive) {
            revert ProductNotActive();
        }
        _;
    }

    constructor(uint256 _platformFee) Ownable(msg.sender) {
        platformFeePercent = _platformFee;
    }

    function registerSeller(string calldata _shopeName, string calldata _description) external {
        if (sellerMap[msg.sender].isActive) {
            revert AlreadySeller();
        }

        if (bytes(_shopeName).length == 0) {
            revert InvalidShopName();
        }

        if (bytes(_description).length == 0) {
            revert InvalidShopDescription();
        }

        sellerMap[msg.sender] = SellerStruct({
            shopName: _shopeName,
            shopDescription: _description,
            sellerAddress: msg.sender,
            totalSales: 0,
            earnings: 0,
            isActive: true,
            registeredAt: block.timestamp
        });

        emit SellerRegistered(msg.sender, _shopeName, block.timestamp);
    }

    function listProduct(
        string calldata name,
        string calldata description,
        string calldata category,
        uint256 price,
        uint256 quantity
    ) external onlySeller returns (uint256 productId) {
        if (bytes(name).length == 0) {
            revert InvalidProductName();
        }

        if (price == 0) {
            revert InvalidPrice();
        }

        if (quantity == 0) {
            revert InvalidQuantity();
        }

        productIdCounter++;
        productId = productIdCounter;

        productMap[productId] = ProductStruct({
            id: productId,
            name: name,
            description: description,
            price: price,
            quantity: quantity,
            category: category,
            seller: msg.sender,
            isActive: true,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        sellerProduct[msg.sender].push(productId);

        emit ProductListed(productId, msg.sender, name, price, quantity);

        return productId;
    }

    function updateProduct(uint256 productId, uint256 price, uint256 quantity, bool isActive) external {
        if (productId == 0 || productId > productIdCounter) {
            revert ProductNotFound();
        }

        if (productMap[productId].seller != msg.sender) {
            revert NotProductOwner();
        }

        if (price == 0) {
            revert InvalidPrice();
        }

        ProductStruct storage newProduct = productMap[productId];

        newProduct.price = price;
        newProduct.quantity = quantity;
        newProduct.isActive = isActive;
        newProduct.updatedAt = block.timestamp;

        emit ProductUpdated(productId, price, quantity, isActive);
    }

    function purchaseProduct(uint256 productId, uint256 quantity)
        external
        payable
        validProduct(productId)
        nonReentrant
        returns (uint256 orderId)
    {
        ProductStruct storage newProduct = productMap[productId];

        if (newProduct.seller == msg.sender) {
            revert CannotBuyOwnProduct();
        }

        if (quantity == 0) {
            revert InvalidQuantity();
        }

        if (newProduct.quantity < quantity) {
            revert InsufficientStock();
        }

        uint256 totalPrice = newProduct.price * quantity;
        if (msg.value != totalPrice) {
            revert IncorrectPayment();
        }

        ordderIdCount++;
        orderId = ordderIdCount;
        newProduct.quantity -= quantity;

        orderMap[orderId] = OrderStruct({
            id: orderId,
            productId: productId,
            buyer: msg.sender,
            seller: newProduct.seller,
            quantity: quantity,
            totalPrice: totalPrice,
            status: OrderStatus.Pending,
            disputeStatus: DisputeStatus.None,
            createdAt: block.timestamp,
            updatedAt: block.timestamp
        });

        buyerOrders[msg.sender].push(orderId);
        sellerOrders[newProduct.seller].push(orderId);

        emit OrderPlaced(orderId, productId, msg.sender, newProduct.seller, quantity, totalPrice);

        return orderId;
    }

    function confirmDelivery(uint256 orderId) external validOrder(orderId) nonReentrant {
        OrderStruct storage order = orderMap[orderId];

        if (order.buyer != msg.sender) {
            revert NotTheBuyer();
        }

        if (order.status != OrderStatus.Shipped) {
            revert InvalidOrderStatus();
        }

        OrderStatus oldStatus = order.status;
        order.status = OrderStatus.Delivered;
        order.updatedAt = block.timestamp;

        uint256 platformFee = (order.totalPrice * platformFeePercent) / 10000;
        uint256 sellerAmount = order.totalPrice - platformFee;

        platformErnings += platformFee;

        sellerMap[order.seller].earnings += sellerAmount;
        sellerMap[order.seller].totalSales++;

        emit OrderStatusChanged(orderId, oldStatus, OrderStatus.Delivered, block.timestamp);

        emit DeliveryConfirmed(orderId, msg.sender, block.timestamp);
    }

    function withdrawEarnings() external onlySeller nonReentrant {
        uint256 amount = sellerMap[msg.sender].earnings;
        sellerMap[msg.sender].earnings = 0;
        if (amount == 0) {
            revert NothingToWithdraw();
        }

        (bool success,) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }
        emit EarningsWithdrawn(msg.sender, amount, block.timestamp);
    }

    function requestRefund(uint256 orderId, string memory reason) external validOrder(orderId) {
        OrderStruct storage order = orderMap[orderId];

        if (order.buyer != msg.sender) {
            revert NotTheBuyer();
        }

        if (order.status != OrderStatus.Pending) {
            revert InvalidOrderStatus();
        }

        if (bytes(reason).length == 0) {
            revert EmptyString();
        }
        emit RefundRequest(orderId, msg.sender, reason, block.timestamp);
    }

    function raiseDispute(uint256 orderId, string calldata description) external {
        OrderStruct storage order = orderMap[orderId];

        if (order.buyer != msg.sender && order.seller != msg.sender) {
            revert Unauthorized();
        }

        if (
            order.status == OrderStatus.Delivered || order.status == OrderStatus.Cancelled
                || order.status == OrderStatus.Refunded
        ) {
            revert OrderNotDisputable();
        }

        if (order.disputeStatus != DisputeStatus.None) {
            revert DisputeAlreadyExists();
        }

        if (bytes(description).length == 0) {
            revert EmptyString();
        }

        order.status = OrderStatus.Disputed;
        order.disputeStatus = DisputeStatus.Open;
        order.updatedAt = block.timestamp;

        disputes[orderId] = Dispute({
            orderId: orderId,
            complainant: msg.sender,
            description: description,
            status: DisputeStatus.Open,
            createdAt: block.timestamp,
            resolvedAt: 0
        });

        emit DisputeRaised(orderId, msg.sender, description, block.timestamp);
    }

    function updatePlatformFee(uint256 newFeePercent) external onlyOwner {
        platformFeePercent = newFeePercent;
    }

    function withdrawPlatformFees() external onlyOwner nonReentrant {
        uint256 amount = platformErnings;

        if (amount == 0) {
            revert NothingToWithdraw();
        }
        platformErnings = 0;

        (bool success,) = payable(owner()).call{value: amount}("");

        if (!success) {
            revert TransferFailed();
        }
    }

    function markAsShipped(uint256 orderId) external validOrder(orderId) {
        OrderStruct storage order = orderMap[orderId];

        if (order.seller != msg.sender) {
            revert NotTheOrderSeller();
        }

        if (order.status != OrderStatus.Pending) {
            revert InvalidOrderStatus();
        }

        OrderStatus oldStatus = order.status;
        order.status = OrderStatus.Shipped;
        order.updatedAt = block.timestamp;

        order.status = OrderStatus.Shipped;
        emit OrderStatusChanged(orderId, oldStatus, OrderStatus.Shipped, block.timestamp);
    }

    function getTotalProducts() external view returns (uint256) {
        return productIdCounter;
    }

    function getTotalOrders() external view returns (uint256) {
        return ordderIdCount;
    }

    function getSellerProductIds(address seller) external view returns (uint256[] memory) {
        return sellerProduct[seller];
    }

    function getBuyerOrderIds(address buyer) external view returns (uint256[] memory) {
        return buyerOrders[buyer];
    }
}

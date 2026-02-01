// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

contract DcentraclMart {
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

    event OrderPlaced(
        uint256 indexed orderId,
        uint256 indexed productId,
        address indexed buyer,
        address seller,
        uint256 quantity,
        uint256 totalPrice
    );

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

    ///////////////////
    // mapping
    ///////////////////

    mapping(address => SellerStruct) private sellerMap;
    mapping(uint256 => ProductStruct) private productMap;
    mapping(uint256 => OrderStruct) private orderMap;
    mapping(address => uint256[]) private buyerOrders;
    mapping(address => uint256[]) private sellerOrders;

    ///////////////////
    // modifier
    ///////////////////

    modifier onlySeller() {
        if (!sellerMap[msg.sender].isActive) {
            revert NotASeller();
        }
        _;
    }

    constructor(uint256 _platformFee) {
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
    }

    function purchaseProduct(uint256 productId, uint256 quantity) external returns (uint256 orderId) {
        ProductStruct storage newProduct = productMap[productId];

        uint256 totalPrice = newProduct.price * quantity;

        ordderIdCount++;
        orderId = ordderIdCount;
        newProduct.quantity -= quantity;

        uint256 platformFee = (totalPrice * platformFeePercent) / 10000;
        uint256 sellerAmount = totalPrice - platformFee;

        platformErnings += platformFee;

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

        (bool success,) = payable(newProduct.seller).call{value: sellerAmount}("");
        require(success, "Transfer failed");

        buyerOrders[msg.sender].push(orderId);
        sellerOrders[msg.sender].push(orderId);

        emit OrderPlaced(orderId, productId, msg.sender, newProduct.seller, quantity, totalPrice);

        return orderId;
    }
}

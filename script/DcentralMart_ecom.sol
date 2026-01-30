// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

contract DcentraclMart {
    uint256 public productIdCounter;

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

    ///////////////////
    // mapping
    ///////////////////

    mapping(address => SellerStruct) private sellerMap;
    mapping(uint256 => ProductStruct) private productStruct;

    constructor() {}

    function registerSeller(string calldata _shopeName, string calldata _description) external {
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
    ) external returns (uint256 productId) {
        productIdCounter++;
        productId = productIdCounter;

        productStruct[productId] = ProductStruct({
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
        })
    }
}

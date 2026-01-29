// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.26;

contract DcentraclMart {
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

    ///////////////////
    // mapping
    ///////////////////

    mapping(address => SellerStruct) sellerMap;

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
}

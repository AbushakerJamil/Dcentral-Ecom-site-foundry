# DcentraclMart - Decentralized Marketplace

A decentralized e-commerce platform built on Ethereum that enables peer-to-peer buying and selling without intermediaries.

## Overview

DcentraclMart is a smart contract-based marketplace where sellers can list products and buyers can purchase them directly using cryptocurrency. The platform handles order management, dispute resolution, and automated payment distribution.

## Key Features

### For Sellers

- **Seller Registration**: Register your shop with a name and description
- **Product Management**: List, update, and manage product inventory
- **Order Tracking**: Monitor all orders and update shipping status
- **Earnings Withdrawal**: Withdraw accumulated earnings anytime
- **Dispute Handling**: Participate in dispute resolution process

### For Buyers

- **Browse Products**: View available products from registered sellers
- **Secure Purchases**: Buy products with cryptocurrency payments
- **Delivery Confirmation**: Confirm receipt to release payment to seller
- **Refund Requests**: Request refunds for pending orders
- **Dispute Resolution**: Raise disputes for problematic orders

### Platform Features

- Automated fee collection (configurable platform fee)
- Reentrancy protection for secure transactions
- Order status tracking (Pending, Shipped, Delivered, Cancelled, Refunded, Disputed)
- Dispute management system
- Ownership-based access control

## Smart Contract Details

**Contract Name**: `DcentraclMart`  
**Solidity Version**: `^0.8.26`  
**License**: SEE LICENSE IN LICENSE

### Dependencies

- OpenZeppelin Contracts
  - `Ownable.sol` - Access control
  - `ReentrancyGuard.sol` - Protection against reentrancy attacks

## Core Functions

### Seller Functions

```solidity
registerSeller(string shopName, string description)
listProduct(string name, string description, string category, uint256 price, uint256 quantity)
updateProduct(uint256 productId, uint256 price, uint256 quantity, bool isActive)
markAsShipped(uint256 orderId)
withdrawEarnings()
```

### Buyer Functions

```solidity
purchaseProduct(uint256 productId, uint256 quantity) payable
confirmDelivery(uint256 orderId)
requestRefund(uint256 orderId, string reason)
raiseDispute(uint256 orderId, string description)
```

### Admin Functions

```solidity
updatePlatformFee(uint256 newFeePercent)
withdrawPlatformFees()
```

### View Functions

```solidity
getTotalProducts()
getTotalOrders()
getSellerProductIds(address seller)
getBuyerOrderIds(address buyer)
```

## Order Lifecycle

1. **Pending** - Order placed, payment held in contract
2. **Shipped** - Seller marks order as shipped
3. **Delivered** - Buyer confirms delivery, payment released
4. **Cancelled/Refunded** - Order cancelled or refunded
5. **Disputed** - Dispute raised by buyer or seller

## Fee Structure

- Platform charges a configurable fee percentage on each completed sale
- Fee is deducted from seller earnings upon delivery confirmation
- Platform owner can withdraw accumulated fees

## Security Features

- **ReentrancyGuard**: Prevents reentrancy attacks on withdrawal functions
- **Access Control**: Role-based permissions (Owner, Seller, Buyer)
- **Input Validation**: Comprehensive checks for all user inputs
- **Custom Errors**: Gas-efficient error handling

## Events

The contract emits events for:

- Seller registration and updates
- Product listings and updates
- Order placement and status changes
- Delivery confirmations
- Refund requests and processing
- Dispute creation
- Earnings withdrawals

## Data Structures

### SellerStruct

Stores seller information including shop details, sales statistics, and earnings.

### ProductStruct

Contains product information including name, price, quantity, and seller address.

### OrderStruct

Tracks order details including buyer, seller, product, quantity, price, and status.

### Dispute

Manages dispute information including complainant, description, and resolution status.

## Getting Started

### Prerequisites

- Node.js and npm
- Hardhat or Foundry development environment
- MetaMask or similar Web3 wallet

### Installation

```bash
# Clone the repository
git clone <repository-url>

# Install dependencies
npm install

# Compile contracts
npx hardhat compile
```

### Deployment

```bash
# Deploy to local network
npx hardhat run scripts/deploy.js --network localhost

# Deploy to testnet (e.g., Sepolia)
npx hardhat run scripts/deploy.js --network sepolia
```

### Testing

```bash
# Run tests
npx hardhat test

# Run with coverage
npx hardhat coverage
```

## Usage Example

### Registering as a Seller

```javascript
await dcentraclMart.registerSeller("My Shop", "Quality products for everyone");
```

### Listing a Product

```javascript
await dcentraclMart.listProduct(
  "Laptop",
  "High-performance laptop",
  "Electronics",
  ethers.parseEther("1.5"),
  10,
);
```

### Purchasing a Product

```javascript
await dcentraclMart.purchaseProduct(productId, 2, {
  value: ethers.parseEther("3.0"),
});
```

## Known Issues & Limitations

- No built-in escrow period (buyers must manually confirm delivery)
- Dispute resolution requires manual intervention by contract owner
- No automatic refund mechanism for cancelled orders
- Platform fee is applied even on disputed orders that favor buyers

## Future Improvements

- Automated escrow with time-based release
- Decentralized dispute resolution (DAO-based)
- Rating and review system
- Multi-token payment support
- IPFS integration for product images
- Advanced search and filtering

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Security

If you discover a security vulnerability, please email [security@example.com] instead of using the issue tracker.

## License

This project is licensed under the terms specified in the LICENSE file.

## Contact

- Project Link: [https://github.com/yourusername/dcentraclmart]
- Documentation: [Link to docs]
- Support: [support@example.com]

## Acknowledgments

- OpenZeppelin for secure contract libraries
- Ethereum community for development tools
- Contributors and testers

---

**Disclaimer**: This smart contract is provided as-is. Always conduct thorough testing and audits before deploying to mainnet.

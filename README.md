# EVM Sort

A gas-optimized sorting contract for Ethereum Virtual Machine (EVM) that efficiently maintains sorted collections using a three-layer architecture with bitfields and heaps.

## Overview

**EvmSort** is a Solidity smart contract that provides efficient sorting operations for numerical values on-chain. It uses a sophisticated three-layer data structure combining bitfields and heap-based indexing to achieve O(log n) time complexity for insertions and deletions.

### Key Features

- **Dual Collections**: Maintains separate max and min sorted sets
- **Gas Optimized**: Uses bitfield packing to minimize storage costs
- **Efficient Operations**: O(log n) insert, delete, and pop operations
- **Large Value Support**: Handles uint256 values
- **Battle-Tested**: Comprehensive test suite with 41+ test cases

### Architecture

The contract uses a three-layer architecture:

1. **First Layer (Bitfields)**: Direct bit mapping for values using 256-bit slots
2. **Second Layer (Bitfields)**: Bitmap of active first layer slots
3. **Third Layer (Heaps)**: MaxHeap/MinHeap for efficient top-level indexing

## Installation

### Prerequisites

- Node.js v20.6+ or v22.10+ (LTS recommended)
- npm v10+
- Git

### Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd evm-sorting
   ```

2. **Install Node.js (if needed)**
   ```bash
   # Using nvm (recommended)
   nvm install 22
   nvm use 22
   ```

3. **Install dependencies**
   ```bash
   npm install
   ```

4. **Compile contracts**
   ```bash
   npx hardhat compile
   ```

## Contract API

### Main Functions

#### `setValue(uint256 element, bool exists, bool isMax)`
Add or remove an element from a set.
- `element`: The value to add/remove
- `exists`: `true` to add, `false` to remove
- `isMax`: `true` for max set, `false` for min set

```solidity
// Add 100 to max set
evmSort.setValue(100, true, true);

// Remove 100 from max set
evmSort.setValue(100, false, true);
```

#### `getMax() → uint256`
View the maximum value without removing it.
```solidity
uint256 max = evmSort.getMax();
```

#### `getMin() → uint256`
View the minimum value without removing it.
```solidity
uint256 min = evmSort.getMin();
```

#### `popMax() → uint256`
Remove and return the maximum value.
```solidity
uint256 max = evmSort.popMax();
```

#### `popMin() → uint256`
Remove and return the minimum value.
```solidity
uint256 min = evmSort.popMin();
```

#### `removeSpecificMax(uint256 element) → uint256`
Remove a specific value from the max set.
```solidity
evmSort.removeSpecificMax(200);
```

#### `removeSpecificMin(uint256 element) → uint256`
Remove a specific value from the min set.
```solidity
evmSort.removeSpecificMin(50);
```

#### `hasElement(uint256 element, bool isMax) → bool`
Check if an element exists in a set.
```solidity
bool exists = evmSort.hasElement(100, true);
```

## Running Tests

The project includes comprehensive test suites for both max and min sorting operations.

### Run All Tests
```bash
npm test
```

### Run Max Sorting Tests Only
```bash
npm run test:max
```

### Run Min Sorting Tests Only
```bash
npm run test:min
```

### Test Coverage

```
✔ 41 passing tests
  ├─ Max Sorting: 18 tests
  │  ├─ setValue operations
  │  ├─ getMax operations
  │  ├─ popMax operations
  │  ├─ removeSpecificMax operations
  │  └─ Edge cases
  │
  └─ Min Sorting: 23 tests
     ├─ setValue operations
     ├─ getMin operations
     ├─ popMin operations
     ├─ removeSpecificMin operations
     ├─ Edge cases
     └─ Independence of min/max sets
```

## Deployment

### Local Deployment (Hardhat Network)

```bash
npm run deploy
```

### Deploy to Local Node

Terminal 1:
```bash
npm run node
```

Terminal 2:
```bash
npm run deploy:localhost
```

### Deploy to Testnet

1. **Create `.env` file**
   ```bash
   SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
   PRIVATE_KEY=your_private_key_here
   ETHERSCAN_API_KEY=your_etherscan_api_key
   ```

2. **Update `hardhat.config.js`**
   ```javascript
   require("dotenv").config();

   module.exports = {
     solidity: "0.8.28",
     networks: {
       sepolia: {
         url: process.env.SEPOLIA_RPC_URL,
         accounts: [process.env.PRIVATE_KEY]
       }
     },
     etherscan: {
       apiKey: process.env.ETHERSCAN_API_KEY
     }
   };
   ```

3. **Deploy**
   ```bash
   npm run deploy:sepolia
   ```

### Deployment Output

After deployment, contract addresses are saved to `deployments/deployment-{timestamp}.json`:

```json
{
  "network": "hardhat",
  "chainId": "31337",
  "deployer": "0xf39Fd6...",
  "timestamp": "2025-11-07T15:21:27.130Z",
  "evmSortAddress": "0x9fE46...",
  "libraries": {
    "MaxHeap": "0x5FbDB...",
    "MinHeap": "0xe7f17..."
  }
}
```

## Project Structure

```
evm-sorting/
├── contracts/
│   ├── evmSort.sol       # Main sorting contract
│   ├── MaxHeap.sol       # Max heap library
│   └── MinHeap.sol       # Min heap library
├── test/
│   ├── maxSort.test.js   # Max sorting tests
│   └── minSort.test.js   # Min sorting tests
├── scripts/
│   └── deploy.js         # Deployment script
├── deployments/          # Deployment artifacts (gitignored)
├── hardhat.config.js     # Hardhat configuration
└── package.json          # NPM dependencies & scripts
```

## Gas Optimization

The contract is optimized for minimal gas costs:

- **Bitfield Packing**: Stores 256 values per storage slot
- **Library Usage**: MaxHeap and MinHeap use packed uint32 arrays (8 values per slot)
- **Minimal Storage**: Only stores presence, not actual values
- **Efficient Lookups**: O(1) existence checks, O(log n) min/max retrieval

## Use Cases

- **Order Books**: DEX price level tracking
- **Priority Queues**: On-chain task scheduling
- **Leaderboards**: Gaming score tracking
- **Auctions**: Bid management
- **Data Structures**: General-purpose sorted collections

## Examples

### Example 1: Basic Sorting

```solidity
// Add values to max set
evmSort.setValue(100, true, true);
evmSort.setValue(200, true, true);
evmSort.setValue(50, true, true);

// Get max value
uint256 max = evmSort.getMax(); // Returns 200

// Pop values in descending order
evmSort.popMax(); // Returns 200
evmSort.popMax(); // Returns 100
evmSort.popMax(); // Returns 50
```

### Example 2: Min Set Operations

```solidity
// Add values to min set
evmSort.setValue(100, true, false);
evmSort.setValue(200, true, false);
evmSort.setValue(50, true, false);

// Get min value
uint256 min = evmSort.getMin(); // Returns 50

// Remove specific value
evmSort.removeSpecificMin(50);
uint256 newMin = evmSort.getMin(); // Returns 100
```

### Example 3: Independent Sets

```solidity
// Max and min sets are independent
evmSort.setValue(100, true, true);  // Add to max
evmSort.setValue(100, true, false); // Add to min

evmSort.hasElement(100, true);  // true
evmSort.hasElement(100, false); // true

evmSort.setValue(100, false, true); // Remove from max
evmSort.hasElement(100, true);  // false
evmSort.hasElement(100, false); // still true
```

## Development

### Available Scripts

```bash
npm test              # Run all tests
npm run test:max      # Run max sorting tests
npm run test:min      # Run min sorting tests
npm run deploy        # Deploy to Hardhat network
npm run deploy:localhost  # Deploy to local node
npm run deploy:sepolia    # Deploy to Sepolia testnet
npm run node          # Start local Hardhat node
npx hardhat compile   # Compile contracts
npx hardhat clean     # Clean artifacts
```

## Troubleshooting

### Node.js Version Issues

If you encounter errors about unsupported Node.js version:

```bash
nvm install 22
nvm use 22
npm install
```

### Library Linking Errors

If you get library linking errors during tests:

```bash
npx hardhat clean
npx hardhat compile
npm test
```

### Deployment Failures

- Ensure you have enough ETH for gas
- Check your RPC URL is correct
- Verify your private key is properly formatted (without 0x prefix in .env)

## Security Considerations

⚠️ **Important Notes:**

- This contract has not been audited
- Test thoroughly before mainnet deployment
- The contract doesn't handle token transfers - it only tracks values
- Ensure proper access controls when integrating into larger systems
- Be aware of gas costs for large-scale operations

## License

ISC

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Support

For issues and questions:
- Open an issue on GitHub
- Review the test files for usage examples
- Check the contract source code for detailed comments

---

Docs Built by Saad Rasool Butt

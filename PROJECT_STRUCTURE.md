# Aave AutoLooper - Project Structure
NOTE: Cursor generated structure for a quick overview of all files (Except UI)


Complete file tree and description of all files in the project (excluding `ui/` folder).

---

## 📁 Project Root

```
aave-autoloop/
├── .env                          # Environment variables (private keys, RPC URLs)
├── .gitignore                    # Git ignore patterns
├── .gitmodules                   # Git submodules configuration
├── foundry.lock                  # Foundry dependency lock file
├── foundry.toml                  # Foundry project configuration
├── README.md                     # Project documentation
├── .github/                      # GitHub Actions workflows
├── broadcast/                    # Deployment transaction logs
├── img/                          # Project images/assets
├── lib/                          # External dependencies (submodules)
├── script/                       # Deployment and utility scripts
├── src/                          # Source code
└── test/                         # Test files
```

---

## 📄 Root Files

### `.env`
**Type:** Environment Configuration  
**Description:** Contains sensitive environment variables including:
- `PRIVATE_KEY` - Deployer's private key for transactions
- `SEPOLIA_RPC_URL` - RPC endpoint for Sepolia testnet
- `FORK_URL` - RPC endpoint for mainnet forking
- Other deployment and testing configuration

**Note:** This file is gitignored and should never be committed.

---

### `.gitignore`
**Type:** Git Configuration  
**Description:** Defines files and directories to exclude from version control:
- `cache/` - Foundry compilation cache
- `out/` - Compiled contract artifacts
- `broadcast/*/31337/` - Local network deployment logs
- `broadcast/**/dry-run/` - Dry-run transaction logs
- `docs/` - Documentation files
- `.env` - Environment variables

---

### `.gitmodules`
**Type:** Git Configuration  
**Description:** Configuration for Git submodules. Lists external dependencies:
- `lib/forge-std` - Foundry standard library
- `lib/defi-aave-v3` - Aave V3 DeFi course materials
- `lib/reactive-lib` - Reactive Network library

---

### `foundry.lock`
**Type:** Dependency Lock File  
**Description:** Foundry's dependency lock file that pins exact versions of all dependencies and submodules. Ensures reproducible builds across different environments.

---

### `foundry.toml`
**Type:** Foundry Configuration  
**Description:** Main configuration file for Foundry toolchain. Contains:
- **Profile settings:**
  - `src = "src"` - Source directory
  - `out = "out"` - Output directory for compiled contracts
  - `libs = ["lib"]` - Libraries directory
  - `via_ir = true` - Enable IR-based code generation
  - `optimizer = true` - Enable Solidity optimizer
  - `optimizer_runs = 200` - Optimization runs

- **Remappings:**
  - `cyfrin-aave/` → Maps to Aave V3 course interfaces
  - `reactive-lib/` → Maps to Reactive Network library

- **RPC endpoints:**
  - `mainnet` - Mainnet fork URL
  - `sepolia` - Sepolia testnet RPC URL

---

### `README.md`
**Type:** Documentation  
**Description:** Main project documentation file. Contains project overview, setup instructions, usage examples, and other important information for developers.

---

## 📁 `.github/` Directory

### `.github/workflows/test.yml`
**Type:** GitHub Actions Workflow  
**Description:** CI/CD pipeline configuration for automated testing. Runs on:
- Push events
- Pull request events
- Manual workflow dispatch

**Workflow steps:**
1. Checkout code with submodules
2. Install Foundry toolchain
3. Show Forge version
4. Run `forge fmt --check` (formatting check)
5. Run `forge build --sizes` (compile contracts)
6. Run `forge test -vvv` (run all tests with verbose output)

---

## 📁 `broadcast/` Directory

**Type:** Deployment Logs  
**Description:** Contains transaction logs from `forge script` deployments. Organized by script name and chain ID.

### `broadcast/DeployAutoLooperSepolia.s.sol/11155111/`
**Description:** Deployment logs for AutoLooper on Sepolia (chain ID 11155111)
- `run-*.json` - Individual deployment run logs
- `run-latest.json` - Latest deployment transaction details

### `broadcast/JustSwapUSDTToUSDC.s.sol/11155111/`
**Description:** Transaction logs for USDT to USDC swap operations
- `dry-run/` - Dry-run simulation logs
- `run-*.json` - Actual transaction logs

### `broadcast/TestAutoLooperSepolia.s.sol/11155111/`
**Description:** Test script execution logs
- `dry-run/` - Dry-run logs for testing

**Note:** These files are generated automatically by Foundry when running deployment scripts.

---

## 📁 `img/` Directory

### `img/image.png` & `img/image copy.png`
**Type:** Image Assets  
**Description:** Project images, diagrams, or UI mockups. May contain:
- Architecture diagrams
- UI designs
- Flow charts
- Documentation images

---

## 📁 `script/` Directory

Deployment and utility scripts for interacting with contracts.

### `script/CheckBalances.s.sol`
**Type:** Utility Script  
**Description:** Script to check token balances (WETH, USDC, etc.) for a given address. Useful for debugging and verifying account states.

---

### `script/Counter.sol`
**Type:** Example Script  
**Description:** Simple counter contract example, likely used for testing Foundry setup.

---

### `script/DeployAutoLooperHelper.s.sol`
**Type:** Deployment Script  
**Description:** Deploys the `AutoLooperHelper` contract to Sepolia. This helper contract:
- Manages AutoLooper positions
- Handles opening/closing positions
- Checks health factors
- Can be called from Reactive Network

**Configuration:**
- Reads `AUTOLOOPER_ADDRESS` from env (or deploys new one)
- Reads `OWNER_ADDRESS` and `RECIPIENT_ADDRESS` from env
- Outputs deployment addresses for use in reactive contract deployment

---

### `script/DeployAutoLooperReactive.s.sol`
**Type:** Deployment Script  
**Description:** Deploys the `AutoLooperReactive` contract to Reactive Network. This reactive contract:
- Subscribes to Chainlink price feeds
- Monitors health factors
- Automatically opens/closes positions based on price updates

**Configuration:**
- `ORIGIN_FEED` - Chainlink feed address
- `ORIGIN_CHAIN_ID` - Chain where feed is located
- `DESTINATION_CHAIN_ID` - Chain where AutoLooper is deployed
- `HELPER_CONTRACT` - Helper contract address
- `AUTOLOOPER_ADDRESS` - AutoLooper contract address
- Position parameters (collateral, loops, borrow %, etc.)

---

### `script/DeployAutoLooperSepolia.s.sol`
**Type:** Deployment Script  
**Description:** Simple script to deploy the `AutoLooper` contract to Sepolia testnet. Used for initial contract deployment.

---

### `script/JustSwapUSDTToUSDC.s.sol`
**Type:** Utility Script  
**Description:** Script to swap USDT to USDC on Uniswap V3. Useful for:
- Testing swap functionality
- Acquiring USDC for testing
- Verifying Uniswap integration

---

### `script/SimulateAutoLoop.s.sol`
**Type:** Simulation Script  
**Description:** Simulates the auto-looping process locally. Used for:
- Testing the looping logic
- Verifying position opening
- Checking health factor calculations
- Testing without deploying to testnet

---

### `script/SupplyUSDCToAave.s.sol`
**Type:** Utility Script  
**Description:** Script to supply USDC to Aave V3 pool. Used for:
- Testing Aave integration
- Providing liquidity for testing
- Verifying supply functionality

---

### `script/SwapUSDTToUSDCAndSupply.s.sol`
**Type:** Utility Script  
**Description:** Combined script that:
1. Swaps USDT to USDC on Uniswap
2. Supplies the USDC to Aave

Useful for end-to-end testing of the swap and supply flow.

---

### `script/TestAutoLooperSepolia.s.sol`
**Type:** Test Script  
**Description:** Tests the AutoLooper contract on Sepolia fork. Performs:
- Position opening tests
- Health factor verification
- Position unwinding tests
- Integration testing with Aave and Uniswap

---

### `script/TestDeployedAutoLooper.s.sol`
**Type:** Test Script  
**Description:** Tests an already deployed AutoLooper contract. Reads contract address from environment and performs various operations.

---

### `script/TestDeployedAutoLooperReal.s.sol`
**Type:** Test Script  
**Description:** Real testnet testing script for deployed AutoLooper. Uses actual Sepolia testnet (not fork) to test:
- Real transactions
- Actual gas costs
- Network interactions
- Production-like scenarios

---

## 📁 `src/` Directory

Main source code directory containing all smart contracts.

---

### `src/Constants.sol`
**Type:** Configuration Contract  
**Description:** Centralized constants file containing all contract addresses and configuration for Sepolia testnet:
- **Tokens:**
  - `WETH` - Wrapped Ether address
  - `USDC` - USD Coin address
  - `USDT` - Tether address
  - `DAI` - Dai stablecoin address

- **Aave V3:**
  - `POOL` - Aave V3 Pool contract address
  - `ORACLE` - Aave Oracle address for price feeds

- **Uniswap V3:**
  - `UNISWAP_V3_SWAP_ROUTER_02` - Uniswap V3 SwapRouter02 address
  - `UNISWAP_V3_POOL_FEE_WETH_USDC` - Fee tier for WETH/USDC pool (3000 = 0.3%)
  - `UNISWAP_V3_POOL_FEE_USDT_USDC` - Fee tier for USDT/USDC pool (500 = 0.05%)
  - `UNISWAP_V3_POOL_FEE_DAI_WETH` - Fee tier for DAI/WETH pool (3000 = 0.3%)

**Purpose:** Single source of truth for all addresses, making it easy to switch networks or update addresses.

---

### `src/Constants.sol.mainnet.backup`
**Type:** Backup Configuration  
**Description:** Backup file containing mainnet addresses. Saved for reference when switching between testnet and mainnet configurations.

---

### `src/ConstantsSepolia.sol`
**Type:** Alternative Configuration  
**Description:** Alternative constants file specifically for Sepolia. May contain different or additional Sepolia-specific addresses.

---

### `src/Counter.sol`
**Type:** Example Contract  
**Description:** Simple counter contract example, likely used for:
- Testing Foundry setup
- Learning Solidity basics
- Template for new contracts

---

## 📁 `src/aave/` Directory

Aave integration contracts for lending, borrowing, and position management.

---

### `src/aave/AutoLooper.sol`
**Type:** Main Contract  
**Description:** Core contract that implements automated leveraged looping on Aave. Inherits from `Borrow` and `Swap`.

**Key Features:**
- **Position Opening:** `openPosition(OpenParams)` - Opens a leveraged long WETH position
  - Takes WETH as collateral
  - Borrows USDC
  - Swaps USDC → WETH
  - Resupplies WETH as more collateral
  - Repeats for specified number of loops

- **Position Unwinding:** `unwindWithUserUSDC(address recipient)` - Safely closes position
  - Repays all USDC debt
  - Withdraws all WETH collateral
  - Sends funds to recipient

- **View Functions:**
  - `getPositionData()` - Returns collateral, debt, and health factor
  - `getVariableDebt(address token)` - Gets current debt for a token

**Events:**
- `LoopStep` - Emitted for each loop iteration
- `LoopOpened` - Emitted when position is successfully opened
- `PositionUnwound` - Emitted when position is closed

**Structs:**
- `OpenParams` - Parameters for opening a position:
  - `initialCollateralWeth` - Starting WETH amount
  - `loops` - Number of loop iterations
  - `borrowBps` - Borrow percentage (basis points, e.g., 7000 = 70%)
  - `minHealthFactor` - Minimum health factor to maintain
  - `minSwapOut` - Minimum swap output (slippage protection)

---

### `src/aave/AutoLooperHelper.sol`
**Type:** Helper Contract  
**Description:** Helper contract that can be called from Reactive Network to manage AutoLooper positions.

**Key Features:**
- **Position Management:**
  - `openPositionForReactive(OpenParams)` - Opens position using WETH from owner
  - `checkAndUnwind()` - Checks health factor and unwinds if < 1.05
  - `closePosition()` - Manually closes position (safe unwind)

- **State Tracking:**
  - `isActive` - Tracks if position is currently open
  - `UNWIND_THRESHOLD_HF` - Health factor threshold (1.05) for auto-unwind

- **View Functions:**
  - `getHealthFactor()` - Gets current health factor
  - `getPositionData()` - Gets full position data including active status

**Events:**
- `PositionOpened` - Position successfully opened
- `PositionClosed` - Position closed
- `HealthFactorChecked` - Health check performed
- `PositionOpenFailed` - Position opening failed
- `UnwindFailed` - Unwind operation failed

**Purpose:** Acts as a bridge between Reactive Network callbacks and AutoLooper contract, handling token transfers and error recovery.

---

### `src/aave/Borrow.sol`
**Type:** Base Contract  
**Description:** Base contract providing Aave borrowing functionality. Used by `AutoLooper` via inheritance.

**Key Functions:**
- `supply(address token, uint256 amount)` - Supplies tokens to Aave
- `borrow(address token, uint256 amount)` - Borrows tokens from Aave (variable rate)
- `approxMaxBorrow(address token)` - Calculates approximate maximum borrowable amount
- `getHealthFactor()` - Gets current health factor from Aave
- `getVariableDebt(address token)` - Gets variable debt for a token

**Dependencies:**
- Uses Aave V3 `IPool` interface
- Uses Aave `IAaveOracle` for price feeds

---

### `src/aave/Repay.sol`
**Type:** Utility Contract  
**Description:** Contract for repaying Aave debt. Provides functionality to:
- Repay variable debt
- Handle interest calculations
- Transfer tokens from user if needed

**Key Functions:**
- `repay(address token)` - Repays all variable debt for a token
- `getVariableDebt(address token)` - Gets current debt amount

---

### `src/aave/Supply.sol`
**Type:** Utility Contract  
**Description:** Contract for supplying tokens to Aave. Provides simple interface for supplying collateral.

**Key Functions:**
- `supply(address token, uint256 amount)` - Supplies tokens to Aave pool

---

### `src/aave/Swap.sol`
**Type:** Base Contract  
**Description:** Base contract providing Uniswap V3 swap functionality. Used by `AutoLooper` via inheritance.

**Key Functions:**
- `swapExactInputSingle(...)` - Swaps exact input amount via Uniswap V3
  - Parameters: tokenIn, tokenOut, fee, amountIn, amountOutMin, recipient
  - Returns: amountOut received

**Dependencies:**
- Uses Uniswap V3 `ISwapRouter` interface
- Handles token approvals automatically

---

### `src/aave/Withdraw.sol`
**Type:** Utility Contract  
**Description:** Contract for withdrawing tokens from Aave. Provides functionality to:
- Withdraw supplied collateral
- Handle aToken balances
- Transfer tokens to recipient

**Key Functions:**
- `withdraw(address token, uint256 amount, address to)` - Withdraws tokens from Aave

---

## 📁 `src/reactive/` Directory

Reactive Network integration contracts.

---

### `src/reactive/AutoLooperReactive.sol`
**Type:** Reactive Contract  
**Description:** Reactive contract deployed on Reactive Network that monitors Chainlink price feeds and manages AutoLooper positions automatically.

**Key Features:**
- **Subscription:** Subscribes to Chainlink price feed updates on origin chain
- **Position Opening:** On first price update (or if inactive), opens position via callback
- **Health Monitoring:** On each price update, checks health factor and unwinds if < 1.05
- **State Management:** Tracks `isActive` state optimistically

**Key Functions:**
- `react(LogRecord calldata log)` - Entry point for price feed updates
  - Parses price feed data
  - Opens position if inactive
  - Checks health factor if active
  - Emits callbacks to helper contract

- `setActive(bool _active)` - Manually set active state (for testing/syncing)
- `getConfig()` - Returns all configuration parameters

**Events:**
- `Subscribed` - Successfully subscribed to price feed
- `PositionOpenInitiated` - Position opening initiated
- `HealthCheckInitiated` - Health check performed
- `PositionClosed` - Position closed
- `PositionOpenFailed` - Position opening failed

**Configuration:**
- `originFeed` - Chainlink feed address
- `originChainId` - Chain where feed is located
- `destinationChainId` - Chain where AutoLooper is deployed (Sepolia)
- `helperContract` - Helper contract address
- `autoLooper` - AutoLooper contract address
- `openParams` - Position parameters

**Inheritance:** Extends `AbstractReactive` from reactive-lib, which provides:
- Subscription service integration
- Callback system
- Payment handling
- VM detection

---

## 📁 `src/interfaces/` Directory

External contract interfaces.

---

### `src/interfaces/uniswap-v3/ISwapRouter.sol`
**Type:** Interface  
**Description:** Uniswap V3 SwapRouter interface. Defines:
- `ExactInputSingleParams` struct
- `exactInputSingle()` function signature
- Other swap function signatures

**Purpose:** Allows contracts to interact with Uniswap V3 SwapRouter02 without importing the full contract.

---

## 📁 `test/` Directory

Test files for all contracts.

---

### `test/AutoLooper.test.sol`
**Type:** Test File  
**Description:** Comprehensive tests for the `AutoLooper` contract. Tests:
- Position opening with various parameters
- Loop iterations
- Health factor calculations
- Position unwinding
- Edge cases and error conditions

**Test Functions:**
- `test_openPosition_basic()` - Basic position opening test
- `test_unwindWithUserUSDC()` - Position unwinding test
- Other integration and unit tests

---

### `test/Borrow.test.sol`
**Type:** Test File  
**Description:** Tests for the `Borrow` contract. Tests:
- Token supply functionality
- Borrowing functionality
- Max borrow calculations
- Health factor calculations
- Variable debt tracking

---

### `test/Counter.t.sol`
**Type:** Test File  
**Description:** Tests for the example `Counter` contract. Simple tests for Foundry setup verification.

---

### `test/Repay.test.sol`
**Type:** Test File  
**Description:** Tests for the `Repay` contract. Tests:
- Debt repayment functionality
- Interest calculations
- Full debt repayment
- Edge cases

---

### `test/Supply.test.sol`
**Type:** Test File  
**Description:** Tests for the `Supply` contract. Tests:
- Token supply to Aave
- aToken balance tracking
- Supply with different tokens

---

### `test/Swap.test.sol`
**Type:** Test File  
**Description:** Tests for the `Swap` contract. Tests:
- Uniswap V3 swaps
- Exact input swaps
- Slippage protection
- Token approvals
- Swap routing

---

## 📁 `lib/` Directory

**Type:** External Dependencies  
**Description:** Contains Git submodules with external libraries:
- `forge-std/` - Foundry standard library (testing utilities, cheats, etc.)
- `defi-aave-v3/` - Aave V3 course materials and interfaces
- `reactive-lib/` - Reactive Network library (interfaces and abstract contracts)

**Note:** These are managed via Git submodules and should not be edited directly.

---

## 🔗 Contract Relationships

### Inheritance Chain:
```
AutoLooper
├── Borrow (Aave operations)
│   └── Uses: IPool, IAaveOracle
└── Swap (Uniswap operations)
    └── Uses: ISwapRouter

AutoLooperHelper
└── Uses: AutoLooper, IPool

AutoLooperReactive
└── AbstractReactive (reactive-lib)
    └── Uses: IReactive, ISystemContract
```

### Data Flow:
1. **User** → `AutoLooper.openPosition()` → Opens leveraged position
2. **Reactive Network** → `AutoLooperReactive.react()` → Monitors price feeds
3. **AutoLooperReactive** → Callback → `AutoLooperHelper.checkAndUnwind()`
4. **AutoLooperHelper** → `AutoLooper.unwindWithUserUSDC()` → Closes position

---

## 📊 File Statistics

- **Total Solidity Files:** 20+
- **Test Files:** 6
- **Script Files:** 12
- **Interface Files:** 1
- **Configuration Files:** 5+

---

## 🚀 Quick Reference

### Deploy Contracts:
1. Deploy `AutoLooper` → `script/DeployAutoLooperSepolia.s.sol`
2. Deploy `AutoLooperHelper` → `script/DeployAutoLooperHelper.s.sol`
3. Deploy `AutoLooperReactive` → `script/DeployAutoLooperReactive.s.sol`

### Run Tests:
```bash
forge test                    # Run all tests
forge test -vvv              # Verbose output
forge test --match-path test/AutoLooper.test.sol
```

### Build Contracts:
```bash
forge build                  # Compile all contracts
forge build --sizes          # Show contract sizes
```

---

**Last Updated:** 2024-12-14  
**Solidity Version:** 0.8.28  
**Foundry Version:** Latest

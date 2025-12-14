# Aave AutoLooper (Reactive Auto-Leverage + Auto-Unwind)

A Reactive-powered leveraged looping strategy on top of Aave V3 that automates multi-step "looping" (supply → borrow → swap → resupply) and continuously monitors risk to safely unwind when Health Factor drops below a threshold.

This project was built for the Reactive Network bounty: Auto-Looper for a Lending Protocol.

NOTE: Before running Tests/Scripts- Make sure you have appropriate constants in the contract. Currently loaded with constant for sepolia. If you intend to run tests/scripts made for mainnet fork - use constants from the backup file. Otherwise tests and scripts will fail/Show un-intended behaviour.

![Arch Diagram](./img/Screenshot%202025-12-15%20at%2003.55.26.png "Arch Diagram")

![Flow Diagram](./img/Screenshot%202025-12-15%20at%2003.57.02.png "Flow Diagram")


## What this repo does

**Strategy: leveraged long example (WETH collateral, borrow USDC)**

When a user opts in (via scripts / demo UI), the system can:

1. Supply WETH as collateral to Aave
2. Borrow USDC against that collateral (bounded by a configurable % of max borrowing capacity)
3. Swap borrowed USDC → WETH on Uniswap V3 (slippage bounded by minOut)
4. Resupply swapped WETH back into Aave as more collateral
5. Repeat the loop N times to reach target leverage / target borrow utilization
6. Monitor Health Factor and unwind (repay + withdraw) when the position becomes unsafe


## Why Reactive Contracts here?

The core value of Reactive is automation without the user babysitting a position.

- The Reactive Contract subscribes to Chainlink price feed updates
- Every price update acts as a "heartbeat" trigger
- On each trigger, it initiates a callback to the destination chain:
  - run a health factor check
  - unwind if needed

This fulfills the bounty requirement: all orchestration is done by Reactive Contracts (the "brain" is reactive + callback). The Aave/Uniswap actions are executed on the destination chain by the destination contracts.


## Important note about testnets

This project is designed for testnet + fork development, but in practice:

- Aave testnet markets often have very low borrow liquidity and hit supply caps.
- Uniswap testnet pools often have extreme slippage due to low liquidity.

So the repo validates correctness using:

- Mainnet fork (Tenderly / local anvil fork) for realistic liquidity and swaps
- Sepolia + Foundry cheatcodes for deterministic testing

This is an external infra/liquidity constraint, not a missing logic constraint.


## Repo layout

UI exists in `ui/` but is intentionally not the focus here.

### High-level tree

```
aave-autoloop/
├── .env
├── .gitignore
├── .gitmodules
├── foundry.lock
├── foundry.toml
├── README.md
├── .github/
│   └── workflows/
│       └── test.yml
├── broadcast/
├── img/
├── lib/
├── script/
└── src/
    ├── Constants.sol
    ├── Constants.sol.mainnet.backup
    ├── ConstantsSepolia.sol
    ├── interfaces/
    │   └── uniswap-v3/
    │       └── ISwapRouter.sol
    ├── aave/
    │   ├── AutoLooper.sol
    │   ├── AutoLooperHelper.sol
    │   ├── Borrow.sol
    │   ├── Repay.sol
    │   ├── Supply.sol
    │   ├── Swap.sol
    │   └── Withdraw.sol
    └── reactive/
        └── AutoLooperReactive.sol
└── test/
    ├── AutoLooper.test.sol
    ├── Borrow.test.sol
    ├── Repay.test.sol
    ├── Supply.test.sol
    ├── Swap.test.sol
    └── Counter.t.sol
```

### Core contracts

#### `src/Constants.sol`

Single source of truth for addresses used by the contracts. This contains:

- Token addresses (WETH / USDC / USDT / DAI)
- Aave V3 Pool + Oracle
- Uniswap V3 Router and fee tiers

You can swap between Sepolia vs Mainnet configs by changing this file (or using `ConstantsSepolia.sol` / backup).

⸻

### Aave building blocks (`src/aave/`)

These are minimal wrappers for Aave actions and are used as building blocks:

**Borrow.sol**
- `supply(token, amount)`
- `borrow(token, amount)` (variable rate)
- `approxMaxBorrow(token)` (uses Aave Oracle + account data)
- `getHealthFactor()`
- `getVariableDebt(token)`

**Supply.sol**
- `supply(token, amount)`
- `getSupplyBalance(token)` via aToken

**Withdraw.sol**
- `withdraw(token, amount)` (withdraws from Aave into the contract)

**Repay.sol**
- `repay(token)` repays all variable debt using `type(uint256).max`


### Uniswap building block (`src/aave/Swap.sol`)

- `swapExactInputSingle(tokenIn, tokenOut, fee, amountIn, minOut, recipient)`
- Uses Uniswap V3 SwapRouter02 `exactInputSingle` flow
- Slippage protection via `amountOutMinimum`

Note: interface compatibility matters here; using the wrong router params (e.g., adding deadline incorrectly) causes reverts.


### Strategy contract (`src/aave/AutoLooper.sol`)

This is the main looping strategy contract.

**Open**
`openPosition(OpenParams)`:
- pulls WETH from user
- supplies to Aave
- for loops iterations:
  - compute max borrowable USDC
  - borrow a fraction (`borrowBps`) of max
  - swap borrowed USDC → WETH
  - resupply WETH
  - check health factor >= `minHealthFactor`

**Unwind**
`unwindWithUserUSDC(recipient)` (current version):
- repays all USDC debt (using USDC made available/approved)
- withdraws all collateral
- sends proceeds to recipient

This unwind design is simple for test/fork demos: you can "top up" USDC for repayment. In production, you'd likely swap collateral → USDC to repay debt without requiring extra user USDC (depends on liquidity/market conditions).


### Reactive integration helper (`src/aave/AutoLooperHelper.sol`)

This helper exists because Reactive callbacks should call a controlled entrypoint.

Typical responsibilities:
- open a position on behalf of an owner / controlled account
- check health factor
- unwind if below threshold
- emit structured events for UI/debugging

This contract is the "destination callback target" called by the Reactive system.

The helper checks health factor on each callback and unwinds if it drops below `UNWIND_THRESHOLD_HF` (currently set to 1.05e18). It manages the `isActive` flag to prevent duplicate opens and tracks position state.


### Reactive contract (`src/reactive/AutoLooperReactive.sol`)

Deployed on Reactive (Lasna). It:

- subscribes to a Chainlink feed event (origin chain)
- on each price update:
  - triggers a callback to destination chain (Sepolia) targeting `AutoLooperHelper`
  - helper checks HF and unwinds if unsafe

The design goal:
- reactive contract is the automation brain
- destination contracts are the execution surface for Aave/Uniswap

On the first price feed update after deployment, it opens a position. On subsequent updates, it triggers health checks. The contract subscribes to the `AnswerUpdated` event (topic 0: `0x0559884fd3a460db3073b7fc896cc77986f16e378210ded43186175bf646fc5f`) from the Chainlink aggregator.


### Scripts (`script/`)

These are Foundry scripts to deploy and validate flows:

- **DeployAutoLooperSepolia.s.sol** - Deploy AutoLooper to Sepolia.
- **DeployAutoLooperHelper.s.sol** - Deploy helper contract; configure owner/recipient.
- **DeployAutoLooperReactive.s.sol** - Deploy Reactive contract (Lasna). Config includes origin feed / origin chain / destination chain / helper / open params.
- **SimulateAutoLoop.s.sol** - Runs an end-to-end loop + unwind on a fork (recommended for demos).
- **Utility scripts:**
  - `SwapUSDTToUSDCAndSupply.s.sol`
  - `SupplyUSDCToAave.s.sol`
  - `CheckBalances.s.sol`
  - etc.


## Setup

### Requirements

- Foundry installed (`forge`, `cast`, `anvil`)
- Git submodules pulled (`forge-std`, `defi-aave-v3`, `reactive-lib`)

### Install

```bash
git clone --recurse-submodules <your-repo-url>
cd aave-autoloop
forge build
```

If you already cloned without submodules:

```bash
git submodule update --init --recursive
```

### Environment variables (`.env`)

Example `.env` (adjust to your needs):

```bash
# Mainnet fork URL (Alchemy/Infura/Tenderly/your node)
FORK_URL="https://..."

# Sepolia
SEPOLIA_RPC_URL="https://..."
PRIVATE_KEY="0x..."

# Reactive / Lasna
REACTIVE_RPC="https://lasna-rpc.rnk.dev/"
REACTIVE_PRIVATE_KEY="0x..."

# Chainlink feed configuration (origin chain for reactive subscription)
ORIGIN_CHAIN_ID="84532"           # example: Base Sepolia
ORIGIN_FEED="0x..."               # chainlink aggregator address on origin chain

# Destination chain (where AutoLooperHelper lives)
DESTINATION_CHAIN_ID="11155111"   # Sepolia
```

## Running tests (recommended path)

### 1) Run all tests on a fork

```bash
forge test --fork-url $FORK_URL -vvv
```

### 2) Run a specific test file

```bash
forge test --fork-url $FORK_URL --match-path test/AutoLooper.test.sol -vvv
forge test --fork-url $FORK_URL --match-path test/Swap.test.sol -vvv
```

### 3) Make tests reproducible (pin fork block)

```bash
FORK_BLOCK=$(cast block-number --rpc-url $FORK_URL)
forge test --fork-url $FORK_URL --fork-block-number $FORK_BLOCK -vvv
```


## Running the end-to-end simulation (fork)

This is the best "judge demo" path because it uses mainnet liquidity.

```bash
forge script script/SimulateAutoLoop.s.sol:SimulateAutoLoop \
  --fork-url $FORK_URL \
  -vv
```

Expected behavior:
- deploy AutoLooper
- deal WETH to user on fork
- approve + open a looped position
- print collateral, debt, HF
- "fund" USDC for repay (fork-only convenience)
- unwind
- confirm collateral/debt reset to 0


## Deploying to Sepolia (optional)

Because public testnet liquidity can be bad, this may not always succeed end-to-end, but deployment works.

```bash
forge script script/DeployAutoLooperSepolia.s.sol:DeployAutoLooperSepolia \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

Deploy helper:

```bash
forge script script/DeployAutoLooperHelper.s.sol:DeployAutoLooperHelper \
  --rpc-url $SEPOLIA_RPC_URL \
  --broadcast
```

Deploy reactive:

```bash
forge script script/DeployAutoLooperReactive.s.sol:DeployAutoLooperReactive \
  --rpc-url $REACTIVE_RPC \
  --broadcast
```


## CI (GitHub Actions)

`.github/workflows/test.yml` runs:

- `forge fmt --check`
- `forge build`
- `forge test -vvv`

If you don't want formatting to gate CI, remove `forge fmt --check` from the workflow.


## Known limitations / caveats

1. Testnet liquidity can block borrow/swap loops.
2. Swap slippage on testnets can be unrealistically high.
3. Unwind funding model: current unwind function expects repay liquidity (USDC) to be available/approved.
   - In production, you'd likely swap collateral → debt asset to self-repay.
4. Reactive connectivity constraints: Reactive Lasna supports specific testnet chains; destination/origin must be compatible.


## Security notes

Reactive contracts should never expose arbitrary external execution. Best practice is:

- Reactive → CallbackProxy → Helper entrypoint only
- Helper should restrict sensitive actions via:
  - `onlyCallbackProxy` / `authorizedSenderOnly` style checks
  - allowlisted reactive sender (`rvmIdOnly` pattern)

If you're reviewing security: check `AutoLooperHelper.sol` for the callback authorization logic.

The current implementation allows any caller to invoke `openPositionForReactive` and `checkAndUnwind`. In production, you should add access controls to restrict these functions to only be callable from the Reactive callback proxy or an authorized sender.


## Credits

- Aave interactions inspired by / based on Cyfrin educational building blocks.
- Reactive integration uses `reactive-lib`.
- Swaps use Uniswap V3 SwapRouter02 interface.


## Deploying with .load files

- Open AOS and create/select a process.
- Run one of the loads under `contracts/loads/`:
  - `.load contracts/loads/mock-usda.load`
  - `.load contracts/loads/lock-manager.load`
  - `.load contracts/loads/token-manager.load`
  - `.load contracts/loads/state-manager.load`
  - `.load contracts/loads/coordinator.load`
- Copy the printed PIDs and update them in:
  - `contracts/scripts/configure-integration.lua`
  - `contracts/scripts/verify-e2e.lua`
  - `contracts/verify/verify-processes.sh`

Then:
-  to confirm reachability
- `aos --load contracts/scripts/verify-e2e.lua` for the end-to-end flow

# TIM3 - Collateralized Token on Arweave AO

TIM3 is a 1:1 USDA-backed token built on Arweave's AO network. Users lock USDA as collateral and receive TIM3 tokens that maintain their value through full backing.

## 🏗️ Architecture

### Multi-Process System
- **TIM3 Coordinator**: Main orchestrator for user interactions
- **Lock Manager**: Handles USDA collateral locking/unlocking
- **Token Manager**: Manages TIM3 minting and burning
- **State Manager**: Tracks collateral ratios and system state
- **Mock USDA**: Development token for testing (replaced with real USDA in production)

### Process Communication Flow
```
User → Frontend → Coordinator → Specialized Processes → User's Wallet
```

## 🚀 Quick Start

### Development Setup
```bash
# Install dependencies
npm install

# Build all AO processes
npm run ao:build

# Run comprehensive tests
npm run ao:test

# Start frontend development server
npm run dev
```

### Testing Individual Processes
```bash
# Test specific components
npm run coordinator:test
npm run lock-manager:test
npm run token-manager:test
npm run state-manager:test
```

### Deployment
```bash
# Deploy all processes to AO network
npm run ao:deploy
```

## 🔧 Development Workflow

1. **Process Development**: Write Lua processes in `ao/*/src/process.lua`
2. **Testing**: Create comprehensive tests in `ao/*/test/`
3. **Building**: Use Docker-based Lua squishing for deployment builds
4. **Frontend**: React app with Wander wallet integration

## 🔐 Security Features

- **1:1 USDA Backing**: Every TIM3 token backed by locked USDA
- **Process Separation**: Isolated processes for enhanced security
- **State Validation**: Continuous verification of collateral ratios
- **Comprehensive Testing**: Three-layer testing strategy

## 📁 Project Structure

```
apps/tim3/
├── ao/                      # AO Processes
│   ├── coordinator/         # Main orchestrator
│   ├── lock-manager/        # USDA collateral management
│   ├── token-manager/       # TIM3 token operations
│   ├── state-manager/       # System state tracking
│   └── mock-usda/           # Development USDA token
├── src/                     # React frontend
├── scripts/                 # Build and deployment scripts
├── aoform.yaml             # AO deployment configuration
└── package.json            # Dependencies and build scripts
```

## 🌟 Key Features

- **Full Backing**: 1:1 USDA backing ensures stable value
- **Wander Wallet Integration**: Seamless AO-native wallet experience  
- **Autonomous Operation**: Self-managing collateral system
- **Permanent Storage**: Built on Arweave's permanent infrastructure
- **Battle-Tested Architecture**: Based on Autonomous Finance patterns

## 🔗 Integration

TIM3 is designed to integrate with the broader AO DeFi ecosystem:
- **Botega**: Professional AMM and liquidity pools
- **S3ARCH**: Part of the broader search and discovery platform
- **ArNS**: Human-readable domain access

## ✅ Current Status

**Backend Complete**: All 5 AO processes implemented and tested
- Coordinator: 18/18 tests ✅
- Lock Manager: 12/12 tests ✅  
- Token Manager: 17/17 tests ✅
- State Manager: 11/11 tests ✅
- Mock USDA: 25/25 tests ✅

**Next Phase**: Frontend development with Wander wallet integration

---

**Built with security, permanence, and decentralization at its core.**

## AOS Quick Verify

- Check deployed test processes are reachable:
  - 

## End-to-End Verify (USDA → TIM3)

This runs a mint flow against deployed TEST processes.

- Run once:
  - `aos --load contracts/scripts/verify-e2e.lua`

What it does:
- Applies the Lock Manager transfer-based fix (so user transfers USDA, then mint proceeds)
- Configures Coordinator/State/Lock/Token managers with the correct PIDs
- Mints 5 Mock USDA to your session (`ao.id`)
- Requests mint of 5 TIM3 via the Coordinator
- Transfers 5 Mock USDA to the Lock Manager (credit notice triggers mint)
- Queries and prints your TIM3 balance

Notes:
- If PIDs change, update them at the top of `contracts/scripts/verify-e2e.lua`.
- If any step fails, re-run once after ~10s to allow messages to settle.


## Start Here

- Project status and Next Steps: `docs/STATUS.md`
- Agent handoff protocol: `docs/HANDOFF.md`
- Current PIDs (TEST/PROD): `docs/PIDs.md`



## Start Here

- Project status and Next Steps: `docs/STATUS.md`
- Agent handoff protocol: `docs/HANDOFF.md`
- Current PIDs (TEST/PROD): `docs/PIDs.md`

## PID Sync Helper

After (re)deploying processes and updating `docs/PIDs.md`, you can sync PIDs into the code with:

```bash
python3 tools/update_pids.py --env TEST
```

Then review with `git diff` and commit.

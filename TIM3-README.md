# TIM3 - USDA Collateralized Token on AO

## 🎯 Overview
TIM3 is a 1:1 USDA-backed token on the AO network. Users can swap USDA for TIM3 tokens and burn TIM3 to get USDA back.

## 🚀 Quick Start

### Deploy in 30 Seconds
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3
./deploy-production.sh
```

Or manually:
```bash
aos tim3 --load tim3-swap-contract.lua
```

### In AOS Terminal
```lua
-- Quick test
.load tim3-quickstart.lua
quickTest()

-- Get your process ID (save this!)
ao.id
```

## 📦 Files Included

| File | Purpose | Usage |
|------|---------|-------|
| `tim3-deploy.load` | Main contract (AOS-ready) | Deploy with `aos --load` |
| `tim3-quickstart.load` | Quick setup & test | Load first after deployment |
| `tim3-helpers.load` | Operation functions | Daily operations |
| `tim3-test-suite.load` | Complete test suite | Testing all functions |
| `tim3-monitor.load` | Live dashboard | Monitoring & stats |
| `deploy-production.sh` | Deployment script | Automated deployment |

## 🔧 Step-by-Step Usage

### 1️⃣ Deploy Contract
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3
aos tim3-mainnet --load tim3-deploy.load
```

### 2️⃣ Verify Deployment
```lua
-- In AOS
ao.id  -- Save this ID!
Name   -- Should show "TIM3"
Ticker -- Should show "TIM3"
```

### 3️⃣ Load Helpers
```lua
.load tim3-quickstart.load
quickTest()  -- Verify everything works
```

### 4️⃣ Test Swap Function
```lua
-- Simulate receiving USDA
simulateSwap()

-- Check stats
getStats()
```

## 💼 Operations Guide

### For Users

**Swap USDA → TIM3:**
```lua
.load tim3-helpers.load
swapUsdaForTim3("1000000")  -- Swap 1 USDA
```

**Burn TIM3 → USDA:**
```lua
burnTim3ForUsda("1000000")  -- Burn 1 TIM3
```

**Check Balance:**
```lua
checkMyBalance()
```

### For Monitoring

**Start Dashboard:**
```lua
.load tim3-monitor.load
showDashboard()     -- One-time view
startMonitor()      -- Continuous monitoring
```

**Quick Stats:**
```lua
quickStats()
```

## 🧪 Testing

### Run Full Test Suite
```lua
.load tim3-test-suite.load
runAllTests()
```

### Individual Tests
```lua
testInfo()
testBalance()
testStats()
simulateUsdaDeposit("user_address", "1000000")
testBurn("user_address", "500000")
```

## 🔗 Integration

### Frontend/Wallet Integration

**Process IDs:**
- TIM3: `[YOUR_DEPLOYED_PROCESS_ID]`
- USDA: `FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8`

**Swap USDA for TIM3:**
```javascript
await ao.send({
    process: "USDA_PROCESS_ID",
    action: "Transfer",
    tags: {
        Recipient: "TIM3_PROCESS_ID",
        Quantity: amount
    }
})
```

**Burn TIM3 for USDA:**
```javascript
await ao.send({
    process: "TIM3_PROCESS_ID",
    action: "Transfer",
    tags: {
        Recipient: "burn",
        Quantity: amount
    }
})
```

## 📊 Contract Handlers

| Handler | Action | Description |
|---------|--------|-------------|
| Info | `Info` | Get contract details |
| Balance | `Balance` | Query user balance |
| Transfer | `Transfer` | Transfer or burn TIM3 |
| Credit-Notice | `Credit-Notice` | Receive USDA (auto-mint TIM3) |
| Stats | `Stats` | Get statistics |
| Balances | `Balances` | Get all balances |

## 🏗️ Architecture

```
User → Transfer USDA → TIM3 Contract
                         ↓
                    Mint TIM3 1:1
                         ↓
                    User receives TIM3

User → Burn TIM3 → TIM3 Contract
                      ↓
                 Release USDA 1:1
                      ↓
                User receives USDA
```

## ⚡ Commands Cheatsheet

```lua
-- Deployment
aos tim3 --load tim3-deploy.load

-- Quick start
.load tim3-quickstart.load
quickTest()

-- Operations
.load tim3-helpers.load
swapUsdaForTim3("1000000")
burnTim3ForUsda("1000000")
checkMyBalance()
transferTim3("recipient", "500000")

-- Monitoring
.load tim3-monitor.load
showDashboard()
startMonitor()
quickStats()

-- Testing
.load tim3-test-suite.load
runAllTests()
```

## 🔒 Security

- ✅ 1:1 collateral ratio enforced
- ✅ Only accepts USDA from official process
- ✅ Atomic operations (no intermediate states)
- ✅ Standard AO token compliance

## 📈 Performance

- Single process architecture
- No inter-process communication delays
- Instant swaps and burns
- Gas-efficient operations

## 🆘 Troubleshooting

**Contract not responding?**
```lua
-- Check process is alive
ao.id
Send({Target = ao.id, Action = "Info"})
```

**Balance not updating?**
```lua
-- Force refresh
Send({Target = ao.id, Action = "Balances"})
json.decode(Inbox[#Inbox].Data)
```

**Need to restart?**
```bash
# Exit AOS (Ctrl+C)
# Reconnect
aos tim3
.load tim3-deploy.load
```

## 🎉 Success Checklist

- [ ] Contract deployed with `aos --load tim3-deploy.load`
- [ ] Process ID saved
- [ ] `quickTest()` passes
- [ ] Can receive USDA transfers
- [ ] Can mint TIM3 1:1
- [ ] Can burn TIM3 for USDA
- [ ] Monitoring dashboard works
- [ ] All tests pass

## 📞 Support

1. Check dashboard: `.load tim3-monitor.load` → `showDashboard()`
2. Run tests: `.load tim3-test-suite.load` → `runAllTests()`
3. Review logs: `Inbox[#Inbox]`
4. Check this guide: `DEPLOYMENT-GUIDE.md`

## 🚀 Ready to Deploy!

Everything is prepared and tested. Follow the Quick Start above to deploy your TIM3 contract.

**Production USDA Process:** `FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8`

---

Built with 💙 for the AO Network
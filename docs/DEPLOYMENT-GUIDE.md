# TIM3 Complete Deployment Guide

## 📁 Directory Structure
```
/Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/
├── tim3-swap-contract.lua   # Main AOS contract file
├── tim3-test-suite.lua      # Comprehensive test suite  
├── tim3-helpers.lua         # Helper functions for operations
├── tim3-monitor.lua         # Monitoring dashboard
├── DEPLOYMENT-GUIDE.md      # This guide
└── deploy-production.sh     # Deployment script
```

## 🚀 Step-by-Step Deployment

### Step 1: Open Terminal and Navigate
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3
```

### Step 2: Start AOS with the Contract
```bash
aos tim3-process --load tim3-swap-contract.lua
```

### Step 3: Verify Deployment
Once in AOS, run these commands to verify:
```lua
-- Check process ID
ao.id

-- Verify contract loaded
Name
Ticker
print("USDA Process: " .. USDA_PROCESS_ID)
```

### Step 4: Test Basic Functions
```lua
-- Test Info endpoint
Send({Target = ao.id, Action = "Info"})
Inbox[#Inbox].Data

-- Test Balance endpoint  
Send({Target = ao.id, Action = "Balance"})
Inbox[#Inbox].Data

-- Test Stats endpoint
Send({Target = ao.id, Action = "Stats"})
Inbox[#Inbox].Data
```

## 🧪 Running Tests

### Option 1: Load Test Suite in Same Process
```lua
.load tim3-test-suite.lua
runAllTests()
```

### Option 2: Test from Another Process
```bash
# In a new terminal
aos test-runner
```

Then in the test-runner AOS:
```lua
json = require('json')
TIM3_PROCESS = "YOUR_TIM3_PROCESS_ID_HERE"

-- Load the test helpers
.load tim3-test-suite.lua

-- Run tests
runAllTests()
```

## 🛠️ Using Helper Functions

### Load Helpers in Your AOS Session
```lua
.load tim3-helpers.lua
```

### Available Commands
```lua
-- Swap USDA for TIM3
swapUsdaForTim3("1000000")  -- Swaps 1 USDA

-- Burn TIM3 for USDA
burnTim3ForUsda("500000")   -- Burns 0.5 TIM3

-- Check balances
checkMyBalance()
checkUserBalance("user_address")
checkMyUsdaBalance()

-- Transfer TIM3
transferTim3("recipient_address", "100000")

-- Get contract info
getContractInfo()
getStats()
getAllBalances()
```

## 📊 Monitoring Dashboard

### Start Monitoring
```lua
.load tim3-monitor.lua

-- Show dashboard once
showDashboard()

-- Start continuous monitoring
startMonitor()

-- Stop monitoring
stopMonitor()

-- Quick stats
quickStats()
```

## 🔄 Integration Testing

### Test USDA to TIM3 Swap
```lua
-- Simulate receiving USDA (for testing)
Send({
    Target = ao.id,
    From = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8",
    Action = "Credit-Notice",
    Data = json.encode({
        Sender = ao.id,
        Quantity = "1000000"
    })
})

-- Check if TIM3 was minted
Send({Target = ao.id, Action = "Balance"})
Inbox[#Inbox].Data
```

### Test TIM3 Burn
```lua
-- Burn TIM3 to get USDA back
Send({
    Target = ao.id,
    Action = "Transfer",
    Tags = {
        Recipient = "burn",
        Quantity = "500000"
    }
})

-- Check response
Inbox[#Inbox]
```

## 🔗 Production Integration

### For Wander Wallet Integration
1. Deploy contract and note the process ID
2. Configure Wander Wallet with:
   - TIM3 Process ID: `[YOUR_DEPLOYED_PROCESS_ID]`
   - Token Symbol: `TIM3`
   - Decimals: `6`

### For Frontend Integration
```javascript
// Send USDA to get TIM3
await sendMessage({
    process: USDA_PROCESS_ID,
    action: "Transfer",
    tags: {
        Recipient: TIM3_PROCESS_ID,
        Quantity: amount
    }
});

// Burn TIM3 to get USDA
await sendMessage({
    process: TIM3_PROCESS_ID,
    action: "Transfer",
    tags: {
        Recipient: "burn",
        Quantity: amount
    }
});
```

## 📝 Important Process IDs

- **Production USDA**: `FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8`
- **Your TIM3 Process**: `[Will be shown after deployment]`

## 🐛 Troubleshooting

### Issue: Contract not loading
```lua
-- Ensure json is loaded
json = require('json')

-- Reload contract
.load tim3-deploy.load
```

### Issue: No response from handlers
```lua
-- Check inbox
#Inbox

-- View last message
Inbox[#Inbox]

-- Clear inbox if needed
Inbox = {}
```

### Issue: Balance not updating
```lua
-- Check balances directly
Send({Target = ao.id, Action = "Balances"})
json.decode(Inbox[#Inbox].Data)
```

## 🔐 Security Checks

Before production:
1. Verify USDA_PROCESS_ID is correct
2. Test all swap scenarios
3. Verify collateral ratio stays 1:1
4. Test edge cases (0 amounts, overflow)
5. Verify burn mechanism works correctly

## 📞 Quick Commands Reference

```bash
# Deploy new instance
aos tim3-new --load tim3-deploy.load

# Connect to existing
aos tim3-existing

# Load in existing session
.load tim3-deploy.load
.load tim3-helpers.load
.load tim3-monitor.load
```

## ✅ Deployment Checklist

- [ ] Navigate to correct directory
- [ ] Deploy contract with aos --load
- [ ] Note down process ID
- [ ] Verify contract info
- [ ] Run test suite
- [ ] Test swap functionality
- [ ] Test burn functionality
- [ ] Set up monitoring
- [ ] Configure frontend/wallet
- [ ] Document process ID

## 🎉 Success Indicators

✅ Contract responds to Info, Balance, Stats
✅ Can receive USDA via Credit-Notice
✅ Mints TIM3 1:1 with USDA received
✅ Burns TIM3 and returns USDA
✅ Maintains correct collateral ratio
✅ All tests pass

---

**Ready for Production! 🚀**

For support or issues, check the contract state with:
```lua
.load tim3-monitor.load
showDashboard()
```
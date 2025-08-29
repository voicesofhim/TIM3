# TIM3 System Integration Guide

**Status**: All 5 processes deployed to AOS ✅  
**Phase**: Inter-Process Communication & Integration Testing  
**Date**: January 28, 2025

## 🎯 Overview

This guide walks you through configuring inter-process communication and testing the complete TIM3 system integration on live AOS network.

## 📋 Pre-Deployment Checklist ✅

- [x] Mock-USDA deployed: `u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ`
- [x] TIM3 Coordinator deployed: `DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw`
- [x] State Manager deployed: `K2FjwiTmncglx0pISNMft5-SngxW-HUjs9sctzmXtU4`
- [x] Lock Manager deployed: `MWxRVsCDoSzQ0MhG4_BWkYs0fhcULB-OO3f2t1RlBAs`
- [x] Token Manager deployed: `BUhWwGfuD1GUHVIIWF_Jhm1mfcyAYHOJS6W90ur2Bb0`
- [x] All processes respond to Info actions
- [x] JSON compatibility confirmed

## 🚀 Phase 1: Configure Inter-Process Communication

### Step 1: Start AOS Session
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3
aos tim3-integration
```

### Step 2: Load Integration Script
```lua
-- Essential compatibility fix
json = require('json')

-- Load the integration configuration script
.load /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/scripts/configure-integration.lua
```

### Step 3: Configure All Processes
```lua
-- This will configure all process IDs across the entire system
configureAllProcesses()

-- Check responses
Inbox[#Inbox]
```

### Step 4: Verify Configuration
```lua
-- Test communication between all processes
testSystemCommunication()

-- Check responses
Inbox[#Inbox]

-- Check system health
checkSystemHealth()

-- Check responses  
Inbox[#Inbox]
```

## 🧪 Phase 2: End-to-End Integration Testing

### Test 1: Complete Minting Flow (USDA → TIM3)

**Objective**: Test complete flow from USDA locking to TIM3 minting

```lua
-- Ensure you have USDA balance first
Send({ Target = "u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ", Action = "Balance" })

-- If balance is 0, mint some USDA for testing
Send({ Target = "u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ", Action = "Mint", Amount = "100" })

-- Test the complete minting flow
testMintingFlow()

-- Monitor progress (check multiple times)
Inbox[#Inbox]
```

**Expected Flow**:
1. Coordinator receives MintTIM3 request
2. Coordinator requests USDA lock from Lock Manager
3. Lock Manager requests USDA lock from Mock-USDA
4. Mock-USDA confirms lock
5. Lock Manager confirms to Coordinator
6. Coordinator requests TIM3 mint from Token Manager
7. Token Manager mints TIM3 and confirms
8. Coordinator updates user position
9. User receives TIM3 tokens

### Test 2: Complete Redemption Flow (TIM3 → USDA)

**Objective**: Test complete flow from TIM3 burning to USDA unlocking

```lua
-- Test the complete redemption flow
testRedemptionFlow()

-- Monitor progress (check multiple times)
Inbox[#Inbox]
```

**Expected Flow**:
1. Coordinator receives BurnTIM3 request
2. Coordinator requests TIM3 burn from Token Manager
3. Token Manager burns TIM3 and confirms
4. Coordinator requests USDA unlock from Lock Manager  
5. Lock Manager requests USDA unlock from Mock-USDA
6. Mock-USDA confirms unlock
7. Lock Manager confirms to Coordinator
8. Coordinator updates user position
9. User receives unlocked USDA

### Test 3: System State Consistency

```lua
-- Check coordinator state
Send({ Target = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw", Action = "GetPosition" })

-- Check state manager state
Send({ Target = "K2FjwiTmncglx0pISNMft5-SngxW-HUjs9sctzmXtU4", Action = "SystemHealth" })

-- Check lock manager state
Send({ Target = "MWxRVsCDoSzQ0MhG4_BWkYs0fhcULB-OO3f2t1RlBAs", Action = "LockStats" })

-- Check token manager state
Send({ Target = "BUhWwGfuD1GUHVIIWF_Jhm1mfcyAYHOJS6W90ur2Bb0", Action = "TokenStats" })

-- Check all responses
Inbox[#Inbox]
```

## 🔧 Phase 3: Advanced Testing

### Test 4: Error Handling & Edge Cases

```lua
-- Test invalid mint amount
Send({ Target = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw", Action = "MintTIM3", Tags = { Amount = "0" } })

-- Test insufficient collateral
Send({ Target = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw", Action = "BurnTIM3", Tags = { Amount = "1000" } })

-- Check error responses
Inbox[#Inbox]
```

### Test 5: Circuit Breaker Testing

```lua
-- Test large mint (should trigger circuit breaker)
Send({ Target = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw", Action = "MintTIM3", Tags = { Amount = "2000" } })

-- Check circuit breaker response
Inbox[#Inbox]
```

### Test 6: Timeout Testing

```lua
-- Test operation cleanup
Send({ Target = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw", Action = "CleanupExpired" })

-- Check cleanup results
Inbox[#Inbox]
```

## 📊 Success Criteria Validation

### ✅ Configuration Success Indicators
- [ ] All processes configured with correct Process IDs
- [ ] All processes respond to Info requests
- [ ] No configuration errors in Inbox

### ✅ Minting Flow Success Indicators
- [ ] USDA successfully locked by Lock Manager
- [ ] TIM3 successfully minted by Token Manager
- [ ] User position correctly updated in Coordinator
- [ ] State Manager reflects new collateral and supply
- [ ] 1:1 backing ratio maintained

### ✅ Redemption Flow Success Indicators  
- [ ] TIM3 successfully burned by Token Manager
- [ ] USDA successfully unlocked by Lock Manager
- [ ] User position correctly updated in Coordinator
- [ ] State Manager reflects reduced collateral and supply
- [ ] 1:1 backing ratio maintained

### ✅ System Health Indicators
- [ ] Global collateral ratio = 1.0 (100% backing)
- [ ] Total TIM3 supply matches total collateral
- [ ] No undercollateralized positions
- [ ] All processes report healthy status

## 🚨 Troubleshooting

### Common Issues

**Issue**: Configuration messages not received
```lua
-- Check if process is responding
Send({ Target = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw", Action = "Info" })
Inbox[#Inbox]
```

**Issue**: Minting flow stalls
```lua
-- Check coordinator pending operations
Send({ Target = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw", Action = "SystemHealth" })
Inbox[#Inbox]
```

**Issue**: State inconsistency
```lua
-- Force state update
Send({ Target = "K2FjwiTmncglx0pISNMft5-SngxW-HUjs9sctzmXtU4", Action = "SystemHealth" })
Inbox[#Inbox]
```

## 📈 Performance Monitoring

### Key Metrics to Track
- **Latency**: Time from mint request to completion
- **Throughput**: Operations per minute
- **Error Rate**: Failed operations percentage  
- **State Consistency**: Cross-process state alignment

### Monitoring Commands
```lua
-- System overview
checkSystemHealth()

-- Detailed statistics
Send({ Target = "BUhWwGfuD1GUHVIIWF_Jhm1mfcyAYHOJS6W90ur2Bb0", Action = "TokenStats" })
Send({ Target = "MWxRVsCDoSzQ0MhG4_BWkYs0fhcULB-OO3f2t1RlBAs", Action = "LockStats" })
```

## 🎉 Integration Completion

Once all tests pass successfully:

1. **Document Results**: Update STATUS.md with integration results
2. **Performance Baseline**: Record baseline performance metrics
3. **Security Audit**: Verify all security features working
4. **Frontend Integration**: Ready to connect React frontend
5. **Production Preparation**: Plan transition from Mock-USDA to real USDA

---

**Next Phase**: Frontend Development with Wander Wallet Integration

**Current Status**: 95% → 98% Complete (Integration Phase)

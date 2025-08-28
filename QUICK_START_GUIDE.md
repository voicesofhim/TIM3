# TIM3 Quick Start Guide for New Sessions

**Last Updated**: January 28, 2025  
**Status**: Mock-USDA successfully deployed and tested on AOS

## 🎯 **Current State Summary**
- ✅ Mock-USDA process deployed to AOS (Process ID: `u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ`)
- ✅ All core functionality tested: Info, Balance, Mint operations
- ✅ 1000 mUSDT successfully minted and tracked
- 🔄 Next: Deploy remaining TIM3 processes (Coordinator, State Manager, Lock Manager, Token Manager)

## 🚨 **Critical AOS Deployment Process (TESTED & WORKING)**

### **Step 1: Navigate to Process Directory**
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/[process-name]
```

### **Step 2: Start AOS with Named Process**
```bash
aos [process-name]-test
```
*Example: `aos mock-usda-test`*

### **Step 3: Fix JSON Compatibility (CRITICAL!)**
```lua
json = require('json')
```
**⚠️ MUST RUN THIS FIRST - AOS doesn't have global `json` object**

### **Step 4: Load Process Code**
```lua
.load /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/[process-name]/build/process.lua
```
**⚠️ MUST USE ABSOLUTE PATH - relative paths fail**

### **Step 5: Test Functionality**
```lua
-- Check process info
Send({ Target = ao.id, Action = "Info" })

-- Check responses
Inbox[#Inbox]
```

## 🏗️ **Project Structure Understanding**

### **File Hierarchy (Per Process)**
```
ao/[process-name]/
├── src/process.lua          # Development code (edit here)
├── build/process.lua        # Production code (deployed to AOS)
├── test/
│   ├── [name]_spec.lua     # Test suite
│   └── mock_ao.lua         # AOS simulation
└── squishy                 # Build configuration
```

### **Build Process**
```bash
# From process directory
node ../../scripts/build-process.cjs .
```
*Builds src/process.lua → build/process.lua*

### **Deployment Configuration**
- **File**: `processes.yaml` (contains all process deployment configs)
- **Contains**: Module IDs, Scheduler IDs, Tags for each process

## 🎯 **Next Immediate Actions**

### **1. Deploy Coordinator Process**
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/coordinator
aos coordinator-test
json = require('json')
.load /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/coordinator/build/process.lua
```

### **2. Deploy State Manager Process**
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/state-manager
aos state-manager-test
json = require('json')
.load /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/state-manager/build/process.lua
```

### **3. Deploy Lock Manager Process**
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/lock-manager
aos lock-manager-test
json = require('json')
.load /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/lock-manager/build/process.lua
```

### **4. Deploy Token Manager Process**
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/token-manager
aos token-manager-test
json = require('json')
.load /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3/ao/token-manager/build/process.lua
```

## 🧪 **Testing Each Process**

### **Standard Test Sequence**
```lua
-- 1. Check process info
Send({ Target = ao.id, Action = "Info" })

-- 2. Check responses
Inbox[#Inbox]

-- 3. Process-specific tests (varies by process)
-- For Mock-USDA: Mint, Balance, Transfer
-- For Coordinator: Configure, Mint, Burn
-- For State Manager: Set, Get state
-- etc.
```

## 📝 **Key Process IDs (Update as you deploy)**
- **Mock-USDA**: `u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ` ✅
- **Coordinator**: `[TO BE DEPLOYED]`
- **State Manager**: `[TO BE DEPLOYED]`
- **Lock Manager**: `[TO BE DEPLOYED]`
- **Token Manager**: `[TO BE DEPLOYED]`

## ⚡ **Common Issues & Solutions**

### **"file not found" Error**
- **Cause**: Using relative path
- **Fix**: Use absolute path with `.load`

### **"attempt to index nil value (global 'json')" Error**
- **Cause**: AOS doesn't have global `json`
- **Fix**: Run `json = require('json')` first

### **Process Not Responding**
- **Debug**: Check `Inbox` for error messages
- **Debug**: Verify process loaded with `ao.id`

## 🚀 **Success Criteria**
Each deployed process should:
1. ✅ Load without errors
2. ✅ Respond to `Info` action with correct data
3. ✅ Handle process-specific actions
4. ✅ Maintain state correctly
5. ✅ Communicate with other processes (after configuration)

---
**Remember**: This guide captures all the hard-learned lessons from multiple debugging sessions. Follow it exactly for smooth deployments!

# 🎯 TIM3 AOS COPY-PASTE GUIDE

## ✅ STEP 1: Open Terminal
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3
```

## ✅ STEP 2: Start AOS with Contract
```bash
aos tim3 --load tim3-swap-contract.lua
```

## ✅ STEP 3: Verify It Loaded (Copy & Paste Each Line)
```lua
ao.id
```
**SAVE THIS ID!** ☝️

```lua
Name
```
Should show: `TIM3`

```lua
Ticker
```
Should show: `TIM3`

```lua
USDA_PROCESS_ID
```
Should show: `FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8`

## ✅ STEP 4: Test Basic Functions
```lua
Send({Target = ao.id, Action = "Info"})
```

Wait 1 second, then:
```lua
Inbox[#Inbox].Action
```
Should show: `Info-Response`

## ✅ STEP 5: Check Your Balance
```lua
Send({Target = ao.id, Action = "Balance"})
```

Wait 1 second, then:
```lua
Inbox[#Inbox].Data
```

## ✅ STEP 6: Simulate a Swap (Testing)
```lua
Send({
    Target = ao.id,
    From = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8",
    Action = "Credit-Notice",
    Data = json.encode({
        Sender = ao.id,
        Quantity = "1000000"
    })
})
```

Check it worked:
```lua
Send({Target = ao.id, Action = "Balance"})
```
```lua
json.decode(Inbox[#Inbox].Data)
```

## ✅ STEP 7: Load Helper Functions
```lua
.load tim3-helpers.lua
```

Now you can use:
```lua
checkMyBalance()
```
```lua
getContractInfo()
```
```lua
getStats()
```

## ✅ STEP 8: Load Monitor
```lua
.load tim3-monitor.lua
```

Show dashboard:
```lua
showDashboard()
```

## 🔥 PRODUCTION SWAP COMMANDS

### Swap USDA for TIM3:
```lua
swapUsdaForTim3("1000000")
```

### Burn TIM3 for USDA:
```lua
burnTim3ForUsda("1000000")
```

### Transfer TIM3:
```lua
transferTim3("recipient_address", "500000")
```

---

## 📝 YOUR PROCESS INFO

After Step 3, write down:
- **Process ID**: ________________________
- **Status**: ✅ Deployed

## 🆘 IF SOMETHING BREAKS

Exit AOS:
```
Ctrl + C
```

Reconnect:
```bash
aos tim3
```

Reload contract:
```lua
.load tim3-swap-contract.lua
```
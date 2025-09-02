# 🚀 TIM3 PRODUCTION DEPLOYMENT GUIDE

## ⚡ Quick Deploy (2 Steps)

### Step 1: Deploy Contract
```bash
cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3
aos tim3-production --load tim3-production.lua
```

### Step 2: Load Helpers & Test
```lua
.load tim3-production-helpers.lua
quickTest()
```

**That's it! Your TIM3 contract is live!**

---

## 📋 Production Checklist

After deployment, run these commands in AOS:

### 1️⃣ Save Your Process ID
```lua
ao.id
```
**Write this down:** ________________________

### 2️⃣ Verify Configuration
```lua
getInfo()
viewLastMessage()
```
Should show:
- Name: TIM3
- USDA Process: FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8
- IsProduction: true

### 3️⃣ Test Admin Mint (You're the admin)
```lua
adminTestMint(ao.id, "1000000")
```
Wait 1 second, then:
```lua
viewBalance()
```
Should show balance: 1000000

### 4️⃣ Check System Health
```lua
viewHealth()
```
Should show status: HEALTHY

### 5️⃣ View Statistics
```lua
viewStats()
```
Shows supply, collateral, and swap stats

---

## 🧪 Testing Production Functions

### Test Minting (Admin Only)
```lua
-- Mint 10 TIM3 for testing
adminTestMint(ao.id, "10000000")
viewBalance()
```

### Test Burning
```lua
-- Burn 1 TIM3 to get USDA back
burnTim3("1000000")
```

### Test Transfer
```lua
-- Transfer 0.5 TIM3 to another address
transferTim3("recipient_address", "500000")
```

### Get Admin Statistics
```lua
adminStats()
viewLastMessage()
```

---

## 🔗 Integration Information

**Your TIM3 Contract:**
- Process ID: `[Copy from ao.id above]`
- Admin: `[Your ao.id address]`

**For Wallets/Frontends:**
```javascript
const TIM3_PROCESS = "[YOUR_PROCESS_ID]"
const USDA_PROCESS = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"
```

---

## 📊 Monitor Your Contract

### Live Dashboard
```lua
.load tim3-monitor.lua
showDashboard()
```

### Quick Stats
```lua
quickStats()
```

---

## 🔄 Real Production Flow

### How Users Will Swap:

1. **User sends USDA to your TIM3 process**
   - From: User's wallet
   - To: Your TIM3 Process ID
   - Action: Transfer
   - Amount: e.g., "1000000" (1 USDA)

2. **TIM3 automatically mints 1:1**
   - User receives TIM3 instantly
   - Contract tracks USDA as collateral

3. **User can burn TIM3 anytime**
   - Send TIM3 to "burn" address
   - Receive USDA back 1:1

---

## ⚠️ Important Notes

1. **You are the admin** - Only you can use `adminTestMint`
2. **Real swaps** require actual USDA transfers from users
3. **Test first** with small amounts using admin functions
4. **Save your Process ID** - This is your contract address

---

## 🆘 Troubleshooting

### If nothing responds:
```lua
-- Check process is alive
ao.id
Name
```

### If balance is wrong:
```lua
-- Force check
Send({Target = ao.id, Action = "Balance"})
Inbox[#Inbox].Data
```

### To see all messages:
```lua
#Inbox  -- Shows count
Inbox[#Inbox]  -- Shows last message
```

---

## ✅ Success Indicators

- [x] Contract responds to `getInfo()`
- [x] Admin test mint works
- [x] Balance updates correctly
- [x] Health status is "HEALTHY"
- [x] Stats show correct supply/collateral

---

## 🎉 YOU'RE LIVE!

Your TIM3 contract is now:
- ✅ Deployed on AO mainnet
- ✅ Ready for USDA swaps
- ✅ Fully tested and monitored
- ✅ Integration-ready for wallets

**Share your Process ID with users and they can start swapping!**
# TIM3 Production Integration Guide

## Contract Information

- **TIM3 Process ID**: `[YOUR_DEPLOYED_PROCESS_ID]`
- **USDA Process ID**: `FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8`
- **Token Symbol**: TIM3
- **Decimals**: 6
- **Swap Ratio**: 1:1 with USDA

## For Wallet Integration (e.g., ArConnect, Wander)

### 1. Add TIM3 Token
```javascript
const TIM3_TOKEN = {
    processId: "[YOUR_TIM3_PROCESS_ID]",
    name: "TIM3",
    ticker: "TIM3",
    denomination: 6,
    logo: "TIM3_LOGO_TXID"
}
```

### 2. Swap USDA → TIM3
```javascript
// User sends USDA to TIM3 process
await window.arweaveWallet.dispatch({
    process: "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", // USDA
    action: "Transfer",
    tags: [
        { name: "Recipient", value: "[YOUR_TIM3_PROCESS_ID]" },
        { name: "Quantity", value: "1000000" } // 1 USDA
    ]
});
// TIM3 will be automatically minted to user's address
```

### 3. Burn TIM3 → USDA
```javascript
// User sends TIM3 to "burn" address
await window.arweaveWallet.dispatch({
    process: "[YOUR_TIM3_PROCESS_ID]",
    action: "Transfer",
    tags: [
        { name: "Recipient", value: "burn" },
        { name: "Quantity", value: "1000000" } // 1 TIM3
    ]
});
// USDA will be automatically returned to user's address
```

### 4. Check Balance
```javascript
const message = await ao.message({
    process: "[YOUR_TIM3_PROCESS_ID]",
    action: "Balance",
    tags: [
        { name: "Target", value: userAddress }
    ]
});
// Response in message.Data: {"balance": "1000000", "ticker": "TIM3"}
```

## For Frontend Integration (React/Vue/etc)

### Install AO Connect
```bash
npm install @permaweb/aoconnect
```

### Setup
```javascript
import { message, result, dryrun } from '@permaweb/aoconnect';

const TIM3_PROCESS = "[YOUR_TIM3_PROCESS_ID]";
const USDA_PROCESS = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8";
```

### Swap Functions
```javascript
// Get TIM3 Balance
async function getTIM3Balance(address) {
    const res = await dryrun({
        process: TIM3_PROCESS,
        tags: [
            { name: "Action", value: "Balance" },
            { name: "Target", value: address }
        ]
    });
    const data = JSON.parse(res.Messages[0].Data);
    return data.balance;
}

// Swap USDA for TIM3
async function swapUsdaForTim3(amount) {
    const messageId = await message({
        process: USDA_PROCESS,
        signer: createDataItemSigner(wallet),
        tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: TIM3_PROCESS },
            { name: "Quantity", value: amount }
        ]
    });
    return await result({ message: messageId, process: USDA_PROCESS });
}

// Burn TIM3 for USDA
async function burnTim3ForUsda(amount) {
    const messageId = await message({
        process: TIM3_PROCESS,
        signer: createDataItemSigner(wallet),
        tags: [
            { name: "Action", value: "Transfer" },
            { name: "Recipient", value: "burn" },
            { name: "Quantity", value: amount }
        ]
    });
    return await result({ message: messageId, process: TIM3_PROCESS });
}

// Get Contract Stats
async function getContractStats() {
    const res = await dryrun({
        process: TIM3_PROCESS,
        tags: [
            { name: "Action", value: "Stats" }
        ]
    });
    return JSON.parse(res.Messages[0].Data);
}
```

## API Endpoints

### Actions

| Action | Description | Required Tags | Response |
|--------|-------------|---------------|----------|
| `Info` | Get contract info | None | Contract details |
| `Balance` | Check balance | `Target` (optional) | Balance data |
| `Stats` | Get statistics | None | Contract statistics |
| `Health` | Health check | None | System health status |
| `Transfer` | Transfer/Burn TIM3 | `Recipient`, `Quantity` | Transfer result |

### Responses

#### Balance Response
```json
{
    "target": "user_address",
    "balance": "1000000",
    "ticker": "TIM3"
}
```

#### Stats Response
```json
{
    "TotalSupply": "1000000",
    "UsdaCollateral": "1000000",
    "CollateralRatio": 1.0,
    "SwapStats": {
        "totalSwaps": 10,
        "totalBurns": 5,
        "totalVolume": 15000000,
        "uniqueUsers": 8
    },
    "IsHealthy": true
}
```

## Testing in Production

### For Admin Testing
If you deployed the contract, you're the admin and can test:

```lua
-- In AOS terminal
.load tim3-production-helpers.lua

-- Test mint (admin only)
adminTestMint(ao.id, "1000000")

-- Check it worked
viewBalance()

-- Get admin stats
adminStats()
```

### For User Testing
```lua
-- Check your balance
checkBalance()

-- Burn TIM3 for USDA
burnTim3("500000")

-- Transfer to another user
transferTim3("recipient_address", "250000")
```

## Smart Contract Verification

1. **Verify USDA Process**: Always ensure USDA process is `FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8`
2. **Check Collateral Ratio**: Should always be 1:1
3. **Monitor Health**: Use the `Health` action to verify system status

## Error Handling

Common errors and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| `Insufficient balance` | Not enough TIM3 | Check balance first |
| `Invalid amount` | Amount <= 0 | Use positive integers |
| `Unauthorized` | Not admin for admin functions | Use regular user functions |

## Support

- Process ID: `[YOUR_TIM3_PROCESS_ID]`
- Check health: Send `Action: Health`
- Get stats: Send `Action: Stats`
- Monitor: Load `tim3-monitor.lua` in AOS
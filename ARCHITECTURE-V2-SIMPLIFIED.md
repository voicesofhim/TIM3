# TIM3 Architecture V2 - Simplified Single-Process Approach

## Executive Summary

After extensive testing, we've identified that the multi-process orchestration approach has fundamental inter-process communication issues that make it unreliable for production. We're pivoting to a **single-process solution** that leverages standard AO token patterns.

## The Problem with V1 Architecture

- ❌ **Complex orchestration** between 4+ processes
- ❌ **Unreliable inter-process messaging** 
- ❌ **Custom Lock handlers** not in production USDA
- ❌ **Over-engineered authorization layers**
- ❌ **Network delivery inconsistencies**

## V2 Solution - Single Process Swap Contract

### Core Concept
**One TIM3 process that acts as both the token and the swap mechanism**

### User Experience (Unchanged)
1. User enters "5.0 USDA" in input
2. UI shows "You will receive 5.0 TIM3"
3. User clicks "Swap"
4. Wander Wallet prompts: "Transfer 5 USDA to TIM3 Contract"
5. User confirms → USDA transferred → TIM3 minted automatically

### Technical Flow (Simplified)

```
User Wallet → USDA Transfer → TIM3 Process
                                    ↓
                          Credit-Notice received
                                    ↓
                          Mint TIM3 (1:1 ratio)
                                    ↓
                          User owns TIM3, USDA locked
```

### Single Process Handles Everything

1. **USDA Reception**: Via standard `Credit-Notice` handler
2. **TIM3 Minting**: Atomic operation in same process
3. **Collateral Tracking**: Simple state variables
4. **TIM3 Burning**: Standard token burn with USDA release

## Implementation

### Core Handler Pattern
```lua
-- Receive USDA transfers and mint TIM3
Handlers.add("Credit-Notice", 
  Handlers.utils.hasMatchingTag("Action", "Credit-Notice"),
  function(msg)
    if msg.From == USDA_PROCESS_ID then
      local data = json.decode(msg.Data)
      local user = data.Sender
      local amount = tonumber(data.Quantity)
      
      -- Mint TIM3 1:1 for received USDA
      mint(user, amount)
      
      -- Track USDA collateral
      UsdaCollateral = UsdaCollateral + amount
    end
  end
)

-- Burn TIM3 and release USDA
Handlers.add("Burn",
  Handlers.utils.hasMatchingTag("Action", "Transfer"),
  function(msg)
    if msg.Tags.Recipient == "burn" then
      local amount = tonumber(msg.Tags.Quantity)
      burn(msg.From, amount)
      
      -- Release USDA back to user
      Send({
        Target = USDA_PROCESS_ID,
        Action = "Transfer",
        Recipient = msg.From,
        Quantity = tostring(amount)
      })
      
      UsdaCollateral = UsdaCollateral - amount
    end
  end
)
```

## Benefits

✅ **Zero inter-process communication** - everything atomic  
✅ **Standard AO patterns** - Credit-Notice is universal  
✅ **Production USDA compatible** - no custom handlers needed  
✅ **Simpler testing** - one process to debug  
✅ **Lower gas costs** - fewer process hops  
✅ **More reliable** - no network delivery issues  

## Migration Strategy

1. **Phase 1**: Build single-process TIM3 contract
2. **Phase 2**: Test with production USDA
3. **Phase 3**: Deploy and integrate with frontend
4. **Phase 4**: Archive V1 multi-process system

## Success Metrics

- User transfers USDA → automatically receives TIM3
- User burns TIM3 → automatically receives USDA back
- 1:1 ratio maintained at all times
- Zero failed transactions due to inter-process issues

---

**This approach eliminates ALL the communication issues we've encountered and aligns with standard AO token mechanics.**
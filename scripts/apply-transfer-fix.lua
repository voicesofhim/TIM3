-- Apply Lock Manager Transfer Fix
-- 
-- This script implements a new transfer-based approach for USDA locking:
-- 1. Modified LockCollateral Handler: Instead of sending Lock commands to USDA, it creates a
--    "awaiting-transfer" state and asks the user to transfer USDA directly
-- 2. New Credit-Notice Handler: Listens for USDA transfers and matches them to pending mint operations
-- 3. Perfect User Flow:
--    - User clicks "Mint 5 TIM3"
--    - Gets response: "Transfer 5 USDA to: MWx..."
--    - User transfers → Credit-Notice received → Mint proceeds
json = require('json')

-- New Lock Collateral Handler (Modified to expect user-initiated transfers)
Handlers.add(
    "LockCollateral",
    Handlers.utils.hasMatchingTag("Action", "LockCollateral"),
    function(msg)
        local user = msg.Tags.User or msg.From
        local amount = tonumber(msg.Tags.Amount or msg.Tags.Quantity)
        local purpose = msg.Tags.Purpose or "TIM3-mint"
        
        -- Authorization check
        if not isAuthorizedCaller(msg.From) then
            ao.send({
                Target = msg.From,
                Action = "LockCollateral-Error",
                Data = "Unauthorized caller"
            })
            return
        end
        
        -- Validate amount
        local valid, error = validateAmount(amount)
        if not valid then
            ao.send({
                Target = msg.From,
                Action = "LockCollateral-Error",
                Data = error
            })
            return
        end
        
        -- Check USDA configuration
        if not Config.mockUsdaProcess then
            ao.send({
                Target = msg.From,
                Action = "LockCollateral-Error",
                Data = "USDA process not configured"
            })
            return
        end
        
        -- Generate lock ID
        local lockId = generateLockId(user)
        
        -- Create lock record (pending until user transfers USDA)
        local lockRecord = {
            lockId = lockId,
            user = user,
            amount = amount,
            purpose = purpose,
            status = "awaiting-transfer",  -- Changed from "pending"
            requestor = msg.From,
            timestamp = os.time(),
            unlockTimestamp = nil
        }
        
        CollateralLocks[lockId] = lockRecord
        PendingOps[lockId] = lockRecord
        
        -- Send response asking user to transfer USDA
        ao.send({
            Target = msg.From,
            Action = "LockCollateral-Pending",
            Data = json.encode({
                lockId = lockId,
                user = user,
                amount = tostring(formatAmount(amount)),
                status = "awaiting-transfer",
                message = "Please transfer " .. tostring(formatAmount(amount)) .. " USDA to Lock Manager address: " .. ao.id,
                lockManagerAddress = ao.id
            })
        })
        
        -- Also notify the user directly
        ao.send({
            Target = user,
            Action = "Transfer-Required",
            Data = json.encode({
                lockId = lockId,
                amount = tostring(formatAmount(amount)),
                lockManagerAddress = ao.id,
                usdaProcess = Config.mockUsdaProcess,
                instructions = "Transfer " .. tostring(formatAmount(amount)) .. " USDA to complete TIM3 mint"
            })
        })
    end
)

-- New Credit Notice Handler (Receives USDA transfers)
Handlers.add(
    "USDA-Credit-Notice",
    Handlers.utils.hasMatchingTag("Action", "Credit-Notice"),
    function(msg)
        -- Only accept from configured USDA process
        if msg.From ~= Config.mockUsdaProcess then
            return
        end
        
        local creditData = json.decode(msg.Data or "{}")
        local fromUser = creditData.from
        local amount = tonumber(creditData.amount or "0")
        
        if not fromUser or amount <= 0 then
            return
        end
        
        -- Find matching pending operation
        local matchingLockId = nil
        local matchingLock = nil
        
        for lockId, lockRecord in pairs(PendingOps) do
            if lockRecord.user == fromUser and 
               lockRecord.status == "awaiting-transfer" and 
               lockRecord.amount == amount then
                matchingLockId = lockId
                matchingLock = lockRecord
                break
            end
        end
        
        if matchingLock then
            -- Update lock status
            matchingLock.status = "locked"
            matchingLock.usdaTransferConfirmed = true
            
            -- Update statistics
            LockStats.totalLocked = LockStats.totalLocked + matchingLock.amount
            LockStats.totalLocks = LockStats.totalLocks + 1
            LockStats.activeLocks = LockStats.activeLocks + 1
            
            -- Remove from pending
            PendingOps[matchingLockId] = nil
            
            -- Notify original requestor (Coordinator)
            ao.send({
                Target = matchingLock.requestor,
                Action = "LockCollateral-Success",
                Data = json.encode({
                    lockId = matchingLockId,
                    user = matchingLock.user,
                    amount = tostring(formatAmount(matchingLock.amount)),
                    status = "locked"
                })
            })
            
            -- Notify state manager
            if Config.stateManagerProcess then
                ao.send({
                    Target = Config.stateManagerProcess,
                    Action = "UpdatePosition",
                    Tags = {
                        User = matchingLock.user,
                        Collateral = tostring(matchingLock.amount),
                        Operation = "add"
                    }
                })
            end
            
            -- Notify user of successful lock
            ao.send({
                Target = fromUser,
                Action = "Lock-Confirmed",
                Data = json.encode({
                    lockId = matchingLockId,
                    amount = tostring(formatAmount(amount)),
                    status = "locked",
                    message = "USDA successfully locked. TIM3 mint proceeding."
                })
            })
        else
            -- No matching pending operation - this might be a direct transfer
            -- For now, just acknowledge receipt
            ao.send({
                Target = fromUser,
                Action = "Unexpected-Transfer",
                Data = json.encode({
                    amount = tostring(formatAmount(amount)),
                    message = "Received USDA transfer but no matching mint operation found"
                })
            })
        end
    end
)

print("Lock Manager updated for Transfer-based USDA interaction")
print("New flow: User transfers USDA → Lock Manager receives Credit-Notice → Mint proceeds")
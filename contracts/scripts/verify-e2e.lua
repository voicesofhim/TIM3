-- TIM3 End-to-End Verify: USDA → TIM3 mint
-- Run with: aos --load scripts/verify-e2e.lua

local json = require('json')

-- Deployed TEST Process IDs (safe for development)
local P = {
  COORDINATOR   = "uNhmrUij4u6ZZr_39BDI5E2G2afkit8oC7q4vAtRskM",
  LOCK_MANAGER  = "MWxRVsCDoSzQ0MhG4_BWkYs0fhcULB-OO3f2t1RlBAs",
  TOKEN_MANAGER = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw",
  STATE_MANAGER = "K2FjwiTmncglx0pISNMft5-SngxW-HUjs9sctzmXtU4",
  MOCK_USDA     = "u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ"
}

-- Copy of scripts/apply-transfer-fix.lua (embedded for one-click verify)
local LOCK_FIX = [[
json = require('json')
Handlers.add(
    "LockCollateral",
    Handlers.utils.hasMatchingTag("Action", "LockCollateral"),
    function(msg)
        local user = msg.Tags.User or msg.From
        local amount = tonumber(msg.Tags.Amount or msg.Tags.Quantity)
        local purpose = msg.Tags.Purpose or "TIM3-mint"
        if not isAuthorizedCaller(msg.From) then
            ao.send({ Target = msg.From, Action = "LockCollateral-Error", Data = "Unauthorized caller" })
            return
        end
        local valid, error = validateAmount(amount)
        if not valid then
            ao.send({ Target = msg.From, Action = "LockCollateral-Error", Data = error })
            return
        end
        if not Config.mockUsdaProcess then
            ao.send({ Target = msg.From, Action = "LockCollateral-Error", Data = "USDA process not configured" })
            return
        end
        local lockId = generateLockId(user)
        local lockRecord = {
            lockId = lockId,
            user = user,
            amount = amount,
            purpose = purpose,
            status = "awaiting-transfer",
            requestor = msg.From,
            timestamp = os.time(),
            unlockTimestamp = nil
        }
        CollateralLocks[lockId] = lockRecord
        PendingOps[lockId] = lockRecord
        ao.send({ Target = msg.From, Action = "LockCollateral-Pending", Data = json.encode({
            lockId = lockId,
            user = user,
            amount = tostring(formatAmount(amount)),
            status = "awaiting-transfer",
            message = "Please transfer " .. tostring(formatAmount(amount)) .. " USDA to Lock Manager address: " .. ao.id,
            lockManagerAddress = ao.id
        })})
        ao.send({ Target = user, Action = "Transfer-Required", Data = json.encode({
            lockId = lockId,
            amount = tostring(formatAmount(amount)),
            lockManagerAddress = ao.id,
            usdaProcess = Config.mockUsdaProcess,
            instructions = "Transfer " .. tostring(formatAmount(amount)) .. " USDA to complete TIM3 mint"
        })})
    end
)
Handlers.add(
    "USDA-Credit-Notice",
    Handlers.utils.hasMatchingTag("Action", "Credit-Notice"),
    function(msg)
        if msg.From ~= Config.mockUsdaProcess then return end
        local creditData = json.decode(msg.Data or "{}")
        local fromUser = creditData.from
        local amount = tonumber(creditData.amount or "0")
        if not fromUser or amount <= 0 then return end
        local matchingLockId = nil
        local matchingLock = nil
        for lockId, lockRecord in pairs(PendingOps) do
            if lockRecord.user == fromUser and lockRecord.status == "awaiting-transfer" and lockRecord.amount == amount then
                matchingLockId = lockId
                matchingLock = lockRecord
                break
            end
        end
        if matchingLock then
            matchingLock.status = "locked"
            matchingLock.usdaTransferConfirmed = true
            LockStats.totalLocked = LockStats.totalLocked + matchingLock.amount
            LockStats.totalLocks = LockStats.totalLocks + 1
            LockStats.activeLocks = LockStats.activeLocks + 1
            PendingOps[matchingLockId] = nil
            ao.send({ Target = matchingLock.requestor, Action = "LockCollateral-Success", Data = json.encode({
                lockId = matchingLockId,
                user = matchingLock.user,
                amount = tostring(formatAmount(matchingLock.amount)),
                status = "locked"
            })})
            if Config.stateManagerProcess then
                ao.send({ Target = Config.stateManagerProcess, Action = "UpdatePosition", Tags = {
                    User = matchingLock.user,
                    Collateral = tostring(matchingLock.amount),
                    Operation = "add"
                } })
            end
            ao.send({ Target = fromUser, Action = "Lock-Confirmed", Data = json.encode({
                lockId = matchingLockId,
                amount = tostring(formatAmount(amount)),
                status = "locked",
                message = "USDA successfully locked. TIM3 mint proceeding."
            })})
        else
            ao.send({ Target = fromUser, Action = "Unexpected-Transfer", Data = json.encode({
                amount = tostring(formatAmount(amount)),
                message = "Received USDA transfer but no matching mint operation found"
            })})
        end
    end
)
print("Lock Manager updated for transfer-based USDA interaction")
]]

local function log(msg)
  print(msg)
end

log("🧪 TIM3 E2E Verify (USDA → TIM3)")
log("=================================")

-- 1) Configure processes
log("Configuring processes...")
Send({ Target = P.COORDINATOR, Action = "Configure", Tags = { ConfigType = "MockUsdaProcess",    Value = P.MOCK_USDA } })
Send({ Target = P.COORDINATOR, Action = "Configure", Tags = { ConfigType = "StateManagerProcess", Value = P.STATE_MANAGER } })
Send({ Target = P.COORDINATOR, Action = "Configure", Tags = { ConfigType = "LockManagerProcess",  Value = P.LOCK_MANAGER } })
Send({ Target = P.COORDINATOR, Action = "Configure", Tags = { ConfigType = "TokenManagerProcess", Value = P.TOKEN_MANAGER } })
-- Allow deposit-mint via Credit-Notice path (optional)
Send({ Target = P.COORDINATOR, Action = "Configure", Tags = { ConfigType = "AllowedUsdaProcess", Value = P.MOCK_USDA } })

Send({ Target = P.STATE_MANAGER, Action = "Configure", Tags = { ConfigType = "CoordinatorProcess", Value = P.COORDINATOR } })
Send({ Target = P.STATE_MANAGER, Action = "Configure", Tags = { ConfigType = "LockManagerProcess", Value = P.LOCK_MANAGER } })
Send({ Target = P.STATE_MANAGER, Action = "Configure", Tags = { ConfigType = "TokenManagerProcess", Value = P.TOKEN_MANAGER } })

Send({ Target = P.LOCK_MANAGER, Action = "Configure", Tags = { ConfigType = "CoordinatorProcess", Value = P.COORDINATOR } })
Send({ Target = P.LOCK_MANAGER, Action = "Configure", Tags = { ConfigType = "StateManagerProcess", Value = P.STATE_MANAGER } })
Send({ Target = P.LOCK_MANAGER, Action = "Configure", Tags = { ConfigType = "MockUsdaProcess",   Value = P.MOCK_USDA } })

Send({ Target = P.TOKEN_MANAGER, Action = "Configure", Tags = { ConfigType = "CoordinatorProcess", Value = P.COORDINATOR } })
Send({ Target = P.TOKEN_MANAGER, Action = "Configure", Tags = { ConfigType = "StateManagerProcess", Value = P.STATE_MANAGER } })
Send({ Target = P.TOKEN_MANAGER, Action = "Configure", Tags = { ConfigType = "LockManagerProcess",  Value = P.LOCK_MANAGER } })

log("Applying Lock Manager transfer-based fix...")
Send({ Target = P.LOCK_MANAGER, Action = "Eval", Data = LOCK_FIX })

-- 2) Ensure USDA balance for this session
log("Minting 5 Mock USDA to this session (" .. ao.id .. ")...")
Send({ Target = P.MOCK_USDA, Action = "Mint", Tags = { Amount = "5" } })

-- 3) Request mint of 5 TIM3 via coordinator
log("Requesting mint of 5 TIM3 via Coordinator...")
Send({ Target = P.COORDINATOR, Action = "MintTIM3", Tags = { Amount = "5" } })

-- The coordinator will ask Lock Manager to lock collateral.
-- With the transfer-based fix, user must transfer USDA to Lock Manager.

-- 4) Transfer 5 USDA → Lock Manager (triggers Credit-Notice)
log("Transferring 5 Mock USDA to Lock Manager to satisfy collateral...")
Send({ Target = P.MOCK_USDA, Action = "Transfer", Tags = { Recipient = P.LOCK_MANAGER, Amount = "5" } })

-- 5) Query TIM3 balance for this session
log("Querying TIM3 balance for this session...")
Send({ Target = P.TOKEN_MANAGER, Action = "Balance", Tags = { Target = ao.id } })

log("\n✅ Commands sent. Check Inbox[#Inbox] for:")
log("- MintTIM3-Pending → then MintTIM3-Progress / MintTIM3-Response (from Coordinator)")
log("- Transfer-Response (from Mock USDA) and Lock-Confirmed (from Lock Manager)")
log("- Balance-Response (from Token Manager) for your TIM3 balance")

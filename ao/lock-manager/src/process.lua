-- TIM3 Lock Manager Process
-- Manages USDA collateral locking/unlocking operations
-- Interfaces with Mock USDA token for collateral management

local json = require("cjson")

-- Initialize process state
Name = Name or "TIM3 Lock Manager"
Ticker = Ticker or "TIM3-LOCK"
Version = Version or "1.0.0"

-- Collateral Lock Tracking
CollateralLocks = CollateralLocks or {}

-- Lock Statistics
LockStats = LockStats or {
    totalLocked = 0,
    totalLocks = 0,
    activeLocks = 0,
    totalUnlocked = 0
}

-- Process Configuration
Config = Config or {
    coordinatorProcess = nil,
    stateManagerProcess = nil,
    mockUsdaProcess = nil,
    
    -- Lock parameters
    minLockAmount = 10,
    maxLockAmount = 1000000,
    lockDuration = 0,  -- 0 = indefinite until manual unlock
    
    -- Security settings
    allowedCallers = {},  -- Processes that can request locks
    requireConfirmation = true
}

-- Pending Operations (for async USDA operations)
PendingOps = PendingOps or {}

-- Helper Functions
local function formatAmount(amount)
    if amount == math.floor(amount) then
        return math.floor(amount)
    else
        return math.floor(amount * 1000000) / 1000000
    end
end

local function validateAmount(amount)
    if not amount or type(amount) ~= "number" or amount <= 0 then
        return false, "Invalid amount"
    end
    
    local minAmount = Config.minLockAmount or 10
    local maxAmount = Config.maxLockAmount or 1000000
    
    if amount < minAmount then
        return false, "Amount below minimum (" .. minAmount .. ")"
    end
    if amount > maxAmount then
        return false, "Amount above maximum (" .. maxAmount .. ")"
    end
    return true, nil
end

local function generateLockId(user)
    return user .. "-lock-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
end

local function isAuthorizedCaller(caller)
    if not Config.requireConfirmation then
        return true
    end
    
    -- Allow coordinator and configured processes
    if caller == Config.coordinatorProcess or caller == Config.stateManagerProcess then
        return true
    end
    
    -- Check allowed callers list
    for _, allowedCaller in ipairs(Config.allowedCallers) do
        if caller == allowedCaller then
            return true
        end
    end
    
    return false
end

-- Configuration Handler
Handlers.add(
    "Configure",
    Handlers.utils.hasMatchingTag("Action", "Configure"),
    function(msg)
        local configType = msg.Tags.ConfigType
        local value = msg.Tags.Value
        
        if configType == "CoordinatorProcess" then
            Config.coordinatorProcess = value
        elseif configType == "StateManagerProcess" then
            Config.stateManagerProcess = value
        elseif configType == "MockUsdaProcess" then
            Config.mockUsdaProcess = value
        elseif configType == "MinLockAmount" then
            Config.minLockAmount = tonumber(value) or Config.minLockAmount
        elseif configType == "MaxLockAmount" then
            Config.maxLockAmount = tonumber(value) or Config.maxLockAmount
        elseif configType == "RequireConfirmation" then
            Config.requireConfirmation = value == "true"
        else
            ao.send({
                Target = msg.From,
                Action = "Configure-Error",
                Data = "Unknown configuration type: " .. (configType or "nil")
            })
            return
        end
        
        ao.send({
            Target = msg.From,
            Action = "Configure-Response",
            Data = json.encode({
                configType = configType,
                value = value,
                success = true
            })
        })
    end
)

-- Process Info Handler
Handlers.add(
    "Info",
    Handlers.utils.hasMatchingTag("Action", "Info"),
    function(msg)
        ao.send({
            Target = msg.From,
            Action = "Info-Response",
            Data = json.encode({
                name = Name,
                ticker = Ticker,
                version = Version,
                lockStats = LockStats,
                config = {
                    minLockAmount = Config.minLockAmount,
                    maxLockAmount = Config.maxLockAmount,
                    requireConfirmation = Config.requireConfirmation,
                    mockUsdaConfigured = Config.mockUsdaProcess ~= nil
                }
            })
        })
    end
)

-- Lock Collateral Handler
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
        
        -- Check Mock USDA configuration
        if not Config.mockUsdaProcess then
            ao.send({
                Target = msg.From,
                Action = "LockCollateral-Error",
                Data = "Mock USDA process not configured"
            })
            return
        end
        
        -- Generate lock ID
        local lockId = generateLockId(user)
        
        -- Create lock record (pending until USDA confirms)
        local lockRecord = {
            lockId = lockId,
            user = user,
            amount = amount,
            purpose = purpose,
            status = "pending",
            requestor = msg.From,
            timestamp = os.time(),
            unlockTimestamp = nil
        }
        
        CollateralLocks[lockId] = lockRecord
        PendingOps[lockId] = lockRecord
        
        -- Send lock request to Mock USDA
        ao.send({
            Target = Config.mockUsdaProcess,
            Action = "Lock",
            Tags = {
                User = user,
                Amount = tostring(amount),
                Locker = ao.id,
                Purpose = purpose,
                LockId = lockId
            }
        })
        
        -- Send pending response
        ao.send({
            Target = msg.From,
            Action = "LockCollateral-Pending",
            Data = json.encode({
                lockId = lockId,
                user = user,
                amount = tostring(formatAmount(amount)),
                status = "pending"
            })
        })
    end
)

-- Lock Confirmation Handler (from Mock USDA)
Handlers.add(
    "Lock-Confirmed",
    Handlers.utils.hasMatchingTag("Action", "Lock-Confirmed"),
    function(msg)
        -- Only accept confirmations from configured Mock USDA
        if msg.From ~= Config.mockUsdaProcess then
            return
        end
        
        local lockData = json.decode(msg.Data or "{}")
        local lockId = lockData.lockId
        
        if not lockId or not PendingOps[lockId] then
            return
        end
        
        local lockRecord = CollateralLocks[lockId]
        if lockRecord then
            -- Update lock status
            lockRecord.status = "locked"
            lockRecord.usdaLockId = lockData.lockId
            
            -- Update statistics
            LockStats.totalLocked = LockStats.totalLocked + lockRecord.amount
            LockStats.totalLocks = LockStats.totalLocks + 1
            LockStats.activeLocks = LockStats.activeLocks + 1
            
            -- Remove from pending
            PendingOps[lockId] = nil
            
            -- Notify original requestor
            ao.send({
                Target = lockRecord.requestor,
                Action = "LockCollateral-Success",
                Data = json.encode({
                    lockId = lockId,
                    user = lockRecord.user,
                    amount = tostring(formatAmount(lockRecord.amount)),
                    status = "locked",
                    usdaLockId = lockRecord.usdaLockId
                })
            })
            
            -- Notify state manager
            if Config.stateManagerProcess then
                ao.send({
                    Target = Config.stateManagerProcess,
                    Action = "UpdatePosition",
                    Tags = {
                        User = lockRecord.user,
                        Collateral = tostring(lockRecord.amount),
                        Operation = "add"
                    }
                })
            end
        end
    end
)

-- Unlock Collateral Handler
Handlers.add(
    "UnlockCollateral",
    Handlers.utils.hasMatchingTag("Action", "UnlockCollateral"),
    function(msg)
        local lockId = msg.Tags.LockId
        local user = msg.Tags.User
        local amount = tonumber(msg.Tags.Amount or "0")
        
        -- Authorization check
        if not isAuthorizedCaller(msg.From) then
            ao.send({
                Target = msg.From,
                Action = "UnlockCollateral-Error",
                Data = "Unauthorized caller"
            })
            return
        end
        
        local lockRecord = nil
        
        -- Find lock record
        if lockId then
            lockRecord = CollateralLocks[lockId]
        elseif user and amount > 0 then
            -- Find matching lock by user and amount
            for id, record in pairs(CollateralLocks) do
                if record.user == user and record.amount >= amount and record.status == "locked" then
                    lockRecord = record
                    lockId = id
                    break
                end
            end
        else
            ao.send({
                Target = msg.From,
                Action = "UnlockCollateral-Error",
                Data = "LockId or User+Amount required"
            })
            return
        end
        
        if not lockRecord or lockRecord.status ~= "locked" then
            ao.send({
                Target = msg.From,
                Action = "UnlockCollateral-Error",
                Data = "Lock not found or not in locked state"
            })
            return
        end
        
        -- Check Mock USDA configuration
        if not Config.mockUsdaProcess then
            ao.send({
                Target = msg.From,
                Action = "UnlockCollateral-Error",
                Data = "Mock USDA process not configured"
            })
            return
        end
        
        -- Calculate unlock amount (partial or full)
        local unlockAmount = amount > 0 and math.min(amount, lockRecord.amount) or lockRecord.amount
        
        -- Update lock record
        lockRecord.status = "unlocking"
        lockRecord.unlockTimestamp = os.time()
        lockRecord.unlockAmount = unlockAmount
        
        -- Send unlock request to Mock USDA
        ao.send({
            Target = Config.mockUsdaProcess,
            Action = "Unlock",
            Tags = {
                User = lockRecord.user,
                Amount = tostring(unlockAmount),
                LockId = lockRecord.usdaLockId or lockId
            }
        })
        
        -- Send pending response
        ao.send({
            Target = msg.From,
            Action = "UnlockCollateral-Pending",
            Data = json.encode({
                lockId = lockId,
                user = lockRecord.user,
                unlockAmount = tostring(formatAmount(unlockAmount)),
                status = "unlocking"
            })
        })
    end
)

-- Unlock Confirmation Handler (from Mock USDA)
Handlers.add(
    "Unlock-Response",
    Handlers.utils.hasMatchingTag("Action", "Unlock-Response"),
    function(msg)
        -- Only accept confirmations from configured Mock USDA
        if msg.From ~= Config.mockUsdaProcess then
            return
        end
        
        local unlockData = json.decode(msg.Data or "{}")
        local user = unlockData.user
        local amount = tonumber(unlockData.amount or "0")
        
        -- Find matching lock record
        local lockRecord = nil
        local lockId = nil
        
        for id, record in pairs(CollateralLocks) do
            if record.user == user and record.status == "unlocking" and record.unlockAmount == amount then
                lockRecord = record
                lockId = id
                break
            end
        end
        
        if lockRecord then
            -- Update lock record
            if lockRecord.unlockAmount >= lockRecord.amount then
                -- Full unlock - mark as completed
                lockRecord.status = "unlocked"
                LockStats.activeLocks = LockStats.activeLocks - 1
            else
                -- Partial unlock - update amount and mark as locked
                lockRecord.amount = lockRecord.amount - lockRecord.unlockAmount
                lockRecord.status = "locked"
            end
            
            -- Update statistics
            LockStats.totalUnlocked = LockStats.totalUnlocked + amount
            
            -- Notify original requestor
            ao.send({
                Target = lockRecord.requestor,
                Action = "UnlockCollateral-Success",
                Data = json.encode({
                    lockId = lockId,
                    user = lockRecord.user,
                    unlockedAmount = tostring(formatAmount(amount)),
                    remainingLocked = tostring(formatAmount(lockRecord.amount)),
                    status = lockRecord.status
                })
            })
            
            -- Notify state manager
            if Config.stateManagerProcess then
                ao.send({
                    Target = Config.stateManagerProcess,
                    Action = "UpdatePosition",
                    Tags = {
                        User = lockRecord.user,
                        Collateral = tostring(-amount),  -- Negative to subtract
                        Operation = "add"
                    }
                })
            end
        end
    end
)

-- Get Lock Info Handler
Handlers.add(
    "GetLockInfo",
    Handlers.utils.hasMatchingTag("Action", "GetLockInfo"),
    function(msg)
        local lockId = msg.Tags.LockId
        local user = msg.Tags.User
        
        local locks = {}
        
        if lockId then
            -- Get specific lock
            local lock = CollateralLocks[lockId]
            if lock then
                locks[lockId] = {
                    lockId = lockId,
                    user = lock.user,
                    amount = tostring(formatAmount(lock.amount)),
                    status = lock.status,
                    timestamp = lock.timestamp,
                    purpose = lock.purpose
                }
            end
        elseif user then
            -- Get all locks for user
            for id, lock in pairs(CollateralLocks) do
                if lock.user == user then
                    locks[id] = {
                        lockId = id,
                        user = lock.user,
                        amount = tostring(formatAmount(lock.amount)),
                        status = lock.status,
                        timestamp = lock.timestamp,
                        purpose = lock.purpose
                    }
                end
            end
        else
            ao.send({
                Target = msg.From,
                Action = "GetLockInfo-Error",
                Data = "LockId or User required"
            })
            return
        end
        
        local count = 0
        for _ in pairs(locks) do count = count + 1 end
        
        ao.send({
            Target = msg.From,
            Action = "LockInfo-Response",
            Data = json.encode({
                locks = locks,
                count = count
            })
        })
    end
)

-- Lock Statistics Handler
Handlers.add(
    "LockStats",
    Handlers.utils.hasMatchingTag("Action", "LockStats"),
    function(msg)
        local pendingCount = 0
        for _ in pairs(PendingOps) do pendingCount = pendingCount + 1 end
        
        ao.send({
            Target = msg.From,
            Action = "LockStats-Response",
            Data = json.encode({
                totalLocked = tostring(formatAmount(LockStats.totalLocked)),
                totalLocks = LockStats.totalLocks,
                activeLocks = LockStats.activeLocks,
                totalUnlocked = tostring(formatAmount(LockStats.totalUnlocked)),
                pendingOperations = pendingCount
            })
        })
    end
)
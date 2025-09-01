-- TIM3 Orchestrator Process
-- Main orchestrator for the TIM3 collateralized token system
-- Coordinates USDA locking and TIM3 minting operations

-- JSON is available globally in AO environment

-- Initialize process state
Name = Name or "TIM3 Orchestrator"
Ticker = Ticker or "TIM3"
Version = Version or "1.0.0"

-- Process Configuration
Config = Config or {
    -- Specialist process addresses (will be set via configuration messages)
    mockUsdaProcess = nil,
    allowedUsdaProcess = nil,
    stateManagerProcess = nil,
    lockManagerProcess = nil,
    tokenManagerProcess = nil,
    
    -- System parameters
    collateralRatio = 1.0,  -- 1:1 USDA backing ratio
    minMintAmount = 1,      -- Minimum TIM3 mint amount (prevent dust attacks)
    maxMintAmount = 100000, -- Maximum TIM3 mint amount
    
    -- Circuit breaker parameters
    maxMintPerUser = 50000,     -- Maximum TIM3 per user per period
    maxMintPerBlock = 10000,    -- Maximum TIM3 per block/time period
    mintCooldownPeriod = 300,   -- 5 minutes between large mints
    largeMinThreshold = 1000,   -- Amounts above this trigger cooldown
    
    -- Rate limiting
    blockMintTotal = 0,         -- Current block mint total
    lastBlockReset = 0,         -- Last time block counter was reset
    blockTimeWindow = 3600,     -- 1 hour window for rate limiting
    
    -- System status
    systemActive = true,
    totalCollateral = 0,
    totalTIM3Minted = 0,
    
    -- Timeout settings (5 minutes for pending operations)
    pendingTimeout = 300,  -- 300 seconds = 5 minutes
    
    -- Emergency pause (only admin can toggle)
    emergencyPaused = false,
    adminProcess = nil  -- Set this to the admin process ID
}

-- User positions tracking
UserPositions = UserPositions or {}

-- Pending mint operations (awaiting USDA lock confirmation)
PendingMints = PendingMints or {}

-- Pending burn operations (awaiting token burn confirmation)
PendingBurns = PendingBurns or {}

-- User mint tracking for rate limiting
UserMintHistory = UserMintHistory or {}

-- Process info
ProcessInfo = ProcessInfo or {
    name = Name,
    ticker = Ticker,
    version = Version,
    systemActive = Config.systemActive,
    totalCollateral = Config.totalCollateral,
    totalTIM3Minted = Config.totalTIM3Minted,
    collateralRatio = Config.collateralRatio
}

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
    if amount < Config.minMintAmount then
        return false, "Amount below minimum (" .. Config.minMintAmount .. ")"
    end
    if amount > Config.maxMintAmount then
        return false, "Amount above maximum (" .. Config.maxMintAmount .. ")"
    end
    return true, nil
end

local function calculateRequiredCollateral(tim3Amount)
    -- Use exact 1:1 ratio to prevent rounding attacks
    -- For fractional amounts, require proportional collateral
    return tim3Amount * Config.collateralRatio
end

local function resetBlockLimitsIfNeeded()
    local currentTime = os.time()
    if currentTime - Config.lastBlockReset >= Config.blockTimeWindow then
        Config.blockMintTotal = 0
        Config.lastBlockReset = currentTime
    end
end

local function validateCircuitBreakers(user, amount)
    local currentTime = os.time()
    resetBlockLimitsIfNeeded()
    
    -- Check block/time window limit
    if Config.blockMintTotal + amount > Config.maxMintPerBlock then
        return false, "Block mint limit exceeded (max " .. Config.maxMintPerBlock .. " per " .. (Config.blockTimeWindow / 3600) .. "h)"
    end
    
    -- Initialize user history if needed
    if not UserMintHistory[user] then
        UserMintHistory[user] = {
            totalMinted = 0,
            lastLargeMint = 0,
            mintCount = 0
        }
    end
    
    local userHistory = UserMintHistory[user]
    
    -- Check per-user limit (lifetime or reset periodically)
    if userHistory.totalMinted + amount > Config.maxMintPerUser then
        return false, "User mint limit exceeded (max " .. Config.maxMintPerUser .. " per user)"
    end
    
    -- Check cooldown for large mints
    if amount >= Config.largeMinThreshold then
        local timeSinceLastLarge = currentTime - userHistory.lastLargeMint
        if timeSinceLastLarge < Config.mintCooldownPeriod then
            local remainingCooldown = Config.mintCooldownPeriod - timeSinceLastLarge
            return false, "Large mint cooldown active (wait " .. remainingCooldown .. " seconds)"
        end
    end
    
    return true, nil
end

local function updateCircuitBreakerCounters(user, amount)
    resetBlockLimitsIfNeeded()
    
    -- Update block total
    Config.blockMintTotal = Config.blockMintTotal + amount
    
    -- Update user history
    local userHistory = UserMintHistory[user]
    userHistory.totalMinted = userHistory.totalMinted + amount
    userHistory.mintCount = userHistory.mintCount + 1
    
    -- Update large mint timestamp if applicable
    if amount >= Config.largeMinThreshold then
        userHistory.lastLargeMint = os.time()
    end
end

local function updateProcessInfo()
    ProcessInfo.systemActive = Config.systemActive
    ProcessInfo.totalCollateral = Config.totalCollateral
    ProcessInfo.totalTIM3Minted = Config.totalTIM3Minted
    ProcessInfo.collateralRatio = Config.collateralRatio
end

local function cleanupExpiredOperations()
    local currentTime = os.time()
    local expiredMints = {}
    local expiredBurns = {}
    
    -- Check pending mints
    for mintId, mint in pairs(PendingMints) do
        if currentTime - mint.timestamp > Config.pendingTimeout then
            table.insert(expiredMints, mintId)
        end
    end
    
    -- Check pending burns
    for burnId, burn in pairs(PendingBurns) do
        if currentTime - burn.timestamp > Config.pendingTimeout then
            table.insert(expiredBurns, burnId)
        end
    end
    
    -- Clean up expired mints
    for _, mintId in ipairs(expiredMints) do
        local mint = PendingMints[mintId]
        if mint then
            -- Notify user of timeout
            ao.send({
                Target = mint.user,
                Action = "MintTIM3-Timeout",
                Data = json.encode({
                    mintId = mintId,
                    message = "Operation timed out after " .. Config.pendingTimeout .. " seconds"
                })
            })
            PendingMints[mintId] = nil
        end
    end
    
    -- Clean up expired burns
    for _, burnId in ipairs(expiredBurns) do
        local burn = PendingBurns[burnId]
        if burn then
            -- Notify user of timeout
            ao.send({
                Target = burn.user,
                Action = "BurnTIM3-Timeout",
                Data = json.encode({
                    burnId = burnId,
                    message = "Operation timed out after " .. Config.pendingTimeout .. " seconds"
                })
            })
            PendingBurns[burnId] = nil
        end
    end
    
    return #expiredMints + #expiredBurns  -- Return count of cleaned operations
end

-- Emergency Pause Handler
Handlers.add(
    "EmergencyPause",
    Handlers.utils.hasMatchingTag("Action", "EmergencyPause"),
    function(msg)
        -- Check if sender is admin
        if Config.adminProcess and msg.From ~= Config.adminProcess then
            ao.send({
                Target = msg.From,
                Action = "EmergencyPause-Error",
                Data = "Unauthorized - only admin can pause system"
            })
            return
        end
        
        local pause = msg.Tags.Pause == "true"
        Config.emergencyPaused = pause
        Config.systemActive = not pause  -- Deactivate system if paused
        
        -- Log the action
        ao.send({
            Target = ao.id,
            Action = "EmergencyPause-Log",
            Data = json.encode({
                paused = pause,
                by = msg.From,
                timestamp = os.time(),
                reason = msg.Tags.Reason or "No reason provided"
            })
        })
        
        -- Send response
        ao.send({
            Target = msg.From,
            Action = "EmergencyPause-Response",
            Data = json.encode({
                emergencyPaused = Config.emergencyPaused,
                systemActive = Config.systemActive,
                timestamp = os.time()
            })
        })
    end
)

-- Configuration Handler
Handlers.add(
    "Configure",
    Handlers.utils.hasMatchingTag("Action", "Configure"),
    function(msg)
        local configType = msg.Tags.ConfigType
        local value = msg.Tags.Value
        
        if configType == "MockUsdaProcess" then
            Config.mockUsdaProcess = value
        elseif configType == "StateManagerProcess" then
            Config.stateManagerProcess = value
        elseif configType == "LockManagerProcess" then
            Config.lockManagerProcess = value
        elseif configType == "TokenManagerProcess" then
            Config.tokenManagerProcess = value
        elseif configType == "AllowedUSDAProcess" then
            Config.allowedUsdaProcess = value
        elseif configType == "CollateralRatio" then
            Config.collateralRatio = tonumber(value) or Config.collateralRatio
        elseif configType == "SystemActive" then
            Config.systemActive = value == "true"
        elseif configType == "AdminProcess" then
            Config.adminProcess = value
        elseif configType == "PendingTimeout" then
            Config.pendingTimeout = tonumber(value) or Config.pendingTimeout
        else
            ao.send({
                Target = msg.From,
                Action = "Configure-Error",
                Data = "Unknown configuration type: " .. (configType or "nil")
            })
            return
        end
        
        updateProcessInfo()
        
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
        updateProcessInfo()
        ao.send({
            Target = msg.From,
            Action = "Info-Response",
            Data = json.encode(ProcessInfo)
        })
    end
)

-- Get User Position Handler
Handlers.add(
    "GetPosition",
    Handlers.utils.hasMatchingTag("Action", "GetPosition"),
    function(msg)
        local user = msg.Tags.User or msg.From
        local position = UserPositions[user] or {
            collateral = 0,
            tim3Minted = 0,
            collateralRatio = 0,
            healthFactor = 0
        }
        
        -- Calculate health factor (higher is better)
        if position.tim3Minted > 0 then
            position.collateralRatio = position.collateral / position.tim3Minted
            position.healthFactor = position.collateralRatio / Config.collateralRatio
        end
        
        ao.send({
            Target = msg.From,
            Action = "Position-Response",
            Data = json.encode({
                user = user,
                position = position
            })
        })
    end
)

-- Mint TIM3 Handler (Main Operation)
Handlers.add(
    "MintTIM3",
    Handlers.utils.hasMatchingTag("Action", "MintTIM3"),
    function(msg)
        local user = msg.From
        local tim3Amount = tonumber(msg.Tags.Amount or msg.Tags.Quantity)
        
        -- System status check
        if not Config.systemActive or Config.emergencyPaused then
            ao.send({
                Target = msg.From,
                Action = "MintTIM3-Error",
                Data = Config.emergencyPaused and "System is in emergency pause" or "System is currently inactive"
            })
            return
        end
        
        -- Validate TIM3 amount
        local valid, error = validateAmount(tim3Amount)
        if not valid then
            ao.send({
                Target = msg.From,
                Action = "MintTIM3-Error",
                Data = error
            })
            return
        end
        
        -- Validate circuit breakers
        local circuitOk, circuitError = validateCircuitBreakers(user, tim3Amount)
        if not circuitOk then
            ao.send({
                Target = msg.From,
                Action = "MintTIM3-Error",
                Data = circuitError
            })
            return
        end
        
        -- Calculate required USDA collateral
        local requiredCollateral = calculateRequiredCollateral(tim3Amount)
        
        -- Check if Mock USDA process is configured
        if not Config.mockUsdaProcess then
            ao.send({
                Target = msg.From,
                Action = "MintTIM3-Error",
                Data = "Mock USDA process not configured"
            })
            return
        end
        
        -- Generate mint operation ID
        local mintId = user .. "-mint-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
        
        -- Create pending mint record
        PendingMints[mintId] = {
            mintId = mintId,
            user = user,
            tim3Amount = tim3Amount,
            requiredCollateral = requiredCollateral,
            timestamp = os.time(),
            status = "pending"
        }
        
        -- Step 1: Request USDA lock from Lock Manager
        ao.send({
            Target = Config.lockManagerProcess,
            Action = "LockCollateral",
            Tags = {
                User = user,
                Amount = tostring(requiredCollateral),
                Purpose = "TIM3-mint-" .. mintId
            }
        })
        
        -- Send pending response to user
        ao.send({
            Target = msg.From,
            Action = "MintTIM3-Pending",
            Data = json.encode({
                mintId = mintId,
                user = user,
                tim3Amount = tostring(formatAmount(tim3Amount)),
                requiredCollateral = tostring(formatAmount(requiredCollateral)),
                status = "pending-collateral-lock"
            })
        })
        
        return -- Don't update positions until lock is confirmed
        
    end
)

-- Lock Confirmation Handler (from Lock Manager)
Handlers.add(
    "LockCollateral-Success",
    Handlers.utils.hasMatchingTag("Action", "LockCollateral-Success"),
    function(msg)
        -- Only accept confirmations from configured Lock Manager
        if msg.From ~= Config.lockManagerProcess then
            return
        end
        
        local lockData = json.decode(msg.Data or "{}")
        local purpose = lockData.purpose or ""
        
        -- Extract mint ID from purpose
        local mintId = purpose:match("TIM3%-mint%-(.+)")
        if not mintId or not PendingMints[mintId] then
            return
        end
        
        local pendingMint = PendingMints[mintId]
        local user = pendingMint.user
        local tim3Amount = pendingMint.tim3Amount
        local requiredCollateral = pendingMint.requiredCollateral
        
        -- Check if token manager is configured
        if not Config.tokenManagerProcess then
            ao.send({
                Target = user,
                Action = "MintTIM3-Error",
                Data = "Token manager not configured"
            })
            return
        end
        
        -- Step 2: Request TIM3 minting
        ao.send({
            Target = Config.tokenManagerProcess,
            Action = "Mint",
            Tags = {
                Recipient = user,
                Amount = tostring(tim3Amount),
                Purpose = "TIM3-mint-" .. mintId
            }
        })
        
        -- Update pending status
        pendingMint.status = "pending-token-mint"
        pendingMint.lockId = lockData.lockId
        
        -- Send progress update
        ao.send({
            Target = user,
            Action = "MintTIM3-Progress",
            Data = json.encode({
                mintId = mintId,
                status = "collateral-locked-minting-tokens"
            })
        })
    end
)

-- USDA Credit Notice → Mint TIM3 (1:1 deposit-based)
Handlers.add(
    "USDA-Credit-Notice",
    Handlers.utils.hasMatchingTag("Action", "Credit-Notice"),
    function(msg)
        -- Guards
        if not Config.systemActive or Config.emergencyPaused then return end
        if not Config.tokenManagerProcess then return end
        if not Config.allowedUsdaProcess or msg.From ~= Config.allowedUsdaProcess then return end
        if msg.To and msg.To ~= ao.id then return end

        local sender = msg.Tags.Sender or msg.From
        local quantity = tonumber(msg.Tags.Quantity)
        if not quantity or quantity <= 0 then return end

        local tim3Amount = quantity -- 1:1

        -- Generate a simple pending op id to attribute collateral on Mint-Response
        local mintId = sender .. "-deposit-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
        PendingMints[mintId] = {
            mintId = mintId,
            user = sender,
            tim3Amount = tim3Amount,
            requiredCollateral = tim3Amount,
            timestamp = os.time(),
            status = "pending-token-mint"
        }

        ao.send({
            Target = Config.tokenManagerProcess,
            Action = "Mint",
            Tags = {
                Recipient = sender,
                Amount = tostring(tim3Amount),
                Purpose = "TIM3-mint-" .. mintId
            }
        })
    end
)

-- Mint Confirmation Handler (from Token Manager)
Handlers.add(
    "Mint-Response",
    Handlers.utils.hasMatchingTag("Action", "Mint-Response"),
    function(msg)
        -- Only accept confirmations from configured Token Manager
        if msg.From ~= Config.tokenManagerProcess then
            return
        end
        
        local mintData = json.decode(msg.Data or "{}")
        local purpose = mintData.purpose or ""
        
        -- Extract mint ID from purpose
        local mintId = purpose:match("TIM3%-mint%-(.+)")
        if not mintId or not PendingMints[mintId] then
            return
        end
        
        local pendingMint = PendingMints[mintId]
        local user = pendingMint.user
        local tim3Amount = pendingMint.tim3Amount
        local requiredCollateral = pendingMint.requiredCollateral
        
        -- Update user position
        local currentPosition = UserPositions[user] or {
            collateral = 0,
            tim3Minted = 0,
            collateralRatio = 0,
            healthFactor = 0
        }
        
        currentPosition.collateral = currentPosition.collateral + requiredCollateral
        currentPosition.tim3Minted = currentPosition.tim3Minted + tim3Amount
        currentPosition.collateralRatio = currentPosition.collateral / currentPosition.tim3Minted
        currentPosition.healthFactor = currentPosition.collateralRatio
        
        UserPositions[user] = currentPosition
        
        -- Update global state
        Config.totalCollateral = Config.totalCollateral + requiredCollateral
        Config.totalTIM3Minted = Config.totalTIM3Minted + tim3Amount
        updateProcessInfo()
        
        -- Update State Manager with position change
        if Config.stateManagerProcess then
            ao.send({
                Target = Config.stateManagerProcess,
                Action = "UpdatePosition",
                Tags = {
                    User = user,
                    TokenType = "TIM3", 
                    Amount = tostring(tim3Amount),
                    Operation = "mint",
                    CollateralType = "USDA",
                    CollateralAmount = tostring(requiredCollateral),
                    Timestamp = tostring(os.time())
                }
            })
        end
        
        -- Update circuit breaker counters
        updateCircuitBreakerCounters(user, tim3Amount)
        
        -- Remove from pending
        PendingMints[mintId] = nil
        
        -- Send success response
        ao.send({
            Target = user,
            Action = "MintTIM3-Response",
            Data = json.encode({
                mintId = mintId,
                user = user,
                tim3Minted = tostring(formatAmount(tim3Amount)),
                collateralLocked = tostring(formatAmount(requiredCollateral)),
                newPosition = {
                    collateral = tostring(formatAmount(currentPosition.collateral)),
                    tim3Minted = tostring(formatAmount(currentPosition.tim3Minted)),
                    collateralRatio = tostring(formatAmount(currentPosition.collateralRatio)),
                    healthFactor = tostring(formatAmount(currentPosition.healthFactor))
                }
            })
        })
        
        -- Log the operation
        ao.send({
            Target = ao.id,
            Action = "MintTIM3-Log",
            Data = json.encode({
                mintId = mintId,
                user = user,
                tim3Amount = tim3Amount,
                collateralAmount = requiredCollateral,
                timestamp = tostring(os.time())
            })
        })
    end
)

-- Burn TIM3 Handler (Reverse Operation - Atomic)
Handlers.add(
    "BurnTIM3",
    Handlers.utils.hasMatchingTag("Action", "BurnTIM3"),
    function(msg)
        local user = msg.From
        local tim3Amount = tonumber(msg.Tags.Amount or msg.Tags.Quantity)
        
        -- System status check
        if not Config.systemActive or Config.emergencyPaused then
            ao.send({
                Target = msg.From,
                Action = "BurnTIM3-Error",
                Data = Config.emergencyPaused and "System is in emergency pause" or "System is currently inactive"
            })
            return
        end
        
        -- Validate TIM3 amount
        if not tim3Amount or tim3Amount <= 0 then
            ao.send({
                Target = msg.From,
                Action = "BurnTIM3-Error",
                Data = "Invalid burn amount"
            })
            return
        end
        
        -- Check user position
        local currentPosition = UserPositions[user]
        if not currentPosition or currentPosition.tim3Minted < tim3Amount then
            ao.send({
                Target = msg.From,
                Action = "BurnTIM3-Error", 
                Data = "Insufficient TIM3 balance to burn"
            })
            return
        end
        
        -- Check if token manager is configured
        if not Config.tokenManagerProcess then
            ao.send({
                Target = msg.From,
                Action = "BurnTIM3-Error",
                Data = "Token manager not configured"
            })
            return
        end
        
        -- Calculate collateral to release with exact precision
        local collateralToRelease = tim3Amount * Config.collateralRatio
        
        -- Generate burn operation ID
        local burnId = user .. "-burn-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
        
        -- Create pending burn record
        PendingBurns[burnId] = {
            burnId = burnId,
            user = user,
            tim3Amount = tim3Amount,
            collateralToRelease = collateralToRelease,
            timestamp = os.time(),
            status = "pending-burn"
        }
        
        -- Step 1: Request TIM3 burn from Token Manager
        ao.send({
            Target = Config.tokenManagerProcess,
            Action = "Burn",
            Tags = {
                User = user,
                Amount = tostring(tim3Amount),
                Purpose = "TIM3-burn-" .. burnId
            }
        })
        
        -- Send pending response to user
        ao.send({
            Target = msg.From,
            Action = "BurnTIM3-Pending",
            Data = json.encode({
                burnId = burnId,
                user = user,
                tim3Amount = tostring(formatAmount(tim3Amount)),
                collateralToRelease = tostring(formatAmount(collateralToRelease)),
                status = "pending-token-burn"
            })
        })
        
        return -- Don't update positions until burn is confirmed
    end
)

-- Burn Confirmation Handler (from Token Manager)
Handlers.add(
    "Burn-Response",
    Handlers.utils.hasMatchingTag("Action", "Burn-Response"),
    function(msg)
        -- Only accept confirmations from configured Token Manager
        if msg.From ~= Config.tokenManagerProcess then
            return
        end
        
        local burnData = json.decode(msg.Data or "{}")
        local burnId = burnData.burnId
        
        -- Extract burn ID from data or purpose
        if not burnId and burnData.purpose then
            burnId = burnData.purpose:match("TIM3%-burn%-(.+)")
        end
        
        if not burnId or not PendingBurns[burnId] then
            return
        end
        
        local pendingBurn = PendingBurns[burnId]
        local user = pendingBurn.user
        local tim3Amount = pendingBurn.tim3Amount
        local collateralToRelease = pendingBurn.collateralToRelease
        
        -- Check if lock manager is configured
        if not Config.lockManagerProcess then
            ao.send({
                Target = user,
                Action = "BurnTIM3-Error",
                Data = "Lock manager not configured"
            })
            PendingBurns[burnId] = nil
            return
        end
        
        -- Step 2: Request USDA unlock from Lock Manager
        ao.send({
            Target = Config.lockManagerProcess,
            Action = "UnlockCollateral",
            Tags = {
                User = user,
                Amount = tostring(collateralToRelease),
                Purpose = "TIM3-burn-" .. burnId
            }
        })
        
        -- Update pending status
        pendingBurn.status = "pending-unlock"
        
        -- Send progress update
        ao.send({
            Target = user,
            Action = "BurnTIM3-Progress",
            Data = json.encode({
                burnId = burnId,
                status = "tokens-burned-unlocking-collateral"
            })
        })
    end
)

-- Unlock Confirmation Handler (from Lock Manager)
Handlers.add(
    "UnlockCollateral-Success",
    Handlers.utils.hasMatchingTag("Action", "UnlockCollateral-Success"),
    function(msg)
        -- Only accept confirmations from configured Lock Manager
        if msg.From ~= Config.lockManagerProcess then
            return
        end
        
        local unlockData = json.decode(msg.Data or "{}")
        
        -- Find matching pending burn by user and amount
        local burnId = nil
        local pendingBurn = nil
        
        for id, burn in pairs(PendingBurns) do
            if burn.user == unlockData.user and 
               tostring(burn.collateralToRelease) == tostring(tonumber(unlockData.unlockedAmount or "0")) and
               burn.status == "pending-unlock" then
                burnId = id
                pendingBurn = burn
                break
            end
        end
        
        if not pendingBurn then
            return
        end
        
        local user = pendingBurn.user
        local tim3Amount = pendingBurn.tim3Amount
        local collateralToRelease = pendingBurn.collateralToRelease
        
        -- Update user position
        local currentPosition = UserPositions[user] or {
            collateral = 0,
            tim3Minted = 0,
            collateralRatio = 0,
            healthFactor = 0
        }
        
        currentPosition.collateral = currentPosition.collateral - collateralToRelease
        currentPosition.tim3Minted = currentPosition.tim3Minted - tim3Amount
        
        if currentPosition.tim3Minted > 0 then
            currentPosition.collateralRatio = currentPosition.collateral / currentPosition.tim3Minted
            currentPosition.healthFactor = currentPosition.collateralRatio / Config.collateralRatio
        else
            currentPosition.collateralRatio = 0
            currentPosition.healthFactor = 0
        end
        
        UserPositions[user] = currentPosition
        
        -- Update global state
        Config.totalCollateral = Config.totalCollateral - collateralToRelease
        Config.totalTIM3Minted = Config.totalTIM3Minted - tim3Amount
        updateProcessInfo()
        
        -- Update State Manager with position change
        if Config.stateManagerProcess then
            ao.send({
                Target = Config.stateManagerProcess,
                Action = "UpdatePosition", 
                Tags = {
                    User = user,
                    TokenType = "TIM3",
                    Amount = "-" .. tostring(tim3Amount), -- Negative for burn
                    Operation = "burn",
                    CollateralType = "USDA", 
                    CollateralAmount = "-" .. tostring(collateralToRelease),
                    Timestamp = tostring(os.time())
                }
            })
        end
        
        -- Remove from pending
        PendingBurns[burnId] = nil
        
        -- Send success response
        ao.send({
            Target = user,
            Action = "BurnTIM3-Response",
            Data = json.encode({
                burnId = burnId,
                user = user,
                tim3Burned = tostring(formatAmount(tim3Amount)),
                collateralReleased = tostring(formatAmount(collateralToRelease)),
                newPosition = {
                    collateral = tostring(formatAmount(currentPosition.collateral)),
                    tim3Minted = tostring(formatAmount(currentPosition.tim3Minted)),
                    collateralRatio = tostring(formatAmount(currentPosition.collateralRatio)),
                    healthFactor = tostring(formatAmount(currentPosition.healthFactor))
                }
            })
        })
        
        -- Log the operation
        ao.send({
            Target = ao.id,
            Action = "BurnTIM3-Log",
            Data = json.encode({
                burnId = burnId,
                user = user,
                tim3Amount = tim3Amount,
                collateralReleased = collateralToRelease,
                timestamp = tostring(os.time())
            })
        })
    end
)

-- Cleanup Expired Operations Handler
Handlers.add(
    "CleanupExpired",
    Handlers.utils.hasMatchingTag("Action", "CleanupExpired"),
    function(msg)
        local cleanedCount = cleanupExpiredOperations()
        
        ao.send({
            Target = msg.From,
            Action = "CleanupExpired-Response",
            Data = json.encode({
                cleanedOperations = cleanedCount,
                timestamp = os.time()
            })
        })
    end
)

-- System Health Handler
Handlers.add(
    "SystemHealth",
    Handlers.utils.hasMatchingTag("Action", "SystemHealth"),
    function(msg)
        -- Clean up expired operations when checking health
        cleanupExpiredOperations()
        local globalCollateralRatio = 0
        if Config.totalTIM3Minted > 0 then
            globalCollateralRatio = Config.totalCollateral / Config.totalTIM3Minted
        end
        
        local systemHealth = {
            systemActive = Config.systemActive,
            totalCollateral = tostring(formatAmount(Config.totalCollateral)),
            totalTIM3Minted = tostring(formatAmount(Config.totalTIM3Minted)),
            globalCollateralRatio = tostring(formatAmount(globalCollateralRatio)),
            targetCollateralRatio = tostring(formatAmount(Config.collateralRatio)),
            userPositions = 0
        }
        
        -- Count active user positions
        for user, position in pairs(UserPositions) do
            if position.tim3Minted > 0 then
                systemHealth.userPositions = systemHealth.userPositions + 1
            end
        end
        
        ao.send({
            Target = msg.From,
            Action = "SystemHealth-Response",
            Data = json.encode(systemHealth)
        })
    end
)

-- Configuration Handlers
Handlers.add(
    "SetProcessConfig",
    Handlers.utils.hasMatchingTag("Action", "SetProcessConfig"),
    function(msg)
        -- Update process configurations
        if msg.Tags.MockUsdaProcess then
            Config.mockUsdaProcess = msg.Tags.MockUsdaProcess
        end
        if msg.Tags.StateManagerProcess then
            Config.stateManagerProcess = msg.Tags.StateManagerProcess
        end
        if msg.Tags.LockManagerProcess then
            Config.lockManagerProcess = msg.Tags.LockManagerProcess
        end
        if msg.Tags.TokenManagerProcess then
            Config.tokenManagerProcess = msg.Tags.TokenManagerProcess
        end
        if msg.Tags.AllowedUSDAProcess then
            Config.allowedUsdaProcess = msg.Tags.AllowedUSDAProcess
        end
        
        -- Update process info
        updateProcessInfo()
        
        -- Send confirmation
        ao.send({
            Target = msg.From,
            Action = "SetProcessConfig-Response",
            Data = json.encode({
                mockUsdaProcess = Config.mockUsdaProcess,
                allowedUsdaProcess = Config.allowedUsdaProcess,
                stateManagerProcess = Config.stateManagerProcess,
                lockManagerProcess = Config.lockManagerProcess,
                tokenManagerProcess = Config.tokenManagerProcess,
                timestamp = os.time()
            })
        })
    end
)

-- Individual Process Configuration Handlers
Handlers.add(
    "SetMockUsdaProcess",
    Handlers.utils.hasMatchingTag("Action", "SetMockUsdaProcess"),
    function(msg)
        Config.mockUsdaProcess = msg.Tags.ProcessId or msg.Data
        updateProcessInfo()
        
        ao.send({
            Target = msg.From,
            Action = "SetMockUsdaProcess-Response",
            Data = json.encode({
                mockUsdaProcess = Config.mockUsdaProcess,
                status = "configured"
            })
        })
    end
)

Handlers.add(
    "SetStateManagerProcess",
    Handlers.utils.hasMatchingTag("Action", "SetStateManagerProcess"),
    function(msg)
        Config.stateManagerProcess = msg.Tags.ProcessId or msg.Data
        updateProcessInfo()
        
        ao.send({
            Target = msg.From,
            Action = "SetStateManagerProcess-Response",
            Data = json.encode({
                stateManagerProcess = Config.stateManagerProcess,
                status = "configured"
            })
        })
    end
)

Handlers.add(
    "SetLockManagerProcess",
    Handlers.utils.hasMatchingTag("Action", "SetLockManagerProcess"),
    function(msg)
        Config.lockManagerProcess = msg.Tags.ProcessId or msg.Data
        updateProcessInfo()
        
        ao.send({
            Target = msg.From,
            Action = "SetLockManagerProcess-Response",
            Data = json.encode({
                lockManagerProcess = Config.lockManagerProcess,
                status = "configured"
            })
        })
    end
)

Handlers.add(
    "SetTokenManagerProcess",
    Handlers.utils.hasMatchingTag("Action", "SetTokenManagerProcess"),
    function(msg)
        Config.tokenManagerProcess = msg.Tags.ProcessId or msg.Data
        updateProcessInfo()
        
        ao.send({
            Target = msg.From,
            Action = "SetTokenManagerProcess-Response",
            Data = json.encode({
                tokenManagerProcess = Config.tokenManagerProcess,
                status = "configured"
            })
        })
    end
)

-- Configuration Status Handler
Handlers.add(
    "GetConfig",
    Handlers.utils.hasMatchingTag("Action", "GetConfig"),
    function(msg)
        ao.send({
            Target = msg.From,
            Action = "GetConfig-Response",
            Data = json.encode({
                processes = {
                    mockUsdaProcess = Config.mockUsdaProcess,
                    allowedUsdaProcess = Config.allowedUsdaProcess,
                    stateManagerProcess = Config.stateManagerProcess,
                    lockManagerProcess = Config.lockManagerProcess,
                    tokenManagerProcess = Config.tokenManagerProcess
                },
                systemConfig = {
                    collateralRatio = Config.collateralRatio,
                    minMintAmount = Config.minMintAmount,
                    maxMintAmount = Config.maxMintAmount,
                    systemActive = Config.systemActive
                },
                timestamp = os.time()
            })
        })
    end
)
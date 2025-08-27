-- TIM3 Coordinator Process
-- Main orchestrator for the TIM3 collateralized token system
-- Coordinates USDA locking and TIM3 minting operations

local json = require("cjson")

-- Initialize process state
Name = Name or "TIM3 Coordinator"
Ticker = Ticker or "TIM3-COORD"
Version = Version or "1.0.0"

-- Process Configuration
Config = Config or {
    -- Specialist process addresses (will be set via configuration messages)
    mockUsdaProcess = nil,
    stateManagerProcess = nil,
    lockManagerProcess = nil,
    tokenManagerProcess = nil,
    
    -- System parameters
    collateralRatio = 1.0,  -- 1:1 USDA backing ratio
    minMintAmount = 10,     -- Minimum TIM3 mint amount
    maxMintAmount = 100000, -- Maximum TIM3 mint amount
    
    -- System status
    systemActive = true,
    totalCollateral = 0,
    totalTIM3Minted = 0
}

-- User positions tracking
UserPositions = UserPositions or {}

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
    return math.ceil(tim3Amount * Config.collateralRatio)
end

local function updateProcessInfo()
    ProcessInfo.systemActive = Config.systemActive
    ProcessInfo.totalCollateral = Config.totalCollateral
    ProcessInfo.totalTIM3Minted = Config.totalTIM3Minted
    ProcessInfo.collateralRatio = Config.collateralRatio
end

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
        elseif configType == "CollateralRatio" then
            Config.collateralRatio = tonumber(value) or Config.collateralRatio
        elseif configType == "SystemActive" then
            Config.systemActive = value == "true"
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
        if not Config.systemActive then
            ao.send({
                Target = msg.From,
                Action = "MintTIM3-Error",
                Data = "System is currently inactive"
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
        
        -- Step 1: Request USDA lock (simulate the flow for now)
        -- In a complete system, this would be an async operation
        -- For now, we'll simulate successful collateral locking
        
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
        
        -- Send success response
        ao.send({
            Target = msg.From,
            Action = "MintTIM3-Response",
            Data = json.encode({
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
                user = user,
                tim3Amount = tim3Amount,
                collateralAmount = requiredCollateral,
                timestamp = tostring(os.time())
            })
        })
    end
)

-- Burn TIM3 Handler (Reverse Operation)
Handlers.add(
    "BurnTIM3",
    Handlers.utils.hasMatchingTag("Action", "BurnTIM3"),
    function(msg)
        local user = msg.From
        local tim3Amount = tonumber(msg.Tags.Amount or msg.Tags.Quantity)
        
        -- System status check
        if not Config.systemActive then
            ao.send({
                Target = msg.From,
                Action = "BurnTIM3-Error",
                Data = "System is currently inactive"
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
        
        -- Calculate collateral to release
        local collateralToRelease = math.floor((tim3Amount / currentPosition.tim3Minted) * currentPosition.collateral)
        
        -- Update user position
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
        
        -- Send success response
        ao.send({
            Target = msg.From,
            Action = "BurnTIM3-Response",
            Data = json.encode({
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
                user = user,
                tim3Amount = tim3Amount,
                collateralReleased = collateralToRelease,
                timestamp = tostring(os.time())
            })
        })
    end
)

-- System Health Handler
Handlers.add(
    "SystemHealth",
    Handlers.utils.hasMatchingTag("Action", "SystemHealth"),
    function(msg)
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
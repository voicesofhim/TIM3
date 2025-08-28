-- TIM3 State Manager Process
-- Tracks collateral ratios, system health, and risk management
-- Maintains global system state and user position tracking

-- JSON is available globally in AO environment

-- Initialize process state
Name = Name or "TIM3 State Manager"
Ticker = Ticker or "TIM3-STATE"
Version = Version or "1.0.0"

-- System State Tracking
SystemState = SystemState or {
    totalCollateral = 0,
    totalTIM3Supply = 0,
    globalCollateralRatio = 0,
    targetCollateralRatio = 1.0,
    activePositions = 0,
    systemHealthScore = 100
}

-- User Position Tracking
UserPositions = UserPositions or {}

-- Risk Metrics
RiskMetrics = RiskMetrics or {
    underCollateralizedPositions = 0,
    atRiskPositions = 0,
    healthyPositions = 0,
    averageHealthFactor = 0
}

-- Process Configuration
Config = Config or {
    coordinatorProcess = nil,
    lockManagerProcess = nil,
    tokenManagerProcess = nil,
    updateFrequency = 60,  -- seconds
    riskThresholds = {
        healthy = 1.0,     -- At or above 100% backing
        warning = 0.95,    -- 95-100% backing (minor variance)
        danger = 0.90,     -- 90-95% backing (system stress)
        critical = 0.85    -- Below 85% backing (system intervention needed)
    }
}

-- Helper Functions
local function formatAmount(amount)
    if not amount then return 0 end
    if amount == math.floor(amount) then
        return math.floor(amount)
    else
        return math.floor(amount * 1000000) / 1000000
    end
end

local function calculateHealthFactor(collateral, debt)
    if debt <= 0 then return 999.0 end
    return collateral / debt
end

local function getRiskLevel(healthFactor)
    local thresholds = Config.riskThresholds
    
    if healthFactor >= thresholds.healthy then
        return "healthy"
    elseif healthFactor >= thresholds.warning then
        return "warning"
    elseif healthFactor >= thresholds.danger then
        return "danger"
    else
        return "critical"
    end
end

local function updateSystemMetrics()
    -- Calculate global collateral ratio
    if SystemState.totalTIM3Supply > 0 then
        SystemState.globalCollateralRatio = SystemState.totalCollateral / SystemState.totalTIM3Supply
    else
        SystemState.globalCollateralRatio = 0
    end
    
    -- Reset risk counters
    RiskMetrics.underCollateralizedPositions = 0
    RiskMetrics.atRiskPositions = 0
    RiskMetrics.healthyPositions = 0
    
    local totalHealthFactor = 0
    local positionCount = 0
    
    -- Analyze all user positions
    for user, position in pairs(UserPositions) do
        -- Ensure position has valid values
        position.collateral = position.collateral or 0
        position.tim3Balance = position.tim3Balance or 0
        
        if position.tim3Balance > 0 then
            positionCount = positionCount + 1
            local healthFactor = calculateHealthFactor(position.collateral, position.tim3Balance)
            position.healthFactor = healthFactor
            position.riskLevel = getRiskLevel(healthFactor)
            
            totalHealthFactor = totalHealthFactor + healthFactor
            
            -- Update risk counters
            if position.riskLevel == "critical" then
                RiskMetrics.underCollateralizedPositions = RiskMetrics.underCollateralizedPositions + 1
            elseif position.riskLevel == "danger" or position.riskLevel == "warning" then
                RiskMetrics.atRiskPositions = RiskMetrics.atRiskPositions + 1
            else
                RiskMetrics.healthyPositions = RiskMetrics.healthyPositions + 1
            end
        end
    end
    
    SystemState.activePositions = positionCount
    
    -- Calculate average health factor
    if positionCount > 0 then
        RiskMetrics.averageHealthFactor = totalHealthFactor / positionCount
    else
        RiskMetrics.averageHealthFactor = 0
    end
    
    -- Calculate system health score (0-100)
    local healthScore = 100
    if RiskMetrics.underCollateralizedPositions > 0 then
        healthScore = healthScore - (RiskMetrics.underCollateralizedPositions * 20)
    end
    if RiskMetrics.atRiskPositions > 0 then
        healthScore = healthScore - (RiskMetrics.atRiskPositions * 10)
    end
    if SystemState.globalCollateralRatio < SystemState.targetCollateralRatio then
        healthScore = healthScore - 15
    end
    
    SystemState.systemHealthScore = math.max(0, healthScore)
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
        elseif configType == "LockManagerProcess" then
            Config.lockManagerProcess = value
        elseif configType == "TokenManagerProcess" then
            Config.tokenManagerProcess = value
        elseif configType == "TargetCollateralRatio" then
            SystemState.targetCollateralRatio = tonumber(value) or SystemState.targetCollateralRatio
        elseif configType == "LiquidationThreshold" then
            SystemState.liquidationThreshold = tonumber(value) or SystemState.liquidationThreshold
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
        updateSystemMetrics()
        
        ao.send({
            Target = msg.From,
            Action = "Info-Response",
            Data = json.encode({
                name = Name,
                ticker = Ticker,
                version = Version,
                systemState = SystemState,
                riskMetrics = RiskMetrics
            })
        })
    end
)

-- Update Position Handler (called by other processes)
Handlers.add(
    "UpdatePosition",
    Handlers.utils.hasMatchingTag("Action", "UpdatePosition"),
    function(msg)
        local user = msg.Tags.User
        local collateral = tonumber(msg.Tags.Collateral or "0")
        local tim3Balance = tonumber(msg.Tags.TIM3Balance or "0")
        local operation = msg.Tags.Operation or "update"
        
        if not user then
            ao.send({
                Target = msg.From,
                Action = "UpdatePosition-Error",
                Data = "User required"
            })
            return
        end
        
        -- Initialize or update user position
        if not UserPositions[user] then
            UserPositions[user] = {
                collateral = 0,
                tim3Balance = 0,
                healthFactor = 0,
                riskLevel = "healthy",
                lastUpdate = os.time()
            }
        end
        
        -- Ensure position has valid numeric values
        local position = UserPositions[user]
        position.collateral = position.collateral or 0
        position.tim3Balance = position.tim3Balance or 0
        
        local oldCollateral = position.collateral
        local oldTIM3 = position.tim3Balance
        
        -- Update position
        if operation == "add" then
            position.collateral = position.collateral + collateral
            position.tim3Balance = position.tim3Balance + tim3Balance
        elseif operation == "subtract" then
            position.collateral = position.collateral - collateral
            position.tim3Balance = position.tim3Balance - tim3Balance
        else
            position.collateral = collateral
            position.tim3Balance = tim3Balance
        end
        
        position.lastUpdate = os.time()
        
        -- Update system totals
        SystemState.totalCollateral = SystemState.totalCollateral + (position.collateral - oldCollateral)
        SystemState.totalTIM3Supply = SystemState.totalTIM3Supply + (position.tim3Balance - oldTIM3)
        
        -- Recalculate metrics
        updateSystemMetrics()
        
        ao.send({
            Target = msg.From,
            Action = "UpdatePosition-Response",
            Data = json.encode({
                user = user,
                position = {
                    collateral = tostring(formatAmount(position.collateral)),
                    tim3Balance = tostring(formatAmount(position.tim3Balance)),
                    healthFactor = tostring(formatAmount(position.healthFactor)),
                    riskLevel = position.riskLevel
                },
                systemState = {
                    totalCollateral = tostring(formatAmount(SystemState.totalCollateral)),
                    totalTIM3Supply = tostring(formatAmount(SystemState.totalTIM3Supply)),
                    globalCollateralRatio = tostring(formatAmount(SystemState.globalCollateralRatio))
                }
            })
        })
    end
)

-- Get Position Handler
Handlers.add(
    "GetPosition",
    Handlers.utils.hasMatchingTag("Action", "GetPosition"),
    function(msg)
        local user = msg.Tags.User or msg.From
        local position = UserPositions[user]
        
        if not position then
            position = {
                collateral = 0,
                tim3Balance = 0,
                healthFactor = 0,
                riskLevel = "healthy",
                lastUpdate = 0
            }
        else
            -- Recalculate current health metrics
            position.healthFactor = calculateHealthFactor(position.collateral, position.tim3Balance)
            position.riskLevel = getRiskLevel(position.healthFactor)
        end
        
        ao.send({
            Target = msg.From,
            Action = "Position-Response",
            Data = json.encode({
                user = user,
                position = {
                    collateral = tostring(formatAmount(position.collateral)),
                    tim3Balance = tostring(formatAmount(position.tim3Balance)),
                    healthFactor = tostring(formatAmount(position.healthFactor)),
                    riskLevel = position.riskLevel,
                    lastUpdate = position.lastUpdate
                }
            })
        })
    end
)

-- System Health Handler
Handlers.add(
    "SystemHealth",
    Handlers.utils.hasMatchingTag("Action", "SystemHealth"),
    function(msg)
        updateSystemMetrics()
        
        ao.send({
            Target = msg.From,
            Action = "SystemHealth-Response",
            Data = json.encode({
                systemState = {
                    totalCollateral = tostring(formatAmount(SystemState.totalCollateral)),
                    totalTIM3Supply = tostring(formatAmount(SystemState.totalTIM3Supply)),
                    globalCollateralRatio = tostring(formatAmount(SystemState.globalCollateralRatio)),
                    targetCollateralRatio = tostring(formatAmount(SystemState.targetCollateralRatio)),
                    liquidationThreshold = tostring(formatAmount(SystemState.liquidationThreshold)),
                    activePositions = SystemState.activePositions,
                    systemHealthScore = SystemState.systemHealthScore
                },
                riskMetrics = {
                    underCollateralizedPositions = RiskMetrics.underCollateralizedPositions,
                    atRiskPositions = RiskMetrics.atRiskPositions,
                    healthyPositions = RiskMetrics.healthyPositions,
                    averageHealthFactor = tostring(formatAmount(RiskMetrics.averageHealthFactor))
                }
            })
        })
    end
)

-- Risk Alert Handler (monitors for liquidatable positions)
Handlers.add(
    "CheckRiskAlerts",
    Handlers.utils.hasMatchingTag("Action", "CheckRiskAlerts"),
    function(msg)
        updateSystemMetrics()
        
        local alerts = {}
        
        -- Check for positions requiring liquidation
        for user, position in pairs(UserPositions) do
            if position.tim3Balance > 0 and position.riskLevel == "critical" then
                table.insert(alerts, {
                    user = user,
                    riskLevel = position.riskLevel,
                    healthFactor = formatAmount(position.healthFactor),
                    collateral = formatAmount(position.collateral),
                    tim3Balance = formatAmount(position.tim3Balance)
                })
            end
        end
        
        ao.send({
            Target = msg.From,
            Action = "RiskAlerts-Response",
            Data = json.encode({
                alertCount = #alerts,
                alerts = alerts,
                systemHealthScore = SystemState.systemHealthScore
            })
        })
        
        -- Notify coordinator if there are critical alerts
        if #alerts > 0 and Config.coordinatorProcess then
            ao.send({
                Target = Config.coordinatorProcess,
                Action = "Risk-Alert",
                Data = json.encode({
                    alertCount = #alerts,
                    criticalAlerts = alerts
                })
            })
        end
    end
)

-- Liquidation Check Handler
Handlers.add(
    "CheckLiquidations",
    Handlers.utils.hasMatchingTag("Action", "CheckLiquidations"),
    function(msg)
        updateSystemMetrics()
        
        local liquidatablePositions = {}
        
        for user, position in pairs(UserPositions) do
            if position.tim3Balance > 0 and position.healthFactor < SystemState.liquidationThreshold then
                table.insert(liquidatablePositions, {
                    user = user,
                    healthFactor = formatAmount(position.healthFactor),
                    collateral = formatAmount(position.collateral),
                    tim3Balance = formatAmount(position.tim3Balance),
                    liquidationValue = formatAmount(position.tim3Balance * 0.9)  -- 10% liquidation penalty
                })
            end
        end
        
        ao.send({
            Target = msg.From,
            Action = "Liquidations-Response",
            Data = json.encode({
                liquidatableCount = #liquidatablePositions,
                positions = liquidatablePositions
            })
        })
    end
)
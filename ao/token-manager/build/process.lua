-- TIM3 Token Manager Process
-- Manages TIM3 token minting, burning, and supply operations
-- Implements ERC-20-like functionality for the TIM3 token

local json = require("cjson")

-- Initialize process state
Name = Name or "TIM3 Token Manager"
Ticker = Ticker or "TIM3-TOKEN"
Version = Version or "1.0.0"

-- TIM3 Token Info
TokenInfo = TokenInfo or {
    name = "TIM3 Token",
    ticker = "TIM3",
    denomination = 6,  -- 6 decimal places
    totalSupply = 0,
    logo = "tim3-logo"
}

-- Token Balances and Operations
Balances = Balances or {}
MintOperations = MintOperations or {}
BurnOperations = BurnOperations or {}

-- Token Statistics
TokenStats = TokenStats or {
    totalMinted = 0,
    totalBurned = 0,
    totalTransfers = 0,
    uniqueHolders = 0,
    largestBalance = 0,
    mintOperations = 0,
    burnOperations = 0
}

-- Process Configuration
Config = Config or {
    coordinatorProcess = nil,
    stateManagerProcess = nil,
    lockManagerProcess = nil,
    
    -- Token parameters
    maxSupply = 10000000,  -- 10M TIM3 max supply
    minMintAmount = 1,
    maxMintAmount = 100000,
    
    -- Security settings
    allowedMinters = {},  -- Processes that can mint
    allowedBurners = {},  -- Processes that can burn
    requireConfirmation = true,
    
    -- Features
    transfersEnabled = true,
    mintingEnabled = true,
    burningEnabled = true
}

-- Helper Functions
local function formatAmount(amount)
    if amount == math.floor(amount) then
        return math.floor(amount)
    else
        return math.floor(amount * (10 ^ TokenInfo.denomination)) / (10 ^ TokenInfo.denomination)
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

local function hasBalance(user, amount)
    local balance = Balances[user] or 0
    return balance >= amount
end

local function isAuthorizedMinter(caller)
    if not Config.requireConfirmation then
        return true
    end
    
    if caller == Config.coordinatorProcess then
        return true
    end
    
    for _, allowedMinter in ipairs(Config.allowedMinters) do
        if caller == allowedMinter then
            return true
        end
    end
    
    return false
end

local function isAuthorizedBurner(caller)
    if not Config.requireConfirmation then
        return true
    end
    
    if caller == Config.coordinatorProcess then
        return true
    end
    
    for _, allowedBurner in ipairs(Config.allowedBurners) do
        if caller == allowedBurner then
            return true
        end
    end
    
    return false
end

local function updateTokenStats()
    -- Count unique holders
    local holders = 0
    local largestBalance = 0
    
    for user, balance in pairs(Balances) do
        if balance > 0 then
            holders = holders + 1
            if balance > largestBalance then
                largestBalance = balance
            end
        end
    end
    
    TokenStats.uniqueHolders = holders
    TokenStats.largestBalance = largestBalance
    TokenInfo.totalSupply = TokenStats.totalMinted - TokenStats.totalBurned
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
        elseif configType == "LockManagerProcess" then
            Config.lockManagerProcess = value
        elseif configType == "MaxSupply" then
            Config.maxSupply = tonumber(value) or Config.maxSupply
        elseif configType == "TransfersEnabled" then
            Config.transfersEnabled = value == "true"
        elseif configType == "MintingEnabled" then
            Config.mintingEnabled = value == "true"
        elseif configType == "BurningEnabled" then
            Config.burningEnabled = value == "true"
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

-- Token Info Handler
Handlers.add(
    "Info",
    Handlers.utils.hasMatchingTag("Action", "Info"),
    function(msg)
        updateTokenStats()
        
        ao.send({
            Target = msg.From,
            Action = "Info-Response",
            Data = json.encode({
                processInfo = {
                    name = Name,
                    ticker = Ticker,
                    version = Version
                },
                tokenInfo = TokenInfo,
                tokenStats = TokenStats,
                config = {
                    maxSupply = Config.maxSupply,
                    transfersEnabled = Config.transfersEnabled,
                    mintingEnabled = Config.mintingEnabled,
                    burningEnabled = Config.burningEnabled
                }
            })
        })
    end
)

-- Balance Handler
Handlers.add(
    "Balance",
    Handlers.utils.hasMatchingTag("Action", "Balance"),
    function(msg)
        local target = msg.Tags.Target or msg.From
        local balance = Balances[target] or 0
        
        ao.send({
            Target = msg.From,
            Action = "Balance-Response",
            Data = json.encode({
                target = target,
                balance = tostring(formatAmount(balance)),
                ticker = TokenInfo.ticker
            })
        })
    end
)

-- Balances Handler (for all balances)
Handlers.add(
    "Balances",
    Handlers.utils.hasMatchingTag("Action", "Balances"),
    function(msg)
        local formattedBalances = {}
        
        for user, balance in pairs(Balances) do
            if balance > 0 then
                formattedBalances[user] = tostring(formatAmount(balance))
            end
        end
        
        ao.send({
            Target = msg.From,
            Action = "Balances-Response",
            Data = json.encode(formattedBalances)
        })
    end
)

-- Mint Handler
Handlers.add(
    "Mint",
    Handlers.utils.hasMatchingTag("Action", "Mint"),
    function(msg)
        local recipient = msg.Tags.Recipient or msg.Tags.Target
        local amount = tonumber(msg.Tags.Quantity or msg.Tags.Amount)
        local purpose = msg.Tags.Purpose or "TIM3-mint"
        
        -- Check if minting is enabled
        if not Config.mintingEnabled then
            ao.send({
                Target = msg.From,
                Action = "Mint-Error",
                Data = "Minting is currently disabled"
            })
            return
        end
        
        -- Authorization check
        if not isAuthorizedMinter(msg.From) then
            ao.send({
                Target = msg.From,
                Action = "Mint-Error",
                Data = "Unauthorized minter"
            })
            return
        end
        
        -- Validate recipient
        if not recipient then
            ao.send({
                Target = msg.From,
                Action = "Mint-Error",
                Data = "Recipient required"
            })
            return
        end
        
        -- Validate amount
        local valid, error = validateAmount(amount)
        if not valid then
            ao.send({
                Target = msg.From,
                Action = "Mint-Error",
                Data = error
            })
            return
        end
        
        -- Check max supply limit
        if TokenInfo.totalSupply + amount > Config.maxSupply then
            ao.send({
                Target = msg.From,
                Action = "Mint-Error",
                Data = "Minting would exceed max supply"
            })
            return
        end
        
        -- Generate mint operation ID
        local mintId = recipient .. "-mint-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
        
        -- Execute mint
        Balances[recipient] = (Balances[recipient] or 0) + amount
        TokenStats.totalMinted = TokenStats.totalMinted + amount
        TokenStats.mintOperations = TokenStats.mintOperations + 1
        
        -- Record mint operation
        MintOperations[mintId] = {
            mintId = mintId,
            recipient = recipient,
            amount = amount,
            minter = msg.From,
            purpose = purpose,
            timestamp = os.time()
        }
        
        -- Update token info
        updateTokenStats()
        
        -- Send success response
        ao.send({
            Target = msg.From,
            Action = "Mint-Response",
            Data = json.encode({
                mintId = mintId,
                recipient = recipient,
                amount = tostring(formatAmount(amount)),
                newBalance = tostring(formatAmount(Balances[recipient])),
                totalSupply = tostring(formatAmount(TokenInfo.totalSupply))
            })
        })
        
        -- Credit notice to recipient
        ao.send({
            Target = recipient,
            Action = "Credit-Notice",
            Data = json.encode({
                from = "TIM3-Mint",
                amount = tostring(formatAmount(amount)),
                newBalance = tostring(formatAmount(Balances[recipient])),
                mintId = mintId
            })
        })
        
        -- Notify state manager
        if Config.stateManagerProcess then
            ao.send({
                Target = Config.stateManagerProcess,
                Action = "UpdatePosition",
                Tags = {
                    User = recipient,
                    TIM3Balance = tostring(amount),
                    Operation = "add"
                }
            })
        end
    end
)

-- Burn Handler
Handlers.add(
    "Burn",
    Handlers.utils.hasMatchingTag("Action", "Burn"),
    function(msg)
        local user = msg.Tags.User or msg.From
        local amount = tonumber(msg.Tags.Quantity or msg.Tags.Amount)
        local purpose = msg.Tags.Purpose or "TIM3-burn"
        
        -- Check if burning is enabled
        if not Config.burningEnabled then
            ao.send({
                Target = msg.From,
                Action = "Burn-Error",
                Data = "Burning is currently disabled"
            })
            return
        end
        
        -- Authorization check (users can burn their own tokens, authorized burners can burn any)
        if user ~= msg.From and not isAuthorizedBurner(msg.From) then
            ao.send({
                Target = msg.From,
                Action = "Burn-Error",
                Data = "Unauthorized to burn tokens for this user"
            })
            return
        end
        
        -- Validate amount
        if not amount or amount <= 0 then
            ao.send({
                Target = msg.From,
                Action = "Burn-Error",
                Data = "Invalid burn amount"
            })
            return
        end
        
        -- Check user balance
        if not hasBalance(user, amount) then
            ao.send({
                Target = msg.From,
                Action = "Burn-Error",
                Data = "Insufficient balance to burn"
            })
            return
        end
        
        -- Generate burn operation ID
        local burnId = user .. "-burn-" .. tostring(os.time()) .. "-" .. tostring(math.random(1000, 9999))
        
        -- Execute burn
        Balances[user] = Balances[user] - amount
        TokenStats.totalBurned = TokenStats.totalBurned + amount
        TokenStats.burnOperations = TokenStats.burnOperations + 1
        
        -- Record burn operation
        BurnOperations[burnId] = {
            burnId = burnId,
            user = user,
            amount = amount,
            burner = msg.From,
            purpose = purpose,
            timestamp = os.time()
        }
        
        -- Update token info
        updateTokenStats()
        
        -- Send success response
        ao.send({
            Target = msg.From,
            Action = "Burn-Response",
            Data = json.encode({
                burnId = burnId,
                user = user,
                amount = tostring(formatAmount(amount)),
                newBalance = tostring(formatAmount(Balances[user])),
                totalSupply = tostring(formatAmount(TokenInfo.totalSupply))
            })
        })
        
        -- Debit notice to user (if different from burner)
        if user ~= msg.From then
            ao.send({
                Target = user,
                Action = "Debit-Notice",
                Data = json.encode({
                    burnedBy = msg.From,
                    amount = tostring(formatAmount(amount)),
                    newBalance = tostring(formatAmount(Balances[user])),
                    burnId = burnId
                })
            })
        end
        
        -- Notify state manager
        if Config.stateManagerProcess then
            ao.send({
                Target = Config.stateManagerProcess,
                Action = "UpdatePosition",
                Tags = {
                    User = user,
                    TIM3Balance = tostring(-amount),  -- Negative to subtract
                    Operation = "add"
                }
            })
        end
    end
)

-- Transfer Handler
Handlers.add(
    "Transfer",
    Handlers.utils.hasMatchingTag("Action", "Transfer"),
    function(msg)
        local recipient = msg.Tags.Recipient or msg.Tags.Target
        local amount = tonumber(msg.Tags.Quantity or msg.Tags.Amount)
        local sender = msg.From
        
        -- Check if transfers are enabled
        if not Config.transfersEnabled then
            ao.send({
                Target = msg.From,
                Action = "Transfer-Error",
                Data = "Transfers are currently disabled"
            })
            return
        end
        
        -- Validate inputs
        if not recipient then
            ao.send({
                Target = msg.From,
                Action = "Transfer-Error",
                Data = "Recipient required"
            })
            return
        end
        
        if not amount or amount <= 0 then
            ao.send({
                Target = msg.From,
                Action = "Transfer-Error",
                Data = "Invalid transfer amount"
            })
            return
        end
        
        -- Check sender balance
        if not hasBalance(sender, amount) then
            ao.send({
                Target = msg.From,
                Action = "Transfer-Error",
                Data = "Insufficient balance"
            })
            return
        end
        
        -- Execute transfer
        Balances[sender] = Balances[sender] - amount
        Balances[recipient] = (Balances[recipient] or 0) + amount
        TokenStats.totalTransfers = TokenStats.totalTransfers + 1
        
        -- Update stats
        updateTokenStats()
        
        -- Send responses
        ao.send({
            Target = msg.From,
            Action = "Transfer-Response",
            Data = json.encode({
                recipient = recipient,
                amount = tostring(formatAmount(amount)),
                newBalance = tostring(formatAmount(Balances[sender]))
            })
        })
        
        -- Credit notice to recipient
        ao.send({
            Target = recipient,
            Action = "Credit-Notice",
            Data = json.encode({
                from = sender,
                amount = tostring(formatAmount(amount)),
                newBalance = tostring(formatAmount(Balances[recipient]))
            })
        })
    end
)

-- Get Operation Info Handler
Handlers.add(
    "GetOperation",
    Handlers.utils.hasMatchingTag("Action", "GetOperation"),
    function(msg)
        local operationType = msg.Tags.OperationType  -- "mint" or "burn"
        local operationId = msg.Tags.OperationId
        local user = msg.Tags.User
        
        local operations = {}
        
        if operationType == "mint" then
            if operationId then
                local op = MintOperations[operationId]
                if op then
                    operations[operationId] = op
                end
            elseif user then
                for id, op in pairs(MintOperations) do
                    if op.recipient == user then
                        operations[id] = op
                    end
                end
            end
        elseif operationType == "burn" then
            if operationId then
                local op = BurnOperations[operationId]
                if op then
                    operations[operationId] = op
                end
            elseif user then
                for id, op in pairs(BurnOperations) do
                    if op.user == user then
                        operations[id] = op
                    end
                end
            end
        else
            ao.send({
                Target = msg.From,
                Action = "GetOperation-Error",
                Data = "OperationType must be 'mint' or 'burn'"
            })
            return
        end
        
        local count = 0
        for _ in pairs(operations) do count = count + 1 end
        
        ao.send({
            Target = msg.From,
            Action = "Operation-Response",
            Data = json.encode({
                operationType = operationType,
                operations = operations,
                count = count
            })
        })
    end
)

-- Token Statistics Handler
Handlers.add(
    "TokenStats",
    Handlers.utils.hasMatchingTag("Action", "TokenStats"),
    function(msg)
        updateTokenStats()
        
        ao.send({
            Target = msg.From,
            Action = "TokenStats-Response",
            Data = json.encode({
                tokenInfo = {
                    name = TokenInfo.name,
                    ticker = TokenInfo.ticker,
                    totalSupply = tostring(formatAmount(TokenInfo.totalSupply)),
                    denomination = TokenInfo.denomination
                },
                statistics = {
                    totalMinted = tostring(formatAmount(TokenStats.totalMinted)),
                    totalBurned = tostring(formatAmount(TokenStats.totalBurned)),
                    totalTransfers = TokenStats.totalTransfers,
                    uniqueHolders = TokenStats.uniqueHolders,
                    largestBalance = tostring(formatAmount(TokenStats.largestBalance)),
                    mintOperations = TokenStats.mintOperations,
                    burnOperations = TokenStats.burnOperations
                }
            })
        })
    end
)
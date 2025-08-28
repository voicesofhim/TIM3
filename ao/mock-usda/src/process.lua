-- Mock USDA Token Process for TIM3 Development
-- This simulates the real USDA token functionality for testing

local json = require("cjson")

-- Initialize process state
Name = Name or "Mock USDA"
Ticker = Ticker or "mUSDT"  -- Mock USDT to distinguish from real USDA
Denomination = Denomination or 6  -- 6 decimal places like real USDA
Logo = Logo or "development-token"

-- Initialize balances and state
Balances = Balances or {}
TotalSupply = TotalSupply or 0
Locked = Locked or {}  -- Track locked amounts for TIM3 collateral
ProcessInfo = ProcessInfo or {
    name = Name,
    ticker = Ticker,
    denomination = Denomination,
    totalSupply = TotalSupply
}

-- Helper Functions
local function formatAmount(amount)
    if amount == math.floor(amount) then
        return math.floor(amount)  -- Return integer if no decimal part
    else
        return math.floor(amount * (10 ^ Denomination)) / (10 ^ Denomination)
    end
end

local function validateAmount(amount)
    if not amount or type(amount) ~= "number" or amount <= 0 then
        return false, "Invalid amount"
    end
    return true, nil
end

local function hasBalance(user, amount)
    local balance = Balances[user] or 0
    return balance >= amount
end

-- Process Info Handler
Handlers.add(
    "Info",
    Handlers.utils.hasMatchingTag("Action", "Info"),
    function(msg)
        ao.send({
            Target = msg.From,
            Action = "Info-Response",
            Data = json.encode(ProcessInfo)
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
        local locked = Locked[target] or 0
        local available = balance - locked
        
        ao.send({
            Target = msg.From,
            Action = "Balance-Response",
            Data = json.encode({
                target = target,
                balance = tostring(formatAmount(balance)),
                locked = tostring(formatAmount(locked)),
                available = tostring(formatAmount(available))
            })
        })
    end
)

-- Balances Handler (for all balances)
Handlers.add(
    "Balances",
    Handlers.utils.hasMatchingTag("Action", "Balances"),
    function(msg)
        ao.send({
            Target = msg.From,
            Action = "Balances-Response",
            Data = json.encode(Balances)
        })
    end
)

-- Mint Handler (for development - gives users tokens to test with)
Handlers.add(
    "Mint",
    Handlers.utils.hasMatchingTag("Action", "Mint"),
    function(msg)
        local recipient = msg.Tags.Recipient or msg.From
        local amount = tonumber(msg.Tags.Quantity or msg.Tags.Amount or "1000")
        
        if not amount or amount <= 0 then
            ao.send({
                Target = msg.From,
                Action = "Mint-Error",
                Data = "Invalid mint amount"
            })
            return
        end
        
        -- Mint tokens (only for development)
        Balances[recipient] = (Balances[recipient] or 0) + amount
        TotalSupply = TotalSupply + amount
        ProcessInfo.totalSupply = TotalSupply
        
        ao.send({
            Target = msg.From,
            Action = "Mint-Response",
            Data = json.encode({
                recipient = recipient,
                amount = tostring(formatAmount(amount)),
                newBalance = tostring(formatAmount(Balances[recipient]))
            })
        })
        
        -- Notify recipient if different from sender
        if recipient ~= msg.From then
            ao.send({
                Target = recipient,
                Action = "Credit-Notice",
                Data = json.encode({
                    from = "Mock-USDA-Mint",
                    amount = tostring(formatAmount(amount)),
                    newBalance = tostring(formatAmount(Balances[recipient]))
                })
            })
        end
    end
)

-- Transfer Handler
Handlers.add(
    "Transfer",
    Handlers.utils.hasMatchingTag("Action", "Transfer"),
    function(msg)
        local recipient = msg.Tags.Recipient
        local amount = tonumber(msg.Tags.Quantity or msg.Tags.Amount)
        local sender = msg.From
        
        -- Validate inputs
        if not recipient then
            ao.send({
                Target = msg.From,
                Action = "Transfer-Error", 
                Data = "Recipient required"
            })
            return
        end
        
        local valid, error = validateAmount(amount)
        if not valid then
            ao.send({
                Target = msg.From,
                Action = "Transfer-Error",
                Data = error
            })
            return
        end
        
        -- Check available balance (excluding locked amounts)
        local senderBalance = Balances[sender] or 0
        local senderLocked = Locked[sender] or 0
        local availableBalance = senderBalance - senderLocked
        
        if availableBalance < amount then
            ao.send({
                Target = msg.From,
                Action = "Transfer-Error",
                Data = "Insufficient available balance"
            })
            return
        end
        
        -- Execute transfer
        Balances[sender] = senderBalance - amount
        Balances[recipient] = (Balances[recipient] or 0) + amount
        
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

-- Lock Handler (for TIM3 collateralization)
Handlers.add(
    "Lock",
    Handlers.utils.hasMatchingTag("Action", "Lock"),
    function(msg)
        local user = msg.From
        local amount = tonumber(msg.Tags.Amount or msg.Tags.Quantity)
        local locker = msg.Tags.Locker  -- Process that's requesting the lock (TIM3 Lock Manager)
        
        -- Validate amount
        local valid, error = validateAmount(amount)
        if not valid then
            ao.send({
                Target = msg.From,
                Action = "Lock-Error",
                Data = error
            })
            return
        end
        
        -- Check if user has sufficient available balance
        local userBalance = Balances[user] or 0
        local userLocked = Locked[user] or 0
        local availableBalance = userBalance - userLocked
        
        if availableBalance < amount then
            ao.send({
                Target = msg.From,
                Action = "Lock-Error", 
                Data = "Insufficient available balance for lock"
            })
            return
        end
        
        -- Lock the amount
        Locked[user] = userLocked + amount
        
        -- Send success response
        ao.send({
            Target = msg.From,
            Action = "Lock-Response",
            Data = json.encode({
                user = user,
                amount = tostring(formatAmount(amount)),
                totalLocked = tostring(formatAmount(Locked[user])),
                availableBalance = tostring(formatAmount(userBalance - Locked[user]))
            })
        })
        
        -- Notify the locker process if specified
        if locker then
            ao.send({
                Target = locker,
                Action = "Lock-Confirmed",
                Data = json.encode({
                    user = user,
                    amount = tostring(formatAmount(amount)),
                    lockId = msg.Tags.LockId or (user .. "-" .. tostring(os.time())),
                    purpose = msg.Tags.Purpose  -- Include original purpose for validation
                })
            })
        end
    end
)

-- Unlock Handler (for TIM3 collateral release)
Handlers.add(
    "Unlock",
    Handlers.utils.hasMatchingTag("Action", "Unlock"),
    function(msg)
        local user = msg.Tags.User or msg.From
        local amount = tonumber(msg.Tags.Amount or msg.Tags.Quantity)
        local unlocker = msg.From  -- Process requesting the unlock (should be TIM3 Lock Manager)
        
        -- Validate amount
        local valid, error = validateAmount(amount)
        if not valid then
            ao.send({
                Target = msg.From,
                Action = "Unlock-Error",
                Data = error
            })
            return
        end
        
        -- Check if user has sufficient locked balance
        local userLocked = Locked[user] or 0
        
        if userLocked < amount then
            ao.send({
                Target = msg.From,
                Action = "Unlock-Error",
                Data = "Insufficient locked balance"
            })
            return
        end
        
        -- Unlock the amount
        Locked[user] = userLocked - amount
        
        -- Send success response
        ao.send({
            Target = msg.From,
            Action = "Unlock-Response",
            Data = json.encode({
                user = user,
                amount = tostring(formatAmount(amount)),
                remainingLocked = tostring(formatAmount(Locked[user])),
                availableBalance = tostring(formatAmount((Balances[user] or 0) - Locked[user]))
            })
        })
        
        -- Notify user about unlock
        ao.send({
            Target = user,
            Action = "Unlock-Notice",
            Data = json.encode({
                amount = tostring(formatAmount(amount)),
                unlockedBy = unlocker,
                availableBalance = tostring(formatAmount((Balances[user] or 0) - Locked[user]))
            })
        })
    end
)
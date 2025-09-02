-- TIM3 Swap Contract - Single Process Solution
-- Receives USDA transfers and mints TIM3 tokens 1:1
-- Burns TIM3 tokens and returns USDA 1:1

json = require('json')

-- Token Configuration
Name = Name or "TIM3"
Ticker = Ticker or "TIM3"
Denomination = Denomination or 6
Logo = Logo or "TIM3_LOGO_TXID"

-- Process Configuration
USDA_PROCESS_ID = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"

-- State Variables
Balances = Balances or {}
TotalSupply = TotalSupply or 0
UsdaCollateral = UsdaCollateral or 0

-- Statistics
SwapStats = SwapStats or {
    totalSwaps = 0,
    totalBurns = 0,
    totalVolume = 0
}

-- Helper Functions
local function mint(recipient, amount)
    Balances[recipient] = (Balances[recipient] or 0) + amount
    TotalSupply = TotalSupply + amount
end

local function burn(user, amount)
    local balance = Balances[user] or 0
    if balance >= amount then
        Balances[user] = balance - amount
        TotalSupply = TotalSupply - amount
        return true
    end
    return false
end

-- Standard Token Handlers
Handlers.add("Info", 
    Handlers.utils.hasMatchingTag("Action", "Info"),
    function(msg)
        ao.send({
            Target = msg.From,
            Action = "Info-Response",
            Data = json.encode({
                Name = Name,
                Ticker = Ticker,
                Logo = Logo,
                Denomination = Denomination,
                TotalSupply = tostring(TotalSupply),
                UsdaCollateral = tostring(UsdaCollateral),
                SwapStats = SwapStats
            })
        })
    end
)

Handlers.add("Balance",
    Handlers.utils.hasMatchingTag("Action", "Balance"),
    function(msg)
        local target = msg.Tags.Target or msg.From
        local balance = tostring(Balances[target] or 0)
        
        ao.send({
            Target = msg.From,
            Action = "Balance-Response", 
            Data = json.encode({
                target = target,
                balance = balance
            })
        })
    end
)

Handlers.add("Balances",
    Handlers.utils.hasMatchingTag("Action", "Balances"),
    function(msg)
        ao.send({
            Target = msg.From,
            Action = "Balances-Response",
            Data = json.encode(Balances)
        })
    end
)

-- CORE SWAP FUNCTIONALITY

-- Receive USDA transfers and mint TIM3
Handlers.add("USDA-Credit-Notice",
    Handlers.utils.hasMatchingTag("Action", "Credit-Notice"),
    function(msg)
        -- Only accept from USDA process
        if msg.From ~= USDA_PROCESS_ID then
            return
        end
        
        local creditData = json.decode(msg.Data or "{}")
        local user = creditData.Sender or creditData.from
        local amount = tonumber(creditData.Quantity or creditData.amount or "0")
        
        if not user or amount <= 0 then
            return
        end
        
        -- Mint TIM3 1:1 for received USDA
        mint(user, amount)
        
        -- Track USDA collateral
        UsdaCollateral = UsdaCollateral + amount
        
        -- Update statistics
        SwapStats.totalSwaps = SwapStats.totalSwaps + 1
        SwapStats.totalVolume = SwapStats.totalVolume + amount
        
        -- Notify user of successful swap
        ao.send({
            Target = user,
            Action = "Swap-Success",
            Data = json.encode({
                usdaReceived = tostring(amount),
                tim3Minted = tostring(amount),
                newBalance = tostring(Balances[user]),
                swapId = user .. "-swap-" .. tostring(os.time())
            })
        })
        
        print("USDA->TIM3 Swap: " .. tostring(amount) .. " for user " .. user)
    end
)

-- Standard Transfer Handler (includes burn functionality)
Handlers.add("Transfer",
    Handlers.utils.hasMatchingTag("Action", "Transfer"),
    function(msg)
        local recipient = msg.Tags.Recipient
        local amount = tonumber(msg.Tags.Quantity or "0")
        local sender = msg.From
        
        if amount <= 0 then
            ao.send({
                Target = sender,
                Action = "Transfer-Error",
                Data = "Invalid amount"
            })
            return
        end
        
        local senderBalance = Balances[sender] or 0
        if senderBalance < amount then
            ao.send({
                Target = sender,
                Action = "Transfer-Error", 
                Data = "Insufficient balance"
            })
            return
        end
        
        -- Check if this is a burn operation
        if recipient == "burn" or recipient == ao.id then
            -- Burn TIM3 and release USDA
            if burn(sender, amount) then
                -- Release USDA back to user
                Send({
                    Target = USDA_PROCESS_ID,
                    Action = "Transfer",
                    Recipient = sender,
                    Quantity = tostring(amount)
                })
                
                UsdaCollateral = UsdaCollateral - amount
                SwapStats.totalBurns = SwapStats.totalBurns + 1
                
                ao.send({
                    Target = sender,
                    Action = "Burn-Success",
                    Data = json.encode({
                        tim3Burned = tostring(amount),
                        usdaReleased = tostring(amount),
                        newBalance = tostring(Balances[sender] or 0)
                    })
                })
                
                print("TIM3->USDA Burn: " .. tostring(amount) .. " for user " .. sender)
            else
                ao.send({
                    Target = sender,
                    Action = "Burn-Error",
                    Data = "Insufficient TIM3 balance"
                })
            end
        else
            -- Regular transfer
            Balances[sender] = senderBalance - amount
            Balances[recipient] = (Balances[recipient] or 0) + amount
            
            ao.send({
                Target = sender,
                Action = "Transfer-Success",
                Data = json.encode({
                    recipient = recipient,
                    amount = tostring(amount)
                })
            })
            
            ao.send({
                Target = recipient,
                Action = "Credit-Notice", 
                Data = json.encode({
                    sender = sender,
                    amount = tostring(amount)
                })
            })
        end
    end
)

-- Admin/Debug Handlers
Handlers.add("Stats",
    Handlers.utils.hasMatchingTag("Action", "Stats"),
    function(msg)
        ao.send({
            Target = msg.From,
            Action = "Stats-Response",
            Data = json.encode({
                TotalSupply = tostring(TotalSupply),
                UsdaCollateral = tostring(UsdaCollateral),
                CollateralRatio = UsdaCollateral > 0 and (TotalSupply / UsdaCollateral) or 0,
                SwapStats = SwapStats,
                TopHolders = {}  -- Could implement if needed
            })
        })
    end
)

print("TIM3 Swap Contract loaded successfully")
print("USDA Process: " .. USDA_PROCESS_ID)
print("Ready to receive USDA transfers and mint TIM3 tokens!")
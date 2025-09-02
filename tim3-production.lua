-- TIM3 Production Contract V2
-- USDA-Collateralized Token with 1:1 Swap Mechanism
-- Production Ready with Admin Testing Functions

json = require('json')

-- Token Configuration
Name = Name or "TIM3"
Ticker = Ticker or "TIM3"
Denomination = Denomination or 6
Logo = Logo or "TIM3_LOGO_TXID"

-- Process Configuration
USDA_PROCESS_ID = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"  -- Production USDA

-- Admin Configuration (for testing in production)
ADMIN_ADDRESS = ADMIN_ADDRESS or ao.id  -- Set to deployer initially
IS_PRODUCTION = true

-- State Variables
Balances = Balances or {}
TotalSupply = TotalSupply or 0
UsdaCollateral = UsdaCollateral or 0

-- Statistics
SwapStats = SwapStats or {
    totalSwaps = 0,
    totalBurns = 0,
    totalVolume = 0,
    uniqueUsers = 0,
    lastSwapTime = 0
}

-- User tracking
UniqueUsers = UniqueUsers or {}

-- Helper Functions
local function isAdmin(address)
    return address == ADMIN_ADDRESS
end

local function mint(recipient, amount)
    if not UniqueUsers[recipient] then
        UniqueUsers[recipient] = true
        SwapStats.uniqueUsers = SwapStats.uniqueUsers + 1
    end
    Balances[recipient] = (Balances[recipient] or 0) + amount
    TotalSupply = TotalSupply + amount
    SwapStats.lastSwapTime = os.time()
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
                SwapStats = SwapStats,
                ProcessId = ao.id,
                UsdaProcess = USDA_PROCESS_ID,
                IsProduction = IS_PRODUCTION
            })
        })
    end
)

Handlers.add("Balance",
    Handlers.utils.hasMatchingTag("Action", "Balance"),
    function(msg)
        local target = msg.Tags.Target or msg.Tags.Recipient or msg.From
        local balance = tostring(Balances[target] or 0)
        
        ao.send({
            Target = msg.From,
            Action = "Balance-Response", 
            Data = json.encode({
                target = target,
                balance = balance,
                account = target,
                ticker = Ticker
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
            print("Rejected Credit-Notice from unauthorized process: " .. msg.From)
            return
        end
        
        local creditData = json.decode(msg.Data or "{}")
        local user = creditData.Sender or creditData.sender or creditData.from
        local amount = tonumber(creditData.Quantity or creditData.quantity or creditData.amount or "0")
        
        if not user or amount <= 0 then
            print("Invalid credit notice - user: " .. tostring(user) .. ", amount: " .. tostring(amount))
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
                swapId = user .. "-swap-" .. tostring(os.time()),
                timestamp = os.time()
            })
        })
        
        print("USDA->TIM3 Swap: " .. tostring(amount) .. " for user " .. user)
    end
)

-- Standard Transfer Handler (includes burn functionality)
Handlers.add("Transfer",
    Handlers.utils.hasMatchingTag("Action", "Transfer"),
    function(msg)
        local recipient = msg.Tags.Recipient or msg.Tags.Target
        local amount = tonumber(msg.Tags.Quantity or msg.Tags.Amount or "0")
        local sender = msg.From
        
        if amount <= 0 then
            ao.send({
                Target = sender,
                Action = "Transfer-Error",
                Data = json.encode({
                    error = "Invalid amount",
                    amount = tostring(amount)
                })
            })
            return
        end
        
        local senderBalance = Balances[sender] or 0
        if senderBalance < amount then
            ao.send({
                Target = sender,
                Action = "Transfer-Error", 
                Data = json.encode({
                    error = "Insufficient balance",
                    balance = tostring(senderBalance),
                    required = tostring(amount)
                })
            })
            return
        end
        
        -- Check if this is a burn operation
        if recipient == "burn" or recipient == ao.id or recipient == "BURN" then
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
                        newBalance = tostring(Balances[sender] or 0),
                        timestamp = os.time()
                    })
                })
                
                print("TIM3->USDA Burn: " .. tostring(amount) .. " for user " .. sender)
            else
                ao.send({
                    Target = sender,
                    Action = "Burn-Error",
                    Data = json.encode({
                        error = "Insufficient TIM3 balance"
                    })
                })
            end
        else
            -- Regular transfer
            Balances[sender] = senderBalance - amount
            Balances[recipient] = (Balances[recipient] or 0) + amount
            
            -- Track new users
            if not UniqueUsers[recipient] then
                UniqueUsers[recipient] = true
                SwapStats.uniqueUsers = SwapStats.uniqueUsers + 1
            end
            
            ao.send({
                Target = sender,
                Action = "Transfer-Success",
                Data = json.encode({
                    recipient = recipient,
                    amount = tostring(amount),
                    timestamp = os.time()
                })
            })
            
            ao.send({
                Target = recipient,
                Action = "Credit-Notice", 
                Data = json.encode({
                    sender = sender,
                    amount = tostring(amount),
                    timestamp = os.time()
                })
            })
        end
    end
)

-- Stats Handler
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
                UniqueUsers = SwapStats.uniqueUsers,
                TopHolders = {},  -- Could implement if needed
                ProcessUptime = os.time(),
                IsHealthy = (TotalSupply == UsdaCollateral)
            })
        })
    end
)

-- ADMIN FUNCTIONS (Production Testing)
Handlers.add("Admin-TestMint",
    Handlers.utils.hasMatchingTag("Action", "Admin-TestMint"),
    function(msg)
        if not isAdmin(msg.From) then
            ao.send({
                Target = msg.From,
                Action = "Admin-Error",
                Data = json.encode({
                    error = "Unauthorized",
                    from = msg.From,
                    admin = ADMIN_ADDRESS
                })
            })
            return
        end
        
        local testUser = msg.Tags.User or msg.From
        local amount = tonumber(msg.Tags.Amount or "1000000")
        
        -- Simulate USDA deposit
        mint(testUser, amount)
        UsdaCollateral = UsdaCollateral + amount
        SwapStats.totalSwaps = SwapStats.totalSwaps + 1
        SwapStats.totalVolume = SwapStats.totalVolume + amount
        
        ao.send({
            Target = msg.From,
            Action = "Admin-TestMint-Success",
            Data = json.encode({
                testUser = testUser,
                amount = tostring(amount),
                newBalance = tostring(Balances[testUser]),
                totalSupply = tostring(TotalSupply),
                collateral = tostring(UsdaCollateral)
            })
        })
        
        print("[ADMIN TEST] Minted " .. amount .. " TIM3 for " .. testUser)
    end
)

-- Admin Stats
Handlers.add("Admin-Stats",
    Handlers.utils.hasMatchingTag("Action", "Admin-Stats"),
    function(msg)
        if not isAdmin(msg.From) then
            ao.send({
                Target = msg.From,
                Action = "Admin-Error",
                Data = "Unauthorized"
            })
            return
        end
        
        local holders = {}
        for address, balance in pairs(Balances) do
            if balance > 0 then
                table.insert(holders, {address = address, balance = balance})
            end
        end
        table.sort(holders, function(a, b) return a.balance > b.balance end)
        
        ao.send({
            Target = msg.From,
            Action = "Admin-Stats-Response",
            Data = json.encode({
                TotalSupply = tostring(TotalSupply),
                UsdaCollateral = tostring(UsdaCollateral),
                IsBalanced = (TotalSupply == UsdaCollateral),
                SwapStats = SwapStats,
                TotalHolders = #holders,
                TopHolders = holders,
                AdminAddress = ADMIN_ADDRESS,
                ProcessId = ao.id,
                UsdaProcessId = USDA_PROCESS_ID
            })
        })
    end
)

-- Health Check
Handlers.add("Health",
    Handlers.utils.hasMatchingTag("Action", "Health"),
    function(msg)
        local isHealthy = (TotalSupply == UsdaCollateral)
        ao.send({
            Target = msg.From,
            Action = "Health-Response",
            Data = json.encode({
                status = isHealthy and "HEALTHY" or "WARNING",
                totalSupply = tostring(TotalSupply),
                collateral = tostring(UsdaCollateral),
                ratio = UsdaCollateral > 0 and (TotalSupply / UsdaCollateral) or 0,
                lastActivity = SwapStats.lastSwapTime,
                uptime = os.time()
            })
        })
    end
)

print("==============================================")
print("TIM3 PRODUCTION CONTRACT V2 LOADED")
print("==============================================")
print("Process ID: " .. ao.id)
print("Admin: " .. ADMIN_ADDRESS)
print("USDA Process: " .. USDA_PROCESS_ID)
print("Status: PRODUCTION MODE")
print("==============================================")
print("Ready to receive USDA transfers!")
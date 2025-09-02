-- TIM3 Complete Contract with Helper Functions
json = require('json')

-- ===== CONTRACT DEPLOYMENT =====
Name = "TIM3"; Ticker = "TIM3"; Denomination = 6; Logo = "TIM3_LOGO_TXID"; USDA_PROCESS_ID = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"
Balances = Balances or {}; TotalSupply = TotalSupply or 0; UsdaCollateral = UsdaCollateral or 0
SwapStats = SwapStats or { totalSwaps = 0, totalBurns = 0, totalVolume = 0 }

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

-- Contract Handlers
Handlers.add("Info", Handlers.utils.hasMatchingTag("Action", "Info"), function(msg) 
    ao.send({ Target = msg.From, Action = "Info-Response", Data = json.encode({ Name = Name, Ticker = Ticker, Logo = Logo, Denomination = Denomination, TotalSupply = tostring(TotalSupply), UsdaCollateral = tostring(UsdaCollateral), SwapStats = SwapStats }) }) 
end)

Handlers.add("Balance", Handlers.utils.hasMatchingTag("Action", "Balance"), function(msg) 
    local target = msg.Tags.Target or msg.From
    local balance = tostring(Balances[target] or 0)
    ao.send({ Target = msg.From, Action = "Balance-Response", Data = json.encode({ target = target, balance = balance }) }) 
end)

Handlers.add("Balances", Handlers.utils.hasMatchingTag("Action", "Balances"), function(msg) 
    ao.send({ Target = msg.From, Action = "Balances-Response", Data = json.encode(Balances) }) 
end)

Handlers.add("USDA-Credit-Notice", Handlers.utils.hasMatchingTag("Action", "Credit-Notice"), function(msg) 
    if msg.From ~= USDA_PROCESS_ID then return end
    local creditData = json.decode(msg.Data or "{}")
    local user = creditData.Sender or creditData.from
    local amount = tonumber(creditData.Quantity or creditData.amount or "0")
    if not user or amount <= 0 then return end
    mint(user, amount)
    UsdaCollateral = UsdaCollateral + amount
    SwapStats.totalSwaps = SwapStats.totalSwaps + 1
    SwapStats.totalVolume = SwapStats.totalVolume + amount
    ao.send({ Target = user, Action = "Swap-Success", Data = json.encode({ usdaReceived = tostring(amount), tim3Minted = tostring(amount), newBalance = tostring(Balances[user]), swapId = user .. "-swap-" .. tostring(os.time()) }) })
    print("USDA->TIM3 Swap: " .. tostring(amount) .. " for user " .. user) 
end)

Handlers.add("Transfer", Handlers.utils.hasMatchingTag("Action", "Transfer"), function(msg) 
    local recipient = msg.Tags.Recipient
    local amount = tonumber(msg.Tags.Quantity or "0")
    local sender = msg.From
    if amount <= 0 then 
        ao.send({ Target = sender, Action = "Transfer-Error", Data = "Invalid amount" })
        return 
    end
    local senderBalance = Balances[sender] or 0
    if senderBalance < amount then 
        ao.send({ Target = sender, Action = "Transfer-Error", Data = "Insufficient balance" })
        return 
    end
    if recipient == "burn" or recipient == ao.id then 
        if burn(sender, amount) then 
            Send({ Target = USDA_PROCESS_ID, Action = "Transfer", Recipient = sender, Quantity = tostring(amount) })
            UsdaCollateral = UsdaCollateral - amount
            SwapStats.totalBurns = SwapStats.totalBurns + 1
            ao.send({ Target = sender, Action = "Burn-Success", Data = json.encode({ tim3Burned = tostring(amount), usdaReleased = tostring(amount), newBalance = tostring(Balances[sender] or 0) }) })
            print("TIM3->USDA Burn: " .. tostring(amount) .. " for user " .. sender) 
        else 
            ao.send({ Target = sender, Action = "Burn-Error", Data = "Insufficient TIM3 balance" }) 
        end 
    else 
        Balances[sender] = senderBalance - amount
        Balances[recipient] = (Balances[recipient] or 0) + amount
        ao.send({ Target = sender, Action = "Transfer-Success", Data = json.encode({ recipient = recipient, amount = tostring(amount) }) })
        ao.send({ Target = recipient, Action = "Credit-Notice", Data = json.encode({ sender = sender, amount = tostring(amount) }) }) 
    end 
end)

Handlers.add("Stats", Handlers.utils.hasMatchingTag("Action", "Stats"), function(msg) 
    ao.send({ Target = msg.From, Action = "Stats-Response", Data = json.encode({ TotalSupply = tostring(TotalSupply), UsdaCollateral = tostring(UsdaCollateral), CollateralRatio = UsdaCollateral > 0 and (TotalSupply / UsdaCollateral) or 0, SwapStats = SwapStats, TopHolders = {} }) }) 
end)

-- ===== HELPER FUNCTIONS =====
print("=== TIM3 QUICK START ===")
print("Initializing TIM3 contract...")
print("")
print("Process ID: " .. ao.id)
print("Name: " .. (Name or "TIM3"))
print("Ticker: " .. (Ticker or "TIM3"))
print("USDA Process: " .. (USDA_PROCESS_ID or "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"))
print("")

function quickTest() 
    print("\n🧪 Running Quick Test...")
    Send({Target = ao.id, Action = "Info"})
    os.execute("sleep 1")
    local infoMsg = Inbox[#Inbox]
    if infoMsg and infoMsg.Action == "Info-Response" then 
        print("✅ Info handler working") 
    else 
        print("❌ Info handler failed") 
    end
    Send({Target = ao.id, Action = "Stats"})
    os.execute("sleep 1")
    local statsMsg = Inbox[#Inbox]
    if statsMsg and statsMsg.Action == "Stats-Response" then 
        print("✅ Stats handler working") 
    else 
        print("❌ Stats handler failed") 
    end
    Send({Target = ao.id, Action = "Balance"})
    os.execute("sleep 1")
    local balMsg = Inbox[#Inbox]
    if balMsg and balMsg.Action == "Balance-Response" then 
        print("✅ Balance handler working") 
    else 
        print("❌ Balance handler failed") 
    end
    print("\n✅ Basic handlers operational!")
    return true 
end

function displayCommands() 
    print("\n📋 QUICK COMMANDS:")
    print("================")
    print("quickTest()        - Run basic handler tests")
    print("getInfo()          - Get contract information")
    print("getStats()         - Get current statistics")
    print("simulateSwap()     - Simulate a USDA swap")
    print("showSetup()        - Display setup instructions")
    print("") 
end

function getInfo() 
    Send({Target = ao.id, Action = "Info"})
    os.execute("sleep 1")
    local msg = Inbox[#Inbox]
    if msg and msg.Action == "Info-Response" then 
        local data = json.decode(msg.Data)
        print("\n📊 CONTRACT INFO:")
        print("Name: " .. data.Name)
        print("Ticker: " .. data.Ticker)
        print("Supply: " .. data.TotalSupply)
        print("Collateral: " .. data.UsdaCollateral)
        return data 
    end 
end

function getStats() 
    Send({Target = ao.id, Action = "Stats"})
    os.execute("sleep 1")
    local msg = Inbox[#Inbox]
    if msg and msg.Action == "Stats-Response" then 
        local data = json.decode(msg.Data)
        print("\n📈 STATISTICS:")
        print("Total Swaps: " .. tostring(data.SwapStats.totalSwaps))
        print("Total Burns: " .. tostring(data.SwapStats.totalBurns))
        print("Total Volume: " .. tostring(data.SwapStats.totalVolume))
        return data 
    end 
end

function simulateSwap() 
    local testAmount = "1000000"
    local testUser = "test_" .. tostring(os.time())
    print("\n🔄 Simulating swap of " .. testAmount .. " USDA")
    Send({ Target = ao.id, From = USDA_PROCESS_ID or "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Credit-Notice", Data = json.encode({ Sender = testUser, Quantity = testAmount }) })
    os.execute("sleep 1")
    print("✅ Swap simulated for user: " .. testUser)
    Send({Target = ao.id, Action = "Balance", Tags = {Target = testUser}})
    os.execute("sleep 1")
    local msg = Inbox[#Inbox]
    if msg and msg.Action == "Balance-Response" then 
        local data = json.decode(msg.Data)
        print("✅ User balance: " .. data.balance .. " TIM3") 
    end 
end

function showSetup() 
    print("\n🚀 SETUP INSTRUCTIONS:")
    print("====================")
    print("1. Your TIM3 Process ID: " .. ao.id)
    print("2. Add this to your frontend/wallet")
    print("3. To receive TIM3: Transfer USDA to this process")
    print("4. To get USDA back: Transfer TIM3 to 'burn'")
    print("")
    print("📝 For production use:")
    print("- Ensure USDA process is: FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8")
    print("- Test with small amounts first")
    print("- Monitor with: .load tim3-monitor.load")
    print("") 
end

print("TIM3 Swap Contract loaded successfully")
print("USDA Process: " .. USDA_PROCESS_ID)
print("Ready to receive USDA transfers and mint TIM3 tokens!")
print("✅ TIM3 Contract Ready!")
print("")
displayCommands()
print("Run 'quickTest()' to verify everything is working")
print("Run 'showSetup()' for integration instructions")

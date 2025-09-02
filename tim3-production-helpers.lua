-- TIM3 Production Helper Functions
-- Load this after deploying tim3-production.lua

json = require('json')

print("=== TIM3 PRODUCTION HELPERS ===")

-- Admin Testing Functions (only work if you're the admin)
function adminTestMint(user, amount)
    user = user or ao.id
    amount = amount or "1000000"
    print("Admin test minting " .. amount .. " TIM3 for " .. user)
    Send({
        Target = ao.id,
        Action = "Admin-TestMint",
        Tags = {
            User = user,
            Amount = amount
        }
    })
end

function adminStats()
    print("Fetching admin statistics...")
    Send({
        Target = ao.id,
        Action = "Admin-Stats"
    })
end

-- Standard User Functions
function checkBalance(user)
    user = user or ao.id
    Send({
        Target = ao.id,
        Action = "Balance",
        Tags = {
            Target = user
        }
    })
end

function getInfo()
    Send({Target = ao.id, Action = "Info"})
end

function getStats()
    Send({Target = ao.id, Action = "Stats"})
end

function getHealth()
    Send({Target = ao.id, Action = "Health"})
end

-- Swap Functions
function burnTim3(amount)
    print("Burning " .. amount .. " TIM3 for USDA...")
    Send({
        Target = ao.id,
        Action = "Transfer",
        Tags = {
            Recipient = "burn",
            Quantity = amount
        }
    })
end

function transferTim3(recipient, amount)
    print("Transferring " .. amount .. " TIM3 to " .. recipient)
    Send({
        Target = ao.id,
        Action = "Transfer",
        Tags = {
            Recipient = recipient,
            Quantity = amount
        }
    })
end

-- View Functions
function viewLastMessage()
    if #Inbox > 0 then
        local msg = Inbox[#Inbox]
        print("Last message: " .. (msg.Action or "Unknown"))
        if msg.Data then
            local success, decoded = pcall(json.decode, msg.Data)
            if success then
                return decoded
            else
                return msg.Data
            end
        end
    else
        print("No messages in inbox")
    end
end

function viewBalance()
    checkBalance()
    os.execute("sleep 1")
    return viewLastMessage()
end

function viewStats()
    getStats()
    os.execute("sleep 1")
    return viewLastMessage()
end

function viewHealth()
    getHealth()
    os.execute("sleep 1")
    return viewLastMessage()
end

-- Quick Test Function
function quickTest()
    print("\n=== RUNNING QUICK TEST ===")
    
    -- Test Info
    getInfo()
    os.execute("sleep 1")
    local info = viewLastMessage()
    if info then
        print("✓ Contract Name: " .. (info.Name or "Unknown"))
        print("✓ Process ID: " .. (info.ProcessId or ao.id))
        print("✓ USDA Process: " .. (info.UsdaProcess or "Unknown"))
    end
    
    -- Test Balance
    checkBalance()
    os.execute("sleep 1")
    local bal = viewLastMessage()
    if bal then
        print("✓ Balance check working")
    end
    
    -- Test Stats
    getStats()
    os.execute("sleep 1")
    local stats = viewLastMessage()
    if stats then
        print("✓ Stats: Supply=" .. (stats.TotalSupply or "0") .. ", Collateral=" .. (stats.UsdaCollateral or "0"))
    end
    
    -- Test Health
    getHealth()
    os.execute("sleep 1")
    local health = viewLastMessage()
    if health then
        print("✓ Health: " .. (health.status or "Unknown"))
    end
    
    print("\n=== TEST COMPLETE ===")
end

-- Display available commands
print("\n=== AVAILABLE COMMANDS ===")
print("\nAdmin Functions (if you're admin):")
print("  adminTestMint(user, amount) - Test mint TIM3")
print("  adminStats() - Get detailed admin stats")
print("\nUser Functions:")
print("  checkBalance(user) - Check balance")
print("  burnTim3(amount) - Burn TIM3 for USDA")
print("  transferTim3(recipient, amount) - Transfer TIM3")
print("\nView Functions:")
print("  viewBalance() - Check and view balance")
print("  viewStats() - Get and view stats")
print("  viewHealth() - Check system health")
print("  viewLastMessage() - View last inbox message")
print("\nTesting:")
print("  quickTest() - Run all tests")
print("\nYour Process ID: " .. ao.id)
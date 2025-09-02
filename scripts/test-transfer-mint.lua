-- TIM3 Transfer-Based Mint Test
-- Complete test flow for the new transfer-based USDA locking system

print("🔄 TIM3 TRANSFER-BASED MINT TEST")
print("================================")

-- Process IDs
local processes = {
    coordinator = "dxkd6zkK2t5k0fv_-eG3WRTtZaExetLV0410xI6jfsw",
    tokenManager = "BUhWwGfuD1GUHVIIWF_Jhm1mfcyAYHOJS6W90ur2Bb0",
    lockManager = "MWxRVsCDoSzQ0MhG4_BWkYs0fhcULB-OO3f2t1RlBAs",
    mockUsda = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8",
    wanderWallet = "2fSKy8T_MWCk4RRBtZwGL8TECg9wDCuQD90Y2IeyRQg"
}

-- Helper function to format amounts
function formatAmount(amount)
    return string.format("%.6f", amount / 1000000)
end

-- Test functions for Coordinator process
function mintTIM3(amount)
    amount = amount or 0.1  -- Default to 0.1 USDA (100000 base units)
    print("\n📤 Initiating TIM3 mint for " .. amount .. " USDA...")
    
    Send({
        Target = processes.coordinator,
        Action = "MintTIM3", 
        Tags = {
            Amount = tostring(math.floor(amount * 1000000))  -- Convert to base units
        }
    })
    
    print("   Sent mint request to Coordinator")
    return "Check Inbox[#Inbox] for Lock Manager response"
end

function checkTIM3Balance()
    print("\n💰 Checking TIM3 balance...")
    Send({
        Target = processes.tokenManager,
        Action = "Balance",
        Tags = {
            Target = ao.id
        }
    })
    return "Balance request sent - check Inbox[#Inbox]"
end

function checkUsdaBalance()
    print("\n💵 Checking USDA balance...")
    Send({
        Target = processes.mockUsda,
        Action = "Balance",
        Tags = {
            Recipient = ao.id
        }
    })
    return "Balance request sent - check Inbox[#Inbox]"
end

function transferUsdaToLockManager(amount)
    amount = amount or 0.1  -- Default to 0.1 USDA to match mintTIM3 default
    print("\n💸 Transferring " .. amount .. " USDA to Lock Manager...")
    
    Send({
        Target = processes.mockUsda,
        Action = "Transfer",
        Recipient = processes.lockManager,
        Quantity = tostring(math.floor(amount * 1000000))
    })
    
    print("   Transfer sent to Lock Manager: " .. processes.lockManager)
    return "Transfer initiated - Lock Manager should receive Credit-Notice"
end

function checkLockStatus()
    print("\n🔒 Checking Lock Manager status...")
    Send({
        Target = processes.lockManager,
        Action = "Info"
    })
    return "Status request sent - check Inbox[#Inbox]"
end

-- Display available commands
print("\n📚 AVAILABLE COMMANDS:")
print("   mintTIM3(amount)           -- Start mint process (amount in USDA)")
print("   checkTIM3Balance()         -- Check your TIM3 balance")
print("   checkUsdaBalance()         -- Check your USDA balance")
print("   transferUsdaToLockManager(amount) -- Complete the mint by transferring USDA")
print("   checkLockStatus()          -- Check Lock Manager status")

print("\n🎯 NEW MINT FLOW:")
print("   1. Run: mintTIM3(0.1)  -- or just mintTIM3() for 0.1 USDA default")
print("   2. Check response: Inbox[#Inbox]")
print("   3. You'll get 'awaiting-transfer' with Lock Manager address")
print("   4. Run: transferUsdaToLockManager(0.1)  -- or just transferUsdaToLockManager()")
print("   5. Lock Manager receives Credit-Notice → Completes mint")
print("   6. Check balance: checkTIM3Balance()")

print("\n⚠️ NOTE: Maximum mint amount is 1000 USDA (1000000000000 base units)")
print("\n✅ Test functions loaded successfully!")
print("   Start with: mintTIM3() or mintTIM3(0.1)")
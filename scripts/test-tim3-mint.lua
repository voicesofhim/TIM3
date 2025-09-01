-- TIM3 Mint Test Script
-- Run this from any AOS terminal to test the full mint flow

print("=== TIM3 MINT TEST SCRIPT ===")
print("")

-- Process PIDs
local coordinator = "dxkd6zkK2t5k0fv_-eG3WRTtZaExetLV0410xI6jfsw"
local tokenManager = "BUhWwGfuD1GUHVIIWF_Jhm1mfcyAYHOJS6W90ur2Bb0"
local lockManager = "MWxRVsCDoSzQ0MhG4_BWkYs0fhcULB-OO3f2t1RlBAs"
local mockUsda = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"
local wanderWallet = "2fSKy8T_MWCk4RRBtZwGL8TECg9wDCuQD90Y2IeyRQg"

print("📍 Process PIDs:")
print("  Coordinator:    " .. coordinator)
print("  Token Manager:  " .. tokenManager)
print("  Lock Manager:   " .. lockManager)
print("  Mock USDA:      " .. mockUsda)
print("  Wander Wallet:  " .. wanderWallet)
print("")

-- Step 1: Check current balances
print("📊 Step 1: Checking current balances...")

-- Check USDA balance
Send({Target = mockUsda, Action = "Balance", Tags = {Recipient = wanderWallet}})
print("  Sent USDA balance request...")

-- Check TIM3 balance
Send({Target = tokenManager, Action = "Balance", Tags = {Target = wanderWallet}})
print("  Sent TIM3 balance request...")

-- Step 2: Check Lock Manager configuration
print("")
print("🔧 Step 2: Checking Lock Manager configuration...")
Send({Target = lockManager, Action = "Info"})
print("  Sent Lock Manager info request...")

-- Step 3: Initiate mint (commented out for safety - uncomment to execute)
print("")
print("🚀 Step 3: Ready to mint TIM3")
print("  To initiate mint, run from Wander Wallet terminal:")
print('  Send({Target="' .. coordinator .. '", Action="MintTIM3", Tags={Amount="1"}})')
print("")
print("  Or uncomment the following line in this script:")
print('  -- Send({Target = coordinator, Action = "MintTIM3", Tags = {Amount = "1"}})')

-- Uncomment to actually attempt the mint:
-- Send({Target = coordinator, Action = "MintTIM3", Tags = {Amount = "1"}})

print("")
print("💡 After running this script, check Inbox for responses:")
print("  Inbox[#Inbox]   - Latest message")
print("  Inbox[#Inbox-1] - Previous message")
print("  Inbox[#Inbox-2] - Two messages back")
print("")
print("=== END TEST SCRIPT ===")
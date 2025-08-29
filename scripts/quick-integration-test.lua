-- TIM3 Quick Integration Test
-- Run this script for immediate integration testing
-- Use this after loading configure-integration.lua

print("🚀 TIM3 Quick Integration Test Starting...")
print("==========================================")

print("📝 Ready to begin integration testing!")
print("📝 First run: startIntegration()")

function startIntegration()
    print("⚙️ Step 1: Configuring all processes...")
    configureAllProcesses()
    
    print("⏳ Wait 10 seconds, then check Inbox[#Inbox] for configuration confirmations")
    print("📝 Then run: quickIntegrationTest()")
end

function quickIntegrationTest()
    print("🧪 Starting Quick Integration Test...")
    
    -- Test 1: Health check
    print("🏥 Test 1: System Health Check")
    checkSystemHealth()
    print("✅ Check Inbox[#Inbox], then continue with Test 2")
    
    print("")
    print("📝 Next: Run testMintingSequence() after checking inbox")
end

function testMintingSequence()
    print("🏭 Test 2: Minting Sequence")
    
    -- Ensure USDA balance
    print("💰 Ensuring USDA balance...")
    Send({ Target = "u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ", Action = "Mint", Tags = { Amount = "50" } })
    
    print("⏳ Wait 5 seconds, then run: mintTIM3Test()")
end

function mintTIM3Test()
    print("🚀 Test 3: TIM3 Minting")
    
    -- Mint TIM3
    Send({
        Target = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw",
        Action = "MintTIM3",
        Tags = { Amount = "5" }
    })
    
    print("✅ TIM3 mint request sent!")
    print("📊 Check Inbox[#Inbox] for minting progress")
    print("📝 Then run: testRedemptionSequence()")
end

function testRedemptionSequence()
    print("🔄 Test 4: Redemption Sequence")
    
    -- Burn TIM3
    Send({
        Target = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw",
        Action = "BurnTIM3", 
        Tags = { Amount = "2" }
    })
    
    print("✅ TIM3 burn request sent!")
    print("📊 Check Inbox[#Inbox] for redemption progress")
    print("📝 Then run: finalSystemCheck()")
end

function finalSystemCheck()
    print("🏁 Final System Check")
    
    -- Check balances
    Send({ Target = "u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ", Action = "Balance" })
    Send({ Target = "BUhWwGfuD1GUHVIIWF_Jhm1mfcyAYHOJS6W90ur2Bb0", Action = "Balance" })
    
    -- Check system state
    Send({ Target = "K2FjwiTmncglx0pISNMft5-SngxW-HUjs9sctzmXtU4", Action = "SystemHealth" })
    
    print("✅ Final checks sent!")
    print("📊 Check Inbox[#Inbox] for final system state")
    print("")
    print("🎉 Quick Integration Test Complete!")
    print("✅ If all responses are positive, integration is successful!")
end

print("✅ Quick Integration Test loaded!")
print("📚 Test sequence:")
print("  1. configureAllProcesses() - Configure all process IDs")
print("  2. quickIntegrationTest() - Start health checks")
print("  3. testMintingSequence() - Test minting flow")
print("  4. mintTIM3Test() - Execute TIM3 mint")
print("  5. testRedemptionSequence() - Test redemption flow")
print("  6. finalSystemCheck() - Verify final state")
print("")
print("🚀 Start with: startIntegration()")

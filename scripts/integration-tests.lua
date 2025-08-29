-- TIM3 Integration Test Suite
-- Comprehensive testing functions for live AOS deployment
-- Load after configure-integration.lua

-- Test Results Storage
TestResults = TestResults or {}

-- Helper function to wait and check inbox
local function waitAndCheckInbox(seconds, description)
    print("⏳ " .. description .. " (waiting " .. seconds .. "s)")
    -- In AOS, we'll manually check Inbox[#Inbox] after each operation
    return true
end

-- Test 1: System Communication Test
function testSystemCommunication()
    print("🔄 Testing Inter-Process Communication...")
    
    TestResults.communication = {}
    
    -- Test Coordinator → State Manager
    print("📡 Testing Coordinator → State Manager")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "TestMessage",
        Tags = {
            TestTarget = "StateManager",
            TestMessage = "Integration test communication"
        }
    })
    TestResults.communication.coordinator_to_state = "sent"
    
    -- Test Coordinator → Lock Manager  
    print("📡 Testing Coordinator → Lock Manager")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "TestMessage", 
        Tags = {
            TestTarget = "LockManager",
            TestMessage = "Integration test communication"
        }
    })
    TestResults.communication.coordinator_to_lock = "sent"
    
    -- Test Coordinator → Token Manager
    print("📡 Testing Coordinator → Token Manager")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "TestMessage",
        Tags = {
            TestTarget = "TokenManager", 
            TestMessage = "Integration test communication"
        }
    })
    TestResults.communication.coordinator_to_token = "sent"
    
    print("✅ Communication tests initiated. Check Inbox[#Inbox] for responses.")
    return TestResults.communication
end

-- Test 2: System Health Check
function checkSystemHealth()
    print("🏥 Checking System Health...")
    
    TestResults.health = {}
    
    -- Check each process health
    local processes = {
        {"Mock-USDA", PROCESS_IDS.MOCK_USDA},
        {"Coordinator", PROCESS_IDS.COORDINATOR},
        {"State Manager", PROCESS_IDS.STATE_MANAGER},
        {"Lock Manager", PROCESS_IDS.LOCK_MANAGER},
        {"Token Manager", PROCESS_IDS.TOKEN_MANAGER}
    }
    
    for _, process in ipairs(processes) do
        local name, id = process[1], process[2]
        print("🔍 Checking " .. name .. " health...")
        
        Send({
            Target = id,
            Action = "Info"
        })
        
        TestResults.health[name] = "requested"
    end
    
    print("✅ Health checks initiated. Check Inbox[#Inbox] for responses.")
    return TestResults.health
end

-- Test 3: Complete Minting Flow Test
function testMintingFlow()
    print("🏭 Testing Complete Minting Flow (USDA → TIM3)...")
    
    TestResults.minting = {
        started = os.time(),
        steps = {}
    }
    
    -- Step 1: Check USDA balance first
    print("💰 Step 1: Checking USDA balance...")
    Send({
        Target = PROCESS_IDS.MOCK_USDA,
        Action = "Balance"
    })
    TestResults.minting.steps.balance_check = "sent"
    
    -- Step 2: Mint USDA if needed (for testing)
    print("🔨 Step 2: Ensuring sufficient USDA for test...")
    Send({
        Target = PROCESS_IDS.MOCK_USDA,
        Action = "Mint",
        Tags = { Amount = "100" }
    })
    TestResults.minting.steps.usda_mint = "sent"
    
    -- Step 3: Initiate TIM3 minting
    print("🚀 Step 3: Initiating TIM3 mint (10 TIM3)...")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "MintTIM3",
        Tags = { Amount = "10" }
    })
    TestResults.minting.steps.tim3_mint = "sent"
    
    print("✅ Minting flow initiated. Monitor with Inbox[#Inbox]")
    print("Expected sequence:")
    print("  1. Coordinator receives MintTIM3")
    print("  2. Lock Manager locks USDA") 
    print("  3. Token Manager mints TIM3")
    print("  4. User receives TIM3 tokens")
    
    return TestResults.minting
end

-- Test 4: Complete Redemption Flow Test
function testRedemptionFlow()
    print("🔄 Testing Complete Redemption Flow (TIM3 → USDA)...")
    
    TestResults.redemption = {
        started = os.time(),
        steps = {}
    }
    
    -- Step 1: Check TIM3 balance
    print("💎 Step 1: Checking TIM3 balance...")
    Send({
        Target = PROCESS_IDS.TOKEN_MANAGER,
        Action = "Balance"
    })
    TestResults.redemption.steps.balance_check = "sent"
    
    -- Step 2: Initiate TIM3 burning/redemption
    print("🔥 Step 2: Initiating TIM3 burn (5 TIM3)...")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "BurnTIM3",
        Tags = { Amount = "5" }
    })
    TestResults.redemption.steps.tim3_burn = "sent"
    
    print("✅ Redemption flow initiated. Monitor with Inbox[#Inbox]")
    print("Expected sequence:")
    print("  1. Coordinator receives BurnTIM3")
    print("  2. Token Manager burns TIM3")
    print("  3. Lock Manager unlocks USDA")
    print("  4. User receives USDA tokens")
    
    return TestResults.redemption
end

-- Test 5: State Consistency Check
function checkStateConsistency()
    print("🔍 Checking System State Consistency...")
    
    TestResults.consistency = {}
    
    -- Check coordinator state
    print("📊 Checking Coordinator state...")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "GetPosition"
    })
    TestResults.consistency.coordinator = "requested"
    
    -- Check state manager
    print("📈 Checking State Manager...")
    Send({
        Target = PROCESS_IDS.STATE_MANAGER,
        Action = "SystemHealth"
    })
    TestResults.consistency.state_manager = "requested"
    
    -- Check lock manager stats
    print("🔒 Checking Lock Manager stats...")
    Send({
        Target = PROCESS_IDS.LOCK_MANAGER,
        Action = "LockStats"
    })
    TestResults.consistency.lock_manager = "requested"
    
    -- Check token manager stats
    print("🪙 Checking Token Manager stats...")
    Send({
        Target = PROCESS_IDS.TOKEN_MANAGER,
        Action = "TokenStats"
    })
    TestResults.consistency.token_manager = "requested"
    
    print("✅ Consistency checks initiated. Check Inbox[#Inbox] for all responses.")
    return TestResults.consistency
end

-- Test 6: Error Handling Tests
function testErrorHandling()
    print("⚠️ Testing Error Handling & Edge Cases...")
    
    TestResults.errors = {}
    
    -- Test 1: Invalid mint amount (zero)
    print("🚫 Test 1: Invalid mint amount (0)...")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "MintTIM3",
        Tags = { Amount = "0" }
    })
    TestResults.errors.zero_mint = "sent"
    
    -- Test 2: Invalid mint amount (negative)
    print("🚫 Test 2: Invalid mint amount (-5)...")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "MintTIM3",
        Tags = { Amount = "-5" }
    })
    TestResults.errors.negative_mint = "sent"
    
    -- Test 3: Burn more than available
    print("🚫 Test 3: Burn more TIM3 than available...")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "BurnTIM3",
        Tags = { Amount = "1000" }
    })
    TestResults.errors.excessive_burn = "sent"
    
    -- Test 4: Large mint (circuit breaker test)
    print("🚫 Test 4: Large mint (circuit breaker)...")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "MintTIM3",
        Tags = { Amount = "2000" }
    })
    TestResults.errors.large_mint = "sent"
    
    print("✅ Error handling tests initiated. Check Inbox[#Inbox] for error responses.")
    return TestResults.errors
end

-- Test 7: Performance Test
function testPerformance()
    print("⚡ Testing System Performance...")
    
    TestResults.performance = {
        started = os.time(),
        operations = {}
    }
    
    -- Rapid sequence of small operations
    for i = 1, 5 do
        print("⚡ Performance test " .. i .. "/5: Mint 1 TIM3")
        Send({
            Target = PROCESS_IDS.COORDINATOR,
            Action = "MintTIM3",
            Tags = { Amount = "1" }
        })
        TestResults.performance.operations["mint_" .. i] = os.time()
    end
    
    print("✅ Performance tests initiated. Monitor timing in Inbox[#Inbox]")
    return TestResults.performance
end

-- Comprehensive Test Runner
function runFullIntegrationSuite()
    print("🧪 Running Full TIM3 Integration Test Suite...")
    print("================================================")
    
    -- Initialize test results
    TestResults = {
        suite_started = os.time(),
        suite_version = "1.0.0"
    }
    
    print("Phase 1: System Communication")
    testSystemCommunication()
    print("✅ Check Inbox, then continue...")
    print("")
    
    print("Phase 2: System Health")
    checkSystemHealth()
    print("✅ Check Inbox, then continue...")
    print("")
    
    print("Phase 3: State Consistency")
    checkStateConsistency()
    print("✅ Check Inbox, then continue...")
    print("")
    
    print("Phase 4: Minting Flow")
    testMintingFlow()
    print("✅ Check Inbox, then continue...")
    print("")
    
    print("Phase 5: Redemption Flow")
    testRedemptionFlow()
    print("✅ Check Inbox, then continue...")
    print("")
    
    print("Phase 6: Error Handling")
    testErrorHandling()
    print("✅ Check Inbox, then continue...")
    print("")
    
    print("Phase 7: Performance")
    testPerformance()
    print("✅ Check Inbox for final results...")
    print("")
    
    TestResults.suite_completed = os.time()
    
    print("🎉 Full Integration Test Suite Completed!")
    print("📊 Results stored in TestResults table")
    print("📝 Check all Inbox responses for detailed results")
    
    return TestResults
end

-- Quick Test Functions for Manual Testing
function quickHealthCheck()
    print("🏥 Quick Health Check...")
    checkSystemHealth()
    print("✅ Check Inbox[#Inbox] for results")
end

function quickMint(amount)
    amount = amount or "1"
    print("🏭 Quick Mint: " .. amount .. " TIM3")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "MintTIM3",
        Tags = { Amount = amount }
    })
    print("✅ Check Inbox[#Inbox] for results")
end

function quickBurn(amount)
    amount = amount or "1"
    print("🔥 Quick Burn: " .. amount .. " TIM3")
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "BurnTIM3",
        Tags = { Amount = amount }
    })
    print("✅ Check Inbox[#Inbox] for results")
end

function quickBalance()
    print("💰 Quick Balance Check...")
    Send({ Target = PROCESS_IDS.MOCK_USDA, Action = "Balance" })
    Send({ Target = PROCESS_IDS.TOKEN_MANAGER, Action = "Balance" })
    print("✅ Check Inbox[#Inbox] for USDA and TIM3 balances")
end

-- Helper function to display test results
function showTestResults()
    if not TestResults then
        print("❌ No test results available. Run tests first.")
        return
    end
    
    print("📊 TIM3 Integration Test Results")
    print("===============================")
    
    for category, results in pairs(TestResults) do
        if type(results) == "table" then
            print("🔍 " .. category .. ":")
            for test, status in pairs(results) do
                print("  " .. test .. ": " .. tostring(status))
            end
            print("")
        else
            print(category .. ": " .. tostring(results))
        end
    end
end

print("✅ TIM3 Integration Test Suite Loaded!")
print("📚 Available functions:")
print("  runFullIntegrationSuite() - Complete test suite")
print("  testSystemCommunication() - Test inter-process communication")
print("  checkSystemHealth() - Check all process health")
print("  testMintingFlow() - Test USDA → TIM3 minting")
print("  testRedemptionFlow() - Test TIM3 → USDA redemption")
print("  checkStateConsistency() - Check cross-process state")
print("  testErrorHandling() - Test error scenarios")
print("  quickHealthCheck() - Quick system health")
print("  quickMint(amount) - Quick mint test")
print("  quickBurn(amount) - Quick burn test")
print("  quickBalance() - Quick balance check")
print("  showTestResults() - Display test results")
print("")
print("🚀 Ready for integration testing!")

-- TIM3 Proper Integration Test Suite
-- Professional approach to multi-process testing

describe("TIM3 Proper Integration Tests", function()
    local json = require("cjson")
    local mock_ao = require("test.mock_ao")
    
    -- Process simulators - each process in isolation
    local function setupCoordinator()
        mock_ao.reset()
        dofile("../coordinator/src/process.lua")
        mock_ao.clearSentMessages()
        
        -- Configure for testing
        Config.systemActive = true
        Config.mockUsdaProcess = "mock-usda-123"
        Config.stateManagerProcess = "state-manager-123"
        Config.lockManagerProcess = "lock-manager-123"
        Config.tokenManagerProcess = "token-manager-123"
    end
    
    local function setupMockUsda()
        mock_ao.reset()
        dofile("../mock-usda/src/process.lua")
        mock_ao.clearSentMessages()
    end
    
    local function setupLockManager()
        mock_ao.reset()
        dofile("../lock-manager/src/process.lua")
        mock_ao.clearSentMessages()
        
        -- Configure for testing
        Config.coordinatorProcess = "coordinator-123"
        Config.mockUsdaProcess = "mock-usda-123"
        Config.requireConfirmation = false
    end
    
    describe("User Journey: Complete TIM3 Minting Flow", function()
        it("should complete step-by-step user flow", function()
            local user = "alice"
            local tim3Amount = 100
            local expectedCollateral = 150  -- 100 * 1.5
            
            print("\n🚀 STARTING USER JOURNEY: Alice wants to mint 100 TIM3")
            print("   Required collateral: " .. expectedCollateral .. " USDA")
            
            -- STEP 1: User starts with USDA balance
            print("\n📍 STEP 1: Check Alice's initial USDA balance")
            setupMockUsda()
            Balances[user] = 1000  -- Give Alice 1000 USDA
            
            local balanceMsg = { From = user, Tags = { Action = "Balance" } }
            Handlers.evaluate(balanceMsg, balanceMsg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Balance-Response", messages[1].Action)
            
            local balanceData = json.decode(messages[1].Data)
            print("   ✅ Alice's USDA balance: " .. balanceData.balance)
            assert.are.equal("1000", balanceData.balance)
            
            -- STEP 2: Alice sends MintTIM3 request to Coordinator
            print("\n📍 STEP 2: Alice requests to mint TIM3")
            setupCoordinator()
            
            local mintMsg = {
                From = user,
                Tags = {
                    Action = "MintTIM3",
                    Amount = tostring(tim3Amount)
                }
            }
            
            print("   Sending MintTIM3 request...")
            Handlers.evaluate(mintMsg, mintMsg)
            
            local coordinatorMessages = mock_ao.getSentMessages()
            print("   📨 Coordinator sent " .. #coordinatorMessages .. " messages")
            
            assert.is_true(#coordinatorMessages >= 1, "Coordinator should respond")
            
            local response = coordinatorMessages[1]
            assert.are.equal(user, response.Target)
            print("   Response action: " .. response.Action)
            
            if response.Action == "MintTIM3-Response" then
                local responseData = json.decode(response.Data)
                print("   ✅ TIM3 minted: " .. responseData.tim3Minted)
                print("   ✅ Collateral locked: " .. responseData.collateralLocked)
                
                assert.are.equal(tostring(tim3Amount), responseData.tim3Minted)
                assert.are.equal(tostring(expectedCollateral), responseData.collateralLocked)
            else
                print("   ❌ Unexpected response: " .. response.Action)
                if response.Data then
                    print("   Error data: " .. response.Data)
                end
                assert.fail("Expected successful mint response")
            end
            
            -- STEP 3: Verify user position was recorded
            print("\n📍 STEP 3: Check Alice's position in Coordinator")
            
            local positionMsg = {
                From = user,
                Tags = { Action = "GetPosition" }
            }
            
            Handlers.evaluate(positionMsg, positionMsg)
            local positionMessages = mock_ao.getSentMessages()
            
            -- Clear previous messages and get new ones
            mock_ao.clearSentMessages()
            Handlers.evaluate(positionMsg, positionMsg)
            positionMessages = mock_ao.getSentMessages()
            
            assert.are.equal(1, #positionMessages)
            assert.are.equal("Position-Response", positionMessages[1].Action)
            
            local positionData = json.decode(positionMessages[1].Data)
            print("   ✅ Alice's collateral: " .. positionData.position.collateral)
            print("   ✅ Alice's TIM3 minted: " .. positionData.position.tim3Minted)
            print("   ✅ Health factor: " .. positionData.position.healthFactor)
            
            assert.are.equal(expectedCollateral, positionData.position.collateral)
            assert.are.equal(tim3Amount, positionData.position.tim3Minted)
            
            print("\n🎉 USER JOURNEY COMPLETED SUCCESSFULLY!")
            print("   Alice successfully minted " .. tim3Amount .. " TIM3 tokens")
            print("   Backed by " .. expectedCollateral .. " USDA collateral")
        end)
    end)
    
    describe("Process Communication Flow", function()
        it("should demonstrate message flow between processes", function()
            print("\n📡 DEMONSTRATING INTER-PROCESS COMMUNICATION")
            
            -- Setup Lock Manager
            print("\n📍 Setting up Lock Manager")
            setupLockManager()
            
            local user = "bob"
            local lockAmount = 200
            
            -- Send lock request to Lock Manager
            local lockMsg = {
                From = "coordinator-123",  -- Simulating coordinator request
                Tags = {
                    Action = "LockCollateral",
                    User = user,
                    Amount = tostring(lockAmount)
                }
            }
            
            print("   Sending LockCollateral request...")
            Handlers.evaluate(lockMsg, lockMsg)
            
            local messages = mock_ao.getSentMessages()
            print("   📨 Lock Manager sent " .. #messages .. " messages")
            
            for i, msg in ipairs(messages) do
                print("   Message " .. i .. ": " .. msg.Action .. " → " .. msg.Target)
                if msg.Tags then
                    for key, value in pairs(msg.Tags) do
                        print("     Tag " .. key .. ": " .. value)
                    end
                end
            end
            
            -- Should send messages to Mock USDA and back to coordinator
            assert.is_true(#messages >= 1, "Should send messages")
            
            print("\n💡 LESSON: This shows how processes coordinate!")
            print("   1. Lock Manager receives request from Coordinator")
            print("   2. Lock Manager sends lock request to Mock USDA")  
            print("   3. Lock Manager sends pending response to Coordinator")
            print("   4. (In real flow) Mock USDA would confirm back to Lock Manager")
        end)
    end)
end)
-- Advanced TIM3 Integration Tests
-- Testing complex scenarios and edge cases

describe("Advanced TIM3 Integration Scenarios", function()
    local json = require("cjson")
    local mock_ao = require("test.mock_ao")
    
    local function setupCoordinator()
        mock_ao.reset()
        dofile("../coordinator/src/process.lua")
        mock_ao.clearSentMessages()
        
        Config.systemActive = true
        Config.mockUsdaProcess = "mock-usda-123"
        Config.collateralRatio = 1.5
        Config.minMintAmount = 10
        Config.maxMintAmount = 100000
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
        
        Config.coordinatorProcess = "coordinator-123"
        Config.mockUsdaProcess = "mock-usda-123"
        Config.requireConfirmation = false
    end
    
    local function setupStateManager()
        mock_ao.reset()
        dofile("../state-manager/src/process.lua")
        mock_ao.clearSentMessages()
        
        Config.coordinatorProcess = "coordinator-123"
    end
    
    describe("Complex User Scenarios", function()
        it("should handle multiple users with different amounts", function()
            print("\n🎯 ADVANCED SCENARIO: Multiple Users")
            
            -- Setup users with different amounts
            local users = {
                { name = "alice", mintAmount = 50, expectedCollateral = 75 },
                { name = "bob", mintAmount = 200, expectedCollateral = 300 },
                { name = "charlie", mintAmount = 1000, expectedCollateral = 1500 }
            }
            
            setupCoordinator()
            
            for i, user in ipairs(users) do
                print("\n👤 Processing user: " .. user.name)
                print("   Minting: " .. user.mintAmount .. " TIM3")
                print("   Expected collateral: " .. user.expectedCollateral .. " USDA")
                
                local msg = {
                    From = user.name,
                    Tags = {
                        Action = "MintTIM3",
                        Amount = tostring(user.mintAmount)
                    }
                }
                
                mock_ao.clearSentMessages()
                Handlers.evaluate(msg, msg)
                
                local messages = mock_ao.getSentMessages()
                assert.are.equal(2, #messages, "Should send response + log message")
                
                local response = messages[1]
                assert.are.equal("MintTIM3-Response", response.Action)
                
                local data = json.decode(response.Data)
                assert.are.equal(tostring(user.mintAmount), data.tim3Minted)
                assert.are.equal(tostring(user.expectedCollateral), data.collateralLocked)
                
                print("   ✅ " .. user.name .. " successfully minted " .. user.mintAmount .. " TIM3")
            end
            
            print("\n📊 Checking system totals...")
            
            -- Check system health
            local healthMsg = { From = "admin", Tags = { Action = "SystemHealth" } }
            mock_ao.clearSentMessages()
            Handlers.evaluate(healthMsg, healthMsg)
            
            local healthMessages = mock_ao.getSentMessages()
            assert.are.equal(1, #healthMessages)
            
            local healthData = json.decode(healthMessages[1].Data)
            local totalCollateral = 75 + 300 + 1500  -- Sum of all collateral
            local totalTIM3 = 50 + 200 + 1000        -- Sum of all TIM3
            
            print("   Total collateral: " .. healthData.totalCollateral)
            print("   Total TIM3 minted: " .. healthData.totalTIM3Minted)
            print("   Global ratio: " .. healthData.globalCollateralRatio)
            
            assert.are.equal(tostring(totalCollateral), healthData.totalCollateral)
            assert.are.equal(tostring(totalTIM3), healthData.totalTIM3Minted)
            
            print("   ✅ System totals are correct!")
        end)
    end)
    
    describe("Error Handling and Edge Cases", function()
        it("should properly handle invalid requests", function()
            print("\n⚠️  TESTING ERROR SCENARIOS")
            
            setupCoordinator()
            
            local errorTests = {
                {
                    name = "Zero amount",
                    msg = { From = "user1", Tags = { Action = "MintTIM3", Amount = "0" } },
                    expectedError = "Invalid amount"
                },
                {
                    name = "Negative amount", 
                    msg = { From = "user1", Tags = { Action = "MintTIM3", Amount = "-50" } },
                    expectedError = "Invalid amount"
                },
                {
                    name = "Too small amount",
                    msg = { From = "user1", Tags = { Action = "MintTIM3", Amount = "5" } },
                    expectedError = "Amount below minimum"
                },
                {
                    name = "Too large amount",
                    msg = { From = "user1", Tags = { Action = "MintTIM3", Amount = "200000" } },
                    expectedError = "Amount above maximum"
                }
            }
            
            for _, test in ipairs(errorTests) do
                print("\n🧪 Testing: " .. test.name)
                
                mock_ao.clearSentMessages()
                Handlers.evaluate(test.msg, test.msg)
                
                local messages = mock_ao.getSentMessages()
                assert.are.equal(1, #messages, "Should send error response")
                
                local response = messages[1]
                assert.are.equal("MintTIM3-Error", response.Action)
                assert.is_true(string.find(response.Data, test.expectedError) ~= nil, 
                    "Should contain expected error: " .. test.expectedError)
                
                print("   ✅ Correctly rejected: " .. response.Data)
            end
        end)
        
        it("should handle system inactive state", function()
            print("\n🔒 TESTING SYSTEM INACTIVE")
            
            setupCoordinator()
            Config.systemActive = false  -- Disable system
            
            local msg = {
                From = "user1",
                Tags = { Action = "MintTIM3", Amount = "100" }
            }
            
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            
            local response = messages[1]
            assert.are.equal("MintTIM3-Error", response.Action)
            assert.are.equal("System is currently inactive", response.Data)
            
            print("   ✅ System correctly blocked inactive requests")
        end)
    end)
    
    describe("Cross-Process State Consistency", function()
        it("should maintain consistent state across processes", function()
            print("\n🔄 TESTING STATE CONSISTENCY")
            
            local user = "david"
            local mintAmount = 150
            local expectedCollateral = 225
            
            -- Step 1: Mint TIM3 in Coordinator  
            print("\n📍 Step 1: Mint in Coordinator")
            setupCoordinator()
            
            local mintMsg = {
                From = user,
                Tags = { Action = "MintTIM3", Amount = tostring(mintAmount) }
            }
            
            Handlers.evaluate(mintMsg, mintMsg)
            
            local coordinatorMessages = mock_ao.getSentMessages()
            assert.are.equal(2, #coordinatorMessages)
            assert.are.equal("MintTIM3-Response", coordinatorMessages[1].Action)
            
            print("   ✅ Coordinator recorded: " .. mintAmount .. " TIM3, " .. expectedCollateral .. " collateral")
            
            -- Step 2: Check if State Manager would receive consistent data
            print("\n📍 Step 2: Check State Manager consistency")
            setupStateManager()
            
            -- Simulate position update from coordinator
            local updateMsg = {
                From = "coordinator-123",
                Tags = {
                    Action = "UpdatePosition",
                    User = user,
                    Collateral = tostring(expectedCollateral),
                    TIM3Balance = tostring(mintAmount),
                    Operation = "update"
                }
            }
            
            Handlers.evaluate(updateMsg, updateMsg)
            
            -- Check position
            mock_ao.clearSentMessages()
            local positionMsg = {
                From = "admin",
                Tags = { Action = "GetPosition", User = user }
            }
            
            Handlers.evaluate(positionMsg, positionMsg)
            
            local stateMessages = mock_ao.getSentMessages()
            assert.are.equal(1, #stateMessages)
            
            local positionData = json.decode(stateMessages[1].Data)
            assert.are.equal(expectedCollateral, tonumber(positionData.position.collateral))
            assert.are.equal(mintAmount, tonumber(positionData.position.tim3Balance))
            
            print("   ✅ State Manager has consistent data")
            print("   User collateral: " .. positionData.position.collateral)
            print("   User TIM3 balance: " .. positionData.position.tim3Balance)
            print("   Health factor: " .. positionData.position.healthFactor)
        end)
    end)
end)
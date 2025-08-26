-- TIM3 Coordinator Process Test Suite
-- Comprehensive tests for the main TIM3 orchestrator process

describe("TIM3 Coordinator Process", function()
    local json = require("cjson")
    local mock_ao = require("test.mock_ao")
    
    before_each(function()
        mock_ao.reset()
        dofile("src/process.lua")
        mock_ao.clearSentMessages()
    end)
    
    describe("Basic Operations", function()
        it("should handle Info request", function()
            local msg = { From = "user1", Tags = { Action = "Info" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("user1", messages[1].Target)
            assert.are.equal("Info-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("TIM3 Coordinator", data.name)
            assert.are.equal("TIM3-COORD", data.ticker)
            assert.are.equal("1.0.0", data.version)
            assert.are.equal(true, data.systemActive)
            assert.are.equal(1.5, data.collateralRatio)
        end)
        
        it("should handle configuration updates", function()
            local msg = { 
                From = "admin", 
                Tags = { 
                    Action = "Configure", 
                    ConfigType = "CollateralRatio", 
                    Value = "1.8" 
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Configure-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("CollateralRatio", data.configType)
            assert.are.equal("1.8", data.value)
            assert.are.equal(true, data.success)
            
            -- Check that config was updated
            assert.are.equal(1.8, Config.collateralRatio)
        end)
        
        it("should handle process configuration", function()
            local msg = { 
                From = "admin", 
                Tags = { 
                    Action = "Configure", 
                    ConfigType = "MockUsdaProcess", 
                    Value = "mock-usda-123" 
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Configure-Response", messages[1].Action)
            
            -- Check that mock USDA process was configured
            assert.are.equal("mock-usda-123", Config.mockUsdaProcess)
        end)
        
        it("should reject unknown configuration", function()
            local msg = { 
                From = "admin", 
                Tags = { 
                    Action = "Configure", 
                    ConfigType = "InvalidConfig", 
                    Value = "test" 
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Configure-Error", messages[1].Action)
            assert.is.truthy(string.find(messages[1].Data, "Unknown configuration type"))
        end)
    end)
    
    describe("Position Management", function()
        it("should return empty position for new user", function()
            local msg = { From = "user1", Tags = { Action = "GetPosition" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Position-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.user)
            assert.are.equal(0, data.position.collateral)
            assert.are.equal(0, data.position.tim3Minted)
            assert.are.equal(0, data.position.collateralRatio)
        end)
        
        it("should return position for specific user", function()
            -- Set up a position
            UserPositions["user2"] = {
                collateral = 1500,
                tim3Minted = 1000,
                collateralRatio = 1.5,
                healthFactor = 1.0
            }
            
            local msg = { 
                From = "admin", 
                Tags = { Action = "GetPosition", User = "user2" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Position-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user2", data.user)
            assert.are.equal(1500, data.position.collateral)
            assert.are.equal(1000, data.position.tim3Minted)
            assert.are.equal(1.5, data.position.collateralRatio)
        end)
    end)
    
    describe("TIM3 Minting", function()
        before_each(function()
            -- Configure Mock USDA process
            Config.mockUsdaProcess = "mock-usda-123"
            Config.systemActive = true
        end)
        
        it("should mint TIM3 tokens successfully", function()
            local msg = { 
                From = "user1", 
                Tags = { Action = "MintTIM3", Amount = "100" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)  -- Response + Log
            assert.are.equal("MintTIM3-Response", messages[1].Action)
            assert.are.equal("MintTIM3-Log", messages[2].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.user)
            assert.are.equal("100", data.tim3Minted)
            assert.are.equal("150", data.collateralLocked)  -- 100 * 1.5 ratio
            
            -- Check position was created
            local position = UserPositions["user1"]
            assert.is.not_nil(position)
            assert.are.equal(150, position.collateral)
            assert.are.equal(100, position.tim3Minted)
            assert.are.equal(1.5, position.collateralRatio)
            assert.are.equal(1.0, position.healthFactor)
        end)
        
        it("should reject minting when system is inactive", function()
            Config.systemActive = false
            
            local msg = { 
                From = "user1", 
                Tags = { Action = "MintTIM3", Amount = "100" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("MintTIM3-Error", messages[1].Action)
            assert.are.equal("System is currently inactive", messages[1].Data)
        end)
        
        it("should reject invalid mint amounts", function()
            local msg = { 
                From = "user1", 
                Tags = { Action = "MintTIM3", Amount = "5" }  -- Below minimum
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("MintTIM3-Error", messages[1].Action)
            assert.is.truthy(string.find(messages[1].Data, "below minimum"))
        end)
        
        it("should reject minting without Mock USDA process configured", function()
            Config.mockUsdaProcess = nil
            
            local msg = { 
                From = "user1", 
                Tags = { Action = "MintTIM3", Amount = "100" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("MintTIM3-Error", messages[1].Action)
            assert.are.equal("Mock USDA process not configured", messages[1].Data)
        end)
        
        it("should update global statistics on minting", function()
            local initialCollateral = Config.totalCollateral
            local initialMinted = Config.totalTIM3Minted
            
            local msg = { 
                From = "user1", 
                Tags = { Action = "MintTIM3", Amount = "200" } 
            }
            Handlers.evaluate(msg, msg)
            
            -- Check global state updated
            assert.are.equal(initialCollateral + 300, Config.totalCollateral)  -- 200 * 1.5
            assert.are.equal(initialMinted + 200, Config.totalTIM3Minted)
        end)
    end)
    
    describe("TIM3 Burning", function()
        before_each(function()
            Config.systemActive = true
            -- Set up user with existing position
            UserPositions["user1"] = {
                collateral = 300,
                tim3Minted = 200,
                collateralRatio = 1.5,
                healthFactor = 1.0
            }
            Config.totalCollateral = 300
            Config.totalTIM3Minted = 200
        end)
        
        it("should burn TIM3 tokens successfully", function()
            local msg = { 
                From = "user1", 
                Tags = { Action = "BurnTIM3", Amount = "100" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)  -- Response + Log
            assert.are.equal("BurnTIM3-Response", messages[1].Action)
            assert.are.equal("BurnTIM3-Log", messages[2].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.user)
            assert.are.equal("100", data.tim3Burned)
            assert.are.equal("150", data.collateralReleased)  -- Half of 300
            
            -- Check position was updated
            local position = UserPositions["user1"]
            assert.are.equal(150, position.collateral)
            assert.are.equal(100, position.tim3Minted)
            assert.are.equal(1.5, position.collateralRatio)
        end)
        
        it("should reject burning when system is inactive", function()
            Config.systemActive = false
            
            local msg = { 
                From = "user1", 
                Tags = { Action = "BurnTIM3", Amount = "50" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("BurnTIM3-Error", messages[1].Action)
            assert.are.equal("System is currently inactive", messages[1].Data)
        end)
        
        it("should reject burning more than user has", function()
            local msg = { 
                From = "user1", 
                Tags = { Action = "BurnTIM3", Amount = "300" }  -- User only has 200
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("BurnTIM3-Error", messages[1].Action)
            assert.are.equal("Insufficient TIM3 balance to burn", messages[1].Data)
        end)
        
        it("should reject burning for user with no position", function()
            local msg = { 
                From = "user2",  -- User with no position
                Tags = { Action = "BurnTIM3", Amount = "50" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("BurnTIM3-Error", messages[1].Action)
            assert.are.equal("Insufficient TIM3 balance to burn", messages[1].Data)
        end)
        
        it("should clear position when burning all TIM3", function()
            local msg = { 
                From = "user1", 
                Tags = { Action = "BurnTIM3", Amount = "200" }  -- Burn all
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)
            assert.are.equal("BurnTIM3-Response", messages[1].Action)
            
            -- Check position was cleared
            local position = UserPositions["user1"]
            assert.are.equal(0, position.collateral)
            assert.are.equal(0, position.tim3Minted)
            assert.are.equal(0, position.collateralRatio)
            assert.are.equal(0, position.healthFactor)
        end)
    end)
    
    describe("System Health", function()
        it("should report system health with no positions", function()
            local msg = { From = "admin", Tags = { Action = "SystemHealth" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("SystemHealth-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal(true, data.systemActive)
            assert.are.equal("0", data.totalCollateral)
            assert.are.equal("0", data.totalTIM3Minted)
            assert.are.equal("0", data.globalCollateralRatio)
            assert.are.equal("1.5", data.targetCollateralRatio)
            assert.are.equal(0, data.userPositions)
        end)
        
        it("should report system health with active positions", function()
            -- Set up multiple user positions
            UserPositions["user1"] = { collateral = 300, tim3Minted = 200 }
            UserPositions["user2"] = { collateral = 450, tim3Minted = 300 }
            Config.totalCollateral = 750
            Config.totalTIM3Minted = 500
            
            local msg = { From = "admin", Tags = { Action = "SystemHealth" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("SystemHealth-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("750", data.totalCollateral)
            assert.are.equal("500", data.totalTIM3Minted)
            assert.are.equal("1.5", data.globalCollateralRatio)  -- 750/500
            assert.are.equal(2, data.userPositions)
        end)
    end)
end)
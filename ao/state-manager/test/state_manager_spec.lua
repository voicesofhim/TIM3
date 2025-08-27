-- TIM3 State Manager Process Test Suite
-- Comprehensive tests for collateral ratio tracking and risk management

describe("TIM3 State Manager Process", function()
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
            assert.are.equal("TIM3 State Manager", data.name)
            assert.are.equal("TIM3-STATE", data.ticker)
            assert.are.equal("1.0.0", data.version)
        end)
        
        it("should handle configuration updates", function()
            local msg = { 
                From = "admin", 
                Tags = { 
                    Action = "Configure", 
                    ConfigType = "TargetCollateralRatio", 
                    Value = "2.0" 
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Configure-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("TargetCollateralRatio", data.configType)
            assert.are.equal("2.0", data.value)
            assert.are.equal(true, data.success)
            
            -- Check that config was updated
            assert.are.equal(2.0, SystemState.targetCollateralRatio)
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
            assert.are.equal("0", data.position.collateral)
            assert.are.equal("0", data.position.tim3Balance)
            assert.are.equal("healthy", data.position.riskLevel)
        end)
        
        it("should update user position", function()
            local msg = { 
                From = "coordinator", 
                Tags = { 
                    Action = "UpdatePosition",
                    User = "user1",
                    Collateral = "1000",
                    TIM3Balance = "1000",
                    Operation = "update"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("UpdatePosition-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.user)
            assert.are.equal("1000", data.position.collateral)
            assert.are.equal("1000", data.position.tim3Balance)
            assert.are.equal("1", data.position.healthFactor)
            assert.are.equal("healthy", data.position.riskLevel)
        end)
        
        it("should add to existing position", function()
            -- Set up existing position
            UserPositions["user1"] = {
                collateral = 1000,
                tim3Balance = 500,
                healthFactor = 2.0,
                riskLevel = "healthy",
                lastUpdate = os.time()
            }
            SystemState.totalCollateral = 1000
            SystemState.totalTIM3Supply = 500
            
            local msg = { 
                From = "coordinator", 
                Tags = { 
                    Action = "UpdatePosition",
                    User = "user1",
                    Collateral = "500",
                    TIM3Balance = "250",
                    Operation = "add"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local position = UserPositions["user1"]
            assert.are.equal(1500, position.collateral)  -- 1000 + 500
            assert.are.equal(750, position.tim3Balance)   -- 500 + 250
            assert.are.equal(1500, SystemState.totalCollateral)
            assert.are.equal(750, SystemState.totalTIM3Supply)
        end)
    end)
    
    describe("System Health Monitoring", function()
        it("should report system health with no positions", function()
            local msg = { From = "admin", Tags = { Action = "SystemHealth" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("SystemHealth-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("0", data.systemState.totalCollateral)
            assert.are.equal("0", data.systemState.totalTIM3Supply)
            assert.are.equal("0", data.systemState.globalCollateralRatio)
            assert.are.equal(0, data.systemState.activePositions)
            assert.are.equal(85, data.systemState.systemHealthScore)  -- 100 - 15 (global ratio < target)
        end)
        
        it("should calculate risk metrics with multiple positions", function()
            -- Set up multiple positions with different risk levels
            UserPositions["user1"] = { collateral = 1000, tim3Balance = 1000 }  -- 1.0 - healthy
            UserPositions["user2"] = { collateral = 950, tim3Balance = 1000 }   -- 0.95 - warning  
            UserPositions["user3"] = { collateral = 900, tim3Balance = 1000 }   -- 0.9 - danger
            UserPositions["user4"] = { collateral = 800, tim3Balance = 1000 }   -- 0.8 - critical
            
            SystemState.totalCollateral = 3650
            SystemState.totalTIM3Supply = 4000
            
            local msg = { From = "admin", Tags = { Action = "SystemHealth" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("3650", data.systemState.totalCollateral)
            assert.are.equal("4000", data.systemState.totalTIM3Supply)
            assert.are.equal("0.9125", data.systemState.globalCollateralRatio)
            assert.are.equal(4, data.systemState.activePositions)
            
            assert.are.equal(1, data.riskMetrics.underCollateralizedPositions)  -- user4 (0.8) - critical
            assert.are.equal(2, data.riskMetrics.atRiskPositions)               -- user2 (0.95) warning, user3 (0.9) danger
            assert.are.equal(1, data.riskMetrics.healthyPositions)              -- user1 (1.0) - healthy
        end)
    end)
    
    describe("Risk Monitoring", function()
        it("should detect liquidatable positions", function()
            -- Set up positions with low health factors
            UserPositions["user1"] = { collateral = 1100, tim3Balance = 1000 }  -- 1.1 - below liquidation threshold
            UserPositions["user2"] = { collateral = 1500, tim3Balance = 1000 }  -- 1.5 - healthy
            
            SystemState.liquidationThreshold = 1.2
            
            local msg = { From = "admin", Tags = { Action = "CheckLiquidations" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Liquidations-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal(1, data.liquidatableCount)
            assert.are.equal("user1", data.positions[1].user)
            assert.are.equal(1.1, tonumber(data.positions[1].healthFactor))  -- Compare as number to handle float precision
            assert.are.equal(900, data.positions[1].liquidationValue)  -- 1000 * 0.9 (returned as number)
        end)
        
        it("should send risk alerts to coordinator", function()
            -- Configure coordinator
            Config.coordinatorProcess = "coordinator-123"
            
            -- Set up risky position
            UserPositions["user1"] = { collateral = 800, tim3Balance = 1000 }  -- 0.8 - critical level
            
            local msg = { From = "admin", Tags = { Action = "CheckRiskAlerts" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)
            assert.are.equal("RiskAlerts-Response", messages[1].Action)
            assert.are.equal("Risk-Alert", messages[2].Action)
            assert.are.equal("coordinator-123", messages[2].Target)
            
            local alertData = json.decode(messages[2].Data)
            assert.are.equal(1, alertData.alertCount)
            assert.are.equal("user1", alertData.criticalAlerts[1].user)
        end)
    end)
    
    describe("Error Handling", function()
        it("should reject position update without user", function()
            local msg = { 
                From = "coordinator", 
                Tags = { 
                    Action = "UpdatePosition",
                    Collateral = "1000",
                    TIM3Balance = "500"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("UpdatePosition-Error", messages[1].Action)
            assert.are.equal("User required", messages[1].Data)
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
end)
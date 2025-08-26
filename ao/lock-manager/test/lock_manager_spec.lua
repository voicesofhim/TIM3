-- TIM3 Lock Manager Process Test Suite
-- Comprehensive tests for USDA collateral locking and unlocking

describe("TIM3 Lock Manager Process", function()
    local json = require("cjson")
    local mock_ao = require("test.mock_ao")
    
    before_each(function()
        mock_ao.reset()
        dofile("src/process.lua")
        mock_ao.clearSentMessages()
        
        -- Configure for testing
        Config.coordinatorProcess = "coordinator-123"
        Config.mockUsdaProcess = "mock-usda-123"
        Config.requireConfirmation = false  -- Allow testing without auth
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
            assert.are.equal("TIM3 Lock Manager", data.name)
            assert.are.equal("TIM3-LOCK", data.ticker)
            assert.are.equal("1.0.0", data.version)
            assert.are.equal(true, data.config.mockUsdaConfigured)
        end)
        
        it("should handle configuration updates", function()
            local msg = { 
                From = "admin", 
                Tags = { 
                    Action = "Configure", 
                    ConfigType = "MinLockAmount", 
                    Value = "50" 
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Configure-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("MinLockAmount", data.configType)
            assert.are.equal("50", data.value)
            assert.are.equal(true, data.success)
            
            -- Check that config was updated
            assert.are.equal(50, Config.minLockAmount)
        end)
    end)
    
    describe("Collateral Locking", function()
        it("should initiate collateral lock", function()
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "LockCollateral",
                    User = "user1",
                    Amount = "1500"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)
            
            -- Check Lock request sent to Mock USDA
            assert.are.equal("mock-usda-123", messages[1].Target)
            assert.are.equal("Lock", messages[1].Action)
            assert.are.equal("user1", messages[1].Tags.User)
            assert.are.equal("1500", messages[1].Tags.Amount)
            
            -- Check pending response sent to coordinator
            assert.are.equal("coordinator-123", messages[2].Target)
            assert.are.equal("LockCollateral-Pending", messages[2].Action)
            
            local data = json.decode(messages[2].Data)
            assert.are.equal("user1", data.user)
            assert.are.equal("1500", data.amount)
            assert.are.equal("pending", data.status)
        end)
        
        it("should reject lock with invalid amount", function()
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "LockCollateral",
                    User = "user1",
                    Amount = "5"  -- Below minimum
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("LockCollateral-Error", messages[1].Action)
            assert.is.truthy(string.find(messages[1].Data, "below minimum"))
        end)
        
        it("should reject lock without Mock USDA configured", function()
            Config.mockUsdaProcess = nil
            
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "LockCollateral",
                    User = "user1",
                    Amount = "1000"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("LockCollateral-Error", messages[1].Action)
            assert.are.equal("Mock USDA process not configured", messages[1].Data)
        end)
    end)
    
    describe("Lock Confirmation", function()
        it("should handle successful lock confirmation", function()
            -- First, initiate a lock
            local lockMsg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "LockCollateral",
                    User = "user1",
                    Amount = "1500"
                } 
            }
            Handlers.evaluate(lockMsg, lockMsg)
            mock_ao.clearSentMessages()
            
            -- Simulate Mock USDA confirmation
            local lockId = "user1-lock-1640995200-10"  -- Based on fixed time/random
            local confirmMsg = {
                From = "mock-usda-123",
                Tags = { Action = "Lock-Confirmed" },
                Data = json.encode({
                    user = "user1",
                    amount = "1500",
                    lockId = lockId
                })
            }
            Handlers.evaluate(confirmMsg, confirmMsg)
            
            local messages = mock_ao.getSentMessages()
            assert.is_true(#messages >= 1)
            assert.are.equal("coordinator-123", messages[1].Target)
            assert.are.equal("LockCollateral-Success", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal(lockId, data.lockId)
            assert.are.equal("user1", data.user)
            assert.are.equal("1500", data.amount)
            assert.are.equal("locked", data.status)
            
            -- Check that lock was recorded
            local lockRecord = CollateralLocks[lockId]
            assert.is.not_nil(lockRecord)
            assert.are.equal("locked", lockRecord.status)
            assert.are.equal(1500, lockRecord.amount)
            
            -- Check stats were updated
            assert.are.equal(1500, LockStats.totalLocked)
            assert.are.equal(1, LockStats.totalLocks)
            assert.are.equal(1, LockStats.activeLocks)
        end)
    end)
    
    describe("Collateral Unlocking", function()
        before_each(function()
            -- Set up a locked position
            local lockId = "user1-lock-123"
            CollateralLocks[lockId] = {
                lockId = lockId,
                user = "user1",
                amount = 1500,
                purpose = "TIM3-mint",
                status = "locked",
                requestor = "coordinator-123",
                timestamp = os.time(),
                usdaLockId = "usda-lock-456"
            }
            LockStats.activeLocks = 1
        end)
        
        it("should initiate collateral unlock by lockId", function()
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "UnlockCollateral",
                    LockId = "user1-lock-123",
                    Amount = "750"  -- Partial unlock
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)
            
            -- Check Unlock request sent to Mock USDA
            assert.are.equal("mock-usda-123", messages[1].Target)
            assert.are.equal("Unlock", messages[1].Action)
            assert.are.equal("user1", messages[1].Tags.User)
            assert.are.equal("750", messages[1].Tags.Amount)
            
            -- Check pending response
            assert.are.equal("coordinator-123", messages[2].Target)
            assert.are.equal("UnlockCollateral-Pending", messages[2].Action)
            
            local data = json.decode(messages[2].Data)
            assert.are.equal("user1-lock-123", data.lockId)
            assert.are.equal("750", data.unlockAmount)
            assert.are.equal("unlocking", data.status)
        end)
        
        it("should reject unlock for non-existent lock", function()
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "UnlockCollateral",
                    LockId = "non-existent-lock"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("UnlockCollateral-Error", messages[1].Action)
            assert.are.equal("Lock not found or not in locked state", messages[1].Data)
        end)
    end)
    
    describe("Lock Information", function()
        it("should return lock info for user", function()
            -- Set up locks
            CollateralLocks["lock1"] = { user = "user1", amount = 1000, status = "locked", timestamp = 123, purpose = "TIM3" }
            CollateralLocks["lock2"] = { user = "user1", amount = 500, status = "pending", timestamp = 124, purpose = "TIM3" }
            CollateralLocks["lock3"] = { user = "user2", amount = 750, status = "locked", timestamp = 125, purpose = "TIM3" }
            
            local msg = { 
                From = "admin", 
                Tags = { 
                    Action = "GetLockInfo",
                    User = "user1"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("LockInfo-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal(2, data.count)  -- user1 has 2 locks
            assert.is.not_nil(data.locks["lock1"])
            assert.is.not_nil(data.locks["lock2"])
            assert.is_nil(data.locks["lock3"])  -- Different user
        end)
        
        it("should return lock statistics", function()
            LockStats.totalLocked = 5000
            LockStats.totalLocks = 10
            LockStats.activeLocks = 8
            LockStats.totalUnlocked = 1500
            
            local msg = { From = "admin", Tags = { Action = "LockStats" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("LockStats-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("5000", data.totalLocked)
            assert.are.equal(10, data.totalLocks)
            assert.are.equal(8, data.activeLocks)
            assert.are.equal("1500", data.totalUnlocked)
        end)
    end)
    
    describe("Authorization", function()
        before_each(function()
            Config.requireConfirmation = true
            Config.coordinatorProcess = "coordinator-123"
        end)
        
        it("should allow coordinator to lock collateral", function()
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "LockCollateral",
                    User = "user1",
                    Amount = "1000"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)  -- Request to USDA + pending response
            assert.are.equal("LockCollateral-Pending", messages[2].Action)
        end)
        
        it("should reject unauthorized lock request", function()
            local msg = { 
                From = "unauthorized-process", 
                Tags = { 
                    Action = "LockCollateral",
                    User = "user1",
                    Amount = "1000"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("LockCollateral-Error", messages[1].Action)
            assert.are.equal("Unauthorized caller", messages[1].Data)
        end)
    end)
end)
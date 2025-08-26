-- Simplified Mock USDA Test Suite
-- Core functionality tests with proper mocking

describe("Mock USDA Core Functions", function()
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
            assert.are.equal("Mock USDA", data.name)
            assert.are.equal("mUSDT", data.ticker)
        end)
        
        it("should handle Balance request", function()
            local msg = { From = "user1", Tags = { Action = "Balance" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Balance-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.target)
            assert.are.equal("0", data.balance)
        end)
        
        it("should mint tokens", function()
            local msg = { From = "user1", Tags = { Action = "Mint", Amount = "500" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Mint-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.recipient)
            assert.are.equal("500", data.amount)
            
            -- Check that balance was updated
            assert.are.equal(500, Balances["user1"])
            assert.are.equal(500, TotalSupply)
        end)
        
        it("should transfer tokens", function()
            -- Set up initial balance
            Balances["user1"] = 1000
            
            local msg = { 
                From = "user1", 
                Tags = { Action = "Transfer", Recipient = "user2", Amount = "300" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)  -- Transfer response + Credit notice
            assert.are.equal("Transfer-Response", messages[1].Action)
            assert.are.equal("Credit-Notice", messages[2].Action)
            
            -- Check balances were updated
            assert.are.equal(700, Balances["user1"])
            assert.are.equal(300, Balances["user2"])
        end)
        
        it("should lock tokens", function()
            -- Set up initial balance
            Balances["user1"] = 1000
            
            local msg = { 
                From = "user1", 
                Tags = { Action = "Lock", Amount = "400" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Lock-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.user)
            assert.are.equal("400", data.amount)
            
            -- Check that tokens were locked
            assert.are.equal(400, Locked["user1"])
        end)
        
        it("should unlock tokens", function()
            -- Set up initial state
            Balances["user1"] = 1000
            Locked["user1"] = 400
            
            local msg = { 
                From = "tim3-manager", 
                Tags = { Action = "Unlock", User = "user1", Amount = "200" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)  -- Response + Notice
            assert.are.equal("Unlock-Response", messages[1].Action)
            assert.are.equal("Unlock-Notice", messages[2].Action)
            
            -- Check that tokens were unlocked
            assert.are.equal(200, Locked["user1"])  -- 400 - 200
        end)
        
        it("should prevent transfers with insufficient balance", function()
            Balances["user1"] = 100  -- Only 100 tokens
            
            local msg = { 
                From = "user1", 
                Tags = { Action = "Transfer", Recipient = "user2", Amount = "500" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Transfer-Error", messages[1].Action)
            assert.are.equal("Insufficient available balance", messages[1].Data)
        end)
        
        it("should account for locked tokens in transfers", function()
            Balances["user1"] = 1000
            Locked["user1"] = 600  -- 600 locked, 400 available
            
            local msg = { 
                From = "user1", 
                Tags = { Action = "Transfer", Recipient = "user2", Amount = "500" } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Transfer-Error", messages[1].Action)
            assert.are.equal("Insufficient available balance", messages[1].Data)
        end)
    end)
end)
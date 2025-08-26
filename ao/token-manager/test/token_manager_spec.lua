-- TIM3 Token Manager Process Test Suite
-- Comprehensive tests for TIM3 token minting, burning, and transfers

describe("TIM3 Token Manager Process", function()
    local json = require("cjson")
    local mock_ao = require("test.mock_ao")
    
    before_each(function()
        mock_ao.reset()
        dofile("src/process.lua")
        mock_ao.clearSentMessages()
        
        -- Configure for testing
        Config.coordinatorProcess = "coordinator-123"
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
            assert.are.equal("TIM3 Token Manager", data.processInfo.name)
            assert.are.equal("TIM3-TOKEN", data.processInfo.ticker)
            assert.are.equal("TIM3 Token", data.tokenInfo.name)
            assert.are.equal("TIM3", data.tokenInfo.ticker)
            assert.are.equal(6, data.tokenInfo.denomination)
        end)
        
        it("should handle Balance request", function()
            Balances["user1"] = 1500
            
            local msg = { From = "user1", Tags = { Action = "Balance" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Balance-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.target)
            assert.are.equal("1500", data.balance)
            assert.are.equal("TIM3", data.ticker)
        end)
        
        it("should handle Balances request", function()
            Balances["user1"] = 1000
            Balances["user2"] = 500
            Balances["user3"] = 0  -- Should not appear in response
            
            local msg = { From = "admin", Tags = { Action = "Balances" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Balances-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("1000", data["user1"])
            assert.are.equal("500", data["user2"])
            assert.is_nil(data["user3"])  -- Zero balance excluded
        end)
    end)
    
    describe("Token Minting", function()
        it("should mint tokens successfully", function()
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "Mint",
                    Recipient = "user1",
                    Amount = "1000"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)  -- Mint response + Credit notice
            
            -- Check mint response
            assert.are.equal("coordinator-123", messages[1].Target)
            assert.are.equal("Mint-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.recipient)
            assert.are.equal("1000", data.amount)
            assert.are.equal("1000", data.newBalance)
            assert.are.equal("1000", data.totalSupply)
            
            -- Check credit notice
            assert.are.equal("user1", messages[2].Target)
            assert.are.equal("Credit-Notice", messages[2].Action)
            
            -- Check balances were updated
            assert.are.equal(1000, Balances["user1"])
            assert.are.equal(1000, TokenStats.totalMinted)
            assert.are.equal(1, TokenStats.mintOperations)
        end)
        
        it("should reject minting when disabled", function()
            Config.mintingEnabled = false
            
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "Mint",
                    Recipient = "user1",
                    Amount = "1000"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Mint-Error", messages[1].Action)
            assert.are.equal("Minting is currently disabled", messages[1].Data)
        end)
        
        it("should reject minting without recipient", function()
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "Mint",
                    Amount = "1000"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Mint-Error", messages[1].Action)
            assert.are.equal("Recipient required", messages[1].Data)
        end)
        
        it("should reject minting above max supply", function()
            Config.maxSupply = 1000
            TokenStats.totalMinted = 500
            TokenStats.totalBurned = 0
            -- Update TokenInfo to reflect current supply
            TokenInfo.totalSupply = 500
            
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "Mint",
                    Recipient = "user1",
                    Amount = "600"  -- Would make total 1100, exceeding max
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal("Mint-Error", messages[1].Action)
            assert.are.equal("Minting would exceed max supply", messages[1].Data)
        end)
    end)
    
    describe("Token Burning", function()
        before_each(function()
            -- Set up user with balance
            Balances["user1"] = 1000
            TokenStats.totalMinted = 1000
        end)
        
        it("should burn tokens successfully", function()
            local msg = { 
                From = "user1", 
                Tags = { 
                    Action = "Burn",
                    Amount = "400"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)  -- Just burn response
            assert.are.equal("Burn-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.user)
            assert.are.equal("400", data.amount)
            assert.are.equal("600", data.newBalance)
            assert.are.equal("600", data.totalSupply)  -- 1000 minted - 400 burned
            
            -- Check balances were updated
            assert.are.equal(600, Balances["user1"])
            assert.are.equal(400, TokenStats.totalBurned)
            assert.are.equal(1, TokenStats.burnOperations)
        end)
        
        it("should reject burning when disabled", function()
            Config.burningEnabled = false
            
            local msg = { 
                From = "user1", 
                Tags = { 
                    Action = "Burn",
                    Amount = "100"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Burn-Error", messages[1].Action)
            assert.are.equal("Burning is currently disabled", messages[1].Data)
        end)
        
        it("should reject burning more than balance", function()
            local msg = { 
                From = "user1", 
                Tags = { 
                    Action = "Burn",
                    Amount = "1500"  -- User only has 1000
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Burn-Error", messages[1].Action)
            assert.are.equal("Insufficient balance to burn", messages[1].Data)
        end)
        
        it("should allow authorized burner to burn user tokens", function()
            Config.requireConfirmation = true
            Config.coordinatorProcess = "coordinator-123"
            
            local msg = { 
                From = "coordinator-123", 
                Tags = { 
                    Action = "Burn",
                    User = "user1",
                    Amount = "300"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)  -- Burn response + Debit notice
            
            assert.are.equal("Burn-Response", messages[1].Action)
            assert.are.equal("Debit-Notice", messages[2].Action)
            assert.are.equal("user1", messages[2].Target)
            
            -- Check balance was updated
            assert.are.equal(700, Balances["user1"])
        end)
    end)
    
    describe("Token Transfers", function()
        before_each(function()
            Balances["user1"] = 1000
            Balances["user2"] = 500
        end)
        
        it("should transfer tokens successfully", function()
            local msg = { 
                From = "user1", 
                Tags = { 
                    Action = "Transfer",
                    Recipient = "user2",
                    Amount = "300"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(2, #messages)  -- Transfer response + Credit notice
            
            -- Check transfer response
            assert.are.equal("user1", messages[1].Target)
            assert.are.equal("Transfer-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user2", data.recipient)
            assert.are.equal("300", data.amount)
            assert.are.equal("700", data.newBalance)  -- user1's new balance
            
            -- Check credit notice
            assert.are.equal("user2", messages[2].Target)
            assert.are.equal("Credit-Notice", messages[2].Action)
            
            -- Check balances were updated
            assert.are.equal(700, Balances["user1"])
            assert.are.equal(800, Balances["user2"])  -- 500 + 300
            assert.are.equal(1, TokenStats.totalTransfers)
        end)
        
        it("should reject transfer when disabled", function()
            Config.transfersEnabled = false
            
            local msg = { 
                From = "user1", 
                Tags = { 
                    Action = "Transfer",
                    Recipient = "user2",
                    Amount = "100"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Transfer-Error", messages[1].Action)
            assert.are.equal("Transfers are currently disabled", messages[1].Data)
        end)
        
        it("should reject transfer with insufficient balance", function()
            local msg = { 
                From = "user1", 
                Tags = { 
                    Action = "Transfer",
                    Recipient = "user2",
                    Amount = "1500"  -- user1 only has 1000
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Transfer-Error", messages[1].Action)
            assert.are.equal("Insufficient balance", messages[1].Data)
        end)
    end)
    
    describe("Token Statistics", function()
        it("should return token statistics", function()
            -- Set up some data
            Balances["user1"] = 1000
            Balances["user2"] = 500
            Balances["user3"] = 0  -- Should not count as holder
            TokenStats.totalMinted = 2000
            TokenStats.totalBurned = 500
            TokenStats.totalTransfers = 10
            TokenStats.mintOperations = 5
            TokenStats.burnOperations = 3
            
            local msg = { From = "admin", Tags = { Action = "TokenStats" } }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("TokenStats-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("TIM3 Token", data.tokenInfo.name)
            assert.are.equal("1500", data.tokenInfo.totalSupply)  -- 2000 - 500
            assert.are.equal("2000", data.statistics.totalMinted)
            assert.are.equal("500", data.statistics.totalBurned)
            assert.are.equal(10, data.statistics.totalTransfers)
            assert.are.equal(2, data.statistics.uniqueHolders)  -- user1, user2 (user3 has 0)
            assert.are.equal("1000", data.statistics.largestBalance)
            assert.are.equal(5, data.statistics.mintOperations)
            assert.are.equal(3, data.statistics.burnOperations)
        end)
    end)
    
    describe("Operation Tracking", function()
        it("should return mint operations for user", function()
            -- Set up mint operations
            MintOperations["mint1"] = { recipient = "user1", amount = 1000, timestamp = 123 }
            MintOperations["mint2"] = { recipient = "user2", amount = 500, timestamp = 124 }
            MintOperations["mint3"] = { recipient = "user1", amount = 300, timestamp = 125 }
            
            local msg = { 
                From = "admin", 
                Tags = { 
                    Action = "GetOperation",
                    OperationType = "mint",
                    User = "user1"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("Operation-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("mint", data.operationType)
            assert.are.equal(2, data.count)  -- user1 has 2 mint operations
            assert.is.not_nil(data.operations["mint1"])
            assert.is.not_nil(data.operations["mint3"])
            assert.is_nil(data.operations["mint2"])  -- Different user
        end)
        
        it("should reject invalid operation type", function()
            local msg = { 
                From = "admin", 
                Tags = { 
                    Action = "GetOperation",
                    OperationType = "invalid"
                } 
            }
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            assert.are.equal(1, #messages)
            assert.are.equal("GetOperation-Error", messages[1].Action)
            assert.are.equal("OperationType must be 'mint' or 'burn'", messages[1].Data)
        end)
    end)
end)
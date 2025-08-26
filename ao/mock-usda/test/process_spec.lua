-- Mock USDA Process Test Suite
-- Comprehensive testing for TIM3 development token

describe("Mock USDA Process", function()
    local json = require("json")
    local process
    local mockMsg
    
    -- Test utilities
    local function createMessage(from, action, tags)
        tags = tags or {}
        tags.Action = action
        return {
            From = from,
            Tags = tags
        }
    end
    
    local function captureMessage()
        local captured = {}
        ao.send = function(message)
            table.insert(captured, message)
        end
        return captured
    end
    
    before_each(function()
        -- Reset process state for each test
        package.loaded["process"] = nil
        dofile("src/process.lua")
        
        -- Reset global state
        Balances = {}
        TotalSupply = 0
        Locked = {}
    end)
    
    describe("Process Info", function()
        it("should return correct process information", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Info")
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(1, #messages)
            assert.are.equal("Info-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("Mock USDA", data.name)
            assert.are.equal("mUSDT", data.ticker)
            assert.are.equal(6, data.denomination)
            assert.are.equal(0, data.totalSupply)
        end)
    end)
    
    describe("Balance Operations", function()
        it("should return zero balance for new user", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Balance")
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(1, #messages)
            assert.are.equal("Balance-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.target)
            assert.are.equal("0", data.balance)
            assert.are.equal("0", data.locked)
            assert.are.equal("0", data.available)
        end)
        
        it("should return correct balance for user with tokens", function()
            Balances["user1"] = 1000
            
            local messages = captureMessage()
            local msg = createMessage("user1", "Balance")
            
            Handlers.evaluate(msg, msg)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("1000", data.balance)
            assert.are.equal("0", data.locked)
            assert.are.equal("1000", data.available)
        end)
        
        it("should calculate available balance correctly with locked amount", function()
            Balances["user1"] = 1000
            Locked["user1"] = 300
            
            local messages = captureMessage()
            local msg = createMessage("user1", "Balance")
            
            Handlers.evaluate(msg, msg)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("1000", data.balance)
            assert.are.equal("300", data.locked)
            assert.are.equal("700", data.available)
        end)
    end)
    
    describe("Minting", function()
        it("should mint tokens to sender by default", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Mint", { Amount = "500" })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(1, #messages)
            assert.are.equal("Mint-Response", messages[1].Action)
            
            local data = json.decode(messages[1].Data)
            assert.are.equal("user1", data.recipient)
            assert.are.equal("500", data.amount)
            assert.are.equal("500", data.newBalance)
            
            assert.are.equal(500, Balances["user1"])
            assert.are.equal(500, TotalSupply)
        end)
        
        it("should mint tokens to specified recipient", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Mint", { 
                Recipient = "user2",
                Amount = "1000"
            })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(2, #messages)  -- Response + Credit Notice
            assert.are.equal("Mint-Response", messages[1].Action)
            assert.are.equal("Credit-Notice", messages[2].Action)
            assert.are.equal("user2", messages[2].Target)
            
            assert.are.equal(1000, Balances["user2"])
            assert.are.equal(nil, Balances["user1"])
        end)
        
        it("should reject invalid mint amounts", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Mint", { Amount = "0" })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(1, #messages)
            assert.are.equal("Mint-Error", messages[1].Action)
            assert.are.equal("Invalid mint amount", messages[1].Data)
        end)
    end)
    
    describe("Transfers", function()
        before_each(function()
            -- Give user1 some tokens for transfer tests
            Balances["user1"] = 1000
        end)
        
        it("should transfer tokens successfully", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Transfer", {
                Recipient = "user2",
                Amount = "300"
            })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(2, #messages)  -- Response + Credit Notice
            assert.are.equal("Transfer-Response", messages[1].Action)
            assert.are.equal("Credit-Notice", messages[2].Action)
            
            local responseData = json.decode(messages[1].Data)
            assert.are.equal("user2", responseData.recipient)
            assert.are.equal("300", responseData.amount)
            assert.are.equal("700", responseData.newBalance)
            
            assert.are.equal(700, Balances["user1"])
            assert.are.equal(300, Balances["user2"])
        end)
        
        it("should reject transfer without recipient", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Transfer", { Amount = "300" })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(1, #messages)
            assert.are.equal("Transfer-Error", messages[1].Action)
            assert.are.equal("Recipient required", messages[1].Data)
        end)
        
        it("should reject transfer with insufficient balance", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Transfer", {
                Recipient = "user2", 
                Amount = "1500"  -- More than available
            })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(1, #messages)
            assert.are.equal("Transfer-Error", messages[1].Action)
            assert.are.equal("Insufficient available balance", messages[1].Data)
        end)
        
        it("should account for locked amounts in transfers", function()
            Locked["user1"] = 400  -- 400 locked, 600 available
            
            local messages = captureMessage()
            local msg = createMessage("user1", "Transfer", {
                Recipient = "user2",
                Amount = "700"  -- More than available (600)
            })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(1, #messages)
            assert.are.equal("Transfer-Error", messages[1].Action)
            assert.are.equal("Insufficient available balance", messages[1].Data)
        end)
    end)
    
    describe("Locking Operations", function()
        before_each(function()
            Balances["user1"] = 1000
        end)
        
        it("should lock tokens successfully", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Lock", {
                Amount = "300",
                Locker = "tim3-lock-manager"
            })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(2, #messages)  -- Response + Confirmation
            assert.are.equal("Lock-Response", messages[1].Action)
            assert.are.equal("Lock-Confirmed", messages[2].Action)
            assert.are.equal("tim3-lock-manager", messages[2].Target)
            
            local responseData = json.decode(messages[1].Data)
            assert.are.equal("user1", responseData.user)
            assert.are.equal("300", responseData.amount)
            assert.are.equal("300", responseData.totalLocked)
            assert.are.equal("700", responseData.availableBalance)
            
            assert.are.equal(300, Locked["user1"])
        end)
        
        it("should reject lock with insufficient balance", function()
            local messages = captureMessage()
            local msg = createMessage("user1", "Lock", { Amount = "1500" })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(1, #messages)
            assert.are.equal("Lock-Error", messages[1].Action)
            assert.are.equal("Insufficient available balance for lock", messages[1].Data)
        end)
        
        it("should accumulate multiple locks", function()
            Locked["user1"] = 200  -- Already locked
            
            local messages = captureMessage()
            local msg = createMessage("user1", "Lock", { Amount = "300" })
            
            Handlers.evaluate(msg, msg)
            
            local responseData = json.decode(messages[1].Data)
            assert.are.equal("500", responseData.totalLocked)  -- 200 + 300
            assert.are.equal("500", responseData.availableBalance)  -- 1000 - 500
            
            assert.are.equal(500, Locked["user1"])
        end)
    end)
    
    describe("Unlocking Operations", function()
        before_each(function()
            Balances["user1"] = 1000
            Locked["user1"] = 400
        end)
        
        it("should unlock tokens successfully", function()
            local messages = captureMessage()
            local msg = createMessage("tim3-lock-manager", "Unlock", {
                User = "user1",
                Amount = "200"
            })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(2, #messages)  -- Response + Notice
            assert.are.equal("Unlock-Response", messages[1].Action)
            assert.are.equal("Unlock-Notice", messages[2].Action)
            assert.are.equal("user1", messages[2].Target)
            
            local responseData = json.decode(messages[1].Data)
            assert.are.equal("user1", responseData.user)
            assert.are.equal("200", responseData.amount)
            assert.are.equal("200", responseData.remainingLocked)  -- 400 - 200
            assert.are.equal("800", responseData.availableBalance)  -- 1000 - 200
            
            assert.are.equal(200, Locked["user1"])
        end)
        
        it("should reject unlock with insufficient locked balance", function()
            local messages = captureMessage()
            local msg = createMessage("tim3-lock-manager", "Unlock", {
                User = "user1",
                Amount = "500"  -- More than locked (400)
            })
            
            Handlers.evaluate(msg, msg)
            
            assert.are.equal(1, #messages)
            assert.are.equal("Unlock-Error", messages[1].Action)
            assert.are.equal("Insufficient locked balance", messages[1].Data)
        end)
        
        it("should unlock for sender if no user specified", function()
            Balances["tim3-lock-manager"] = 500
            Locked["tim3-lock-manager"] = 300
            
            local messages = captureMessage()
            local msg = createMessage("tim3-lock-manager", "Unlock", { Amount = "100" })
            
            Handlers.evaluate(msg, msg)
            
            local responseData = json.decode(messages[1].Data)
            assert.are.equal("tim3-lock-manager", responseData.user)
            
            assert.are.equal(200, Locked["tim3-lock-manager"])
        end)
    end)
end)
-- TIM3 Integration Test Suite
-- Tests complete user flows across multiple processes

describe("TIM3 Integration Tests", function()
    local json = require("cjson")
    local mock_ao = require("test.mock_ao")
    
    -- Process instances
    local processes = {}
    
    before_each(function()
        -- Reset mock environment
        mock_ao.reset()
        
        -- Clear processes table
        processes = {}
        
        -- Initialize all processes
        processes.mockUsda = {}
        processes.coordinator = {}
        processes.lockManager = {}
        processes.stateManager = {}
        processes.tokenManager = {}
        
        -- Load Mock USDA
        dofile("../mock-usda/src/process.lua")
        processes.mockUsda.handlers = {}
        for _, handler in ipairs(handler_list or {}) do
            table.insert(processes.mockUsda.handlers, handler)
        end
        
        -- Reset handler list for next process
        handler_list = {}
        Handlers = nil
        
        -- Reinitialize Handlers for next process
        Handlers = {
            add = function(name, matcher, handler)
                handler_list = handler_list or {}
                table.insert(handler_list, {
                    name = name,
                    matcher = matcher,
                    handler = handler
                })
            end,
            utils = {
                hasMatchingTag = function(tagName, tagValue)
                    return function(msg)
                        return msg.Tags and msg.Tags[tagName] == tagValue
                    end
                end
            },
            evaluate = function(msg, env)
                for _, h in ipairs(handler_list or {}) do
                    if h.matcher(msg) then
                        h.handler(msg)
                        break
                    end
                end
            end
        }
        
        -- Load Coordinator
        dofile("../coordinator/src/process.lua")
        processes.coordinator.handlers = {}
        for _, handler in ipairs(handler_list or {}) do
            table.insert(processes.coordinator.handlers, handler)
        end
        
        -- Configure processes to know about each other
        Config.mockUsdaProcess = "mock-usda-process"
        Config.stateManagerProcess = "state-manager-process"
        Config.lockManagerProcess = "lock-manager-process"
        Config.tokenManagerProcess = "token-manager-process"
        
        mock_ao.clearSentMessages()
    end)
    
    describe("User Flow: Mint TIM3 with USDA Collateral", function()
        it("should complete full mint flow", function()
            -- Step 1: User wants to mint 100 TIM3 tokens
            local user = "user123"
            local tim3Amount = 100
            local expectedCollateral = 150  -- 100 * 1.5 (150% collateralization)
            
            -- Give user enough USDA balance
            Balances[user] = 1000  -- Mock USDA balance
            
            -- Step 2: Send MintTIM3 request to Coordinator
            local mintRequest = {
                From = user,
                Tags = {
                    Action = "MintTIM3",
                    Amount = tostring(tim3Amount)
                }
            }
            
            -- Execute the coordinator's MintTIM3 handler
            local coordinatorHandlers = processes.coordinator.handlers
            for _, handler in ipairs(coordinatorHandlers) do
                if handler.name == "MintTIM3" and handler.matcher(mintRequest) then
                    handler.handler(mintRequest)
                    break
                end
            end
            
            -- Check that coordinator responded with success
            local messages = mock_ao.getSentMessages()
            assert.is_true(#messages >= 1, "Coordinator should send response")
            
            local response = messages[1]
            assert.are.equal(user, response.Target)
            assert.are.equal("MintTIM3-Response", response.Action)
            
            local responseData = json.decode(response.Data)
            assert.are.equal(tostring(tim3Amount), responseData.tim3Minted)
            assert.are.equal(tostring(expectedCollateral), responseData.collateralLocked)
            
            print("✅ Integration Test 1: Basic mint flow completed")
        end)
    end)
    
    describe("Learning: Message Flow Tracing", function()
        it("should demonstrate message tracing", function()
            local user = "user456"
            Balances[user] = 500
            
            -- Clear messages before test
            mock_ao.clearSentMessages()
            
            local request = {
                From = user,
                Tags = { Action = "MintTIM3", Amount = "50" }
            }
            
            -- Find and execute the MintTIM3 handler
            local coordinatorHandlers = processes.coordinator.handlers
            for _, handler in ipairs(coordinatorHandlers) do
                if handler.name == "MintTIM3" and handler.matcher(request) then
                    print("🎯 Executing handler: " .. handler.name)
                    handler.handler(request)
                    break
                end
            end
            
            -- Trace all messages sent
            local messages = mock_ao.getSentMessages()
            print("📨 Messages sent: " .. #messages)
            
            for i, msg in ipairs(messages) do
                print("  Message " .. i .. ": " .. msg.Action .. " → " .. msg.Target)
                if msg.Data then
                    local data = json.decode(msg.Data)
                    if data.tim3Minted then
                        print("    TIM3 Minted: " .. data.tim3Minted)
                    end
                    if data.collateralLocked then
                        print("    Collateral: " .. data.collateralLocked)
                    end
                end
            end
            
            assert.is_true(#messages > 0, "Should generate messages")
            print("✅ Integration Test 2: Message tracing completed")
        end)
    end)
end)
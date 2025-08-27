-- Debug Integration Issues
-- Let's understand why our processes aren't coordinating

describe("Debug Integration Issues", function()
    local json = require("cjson")
    local mock_ao = require("test.mock_ao")
    
    before_each(function()
        mock_ao.reset()
        
        -- Load just the Coordinator to start
        dofile("../coordinator/src/process.lua")
        mock_ao.clearSentMessages()
    end)
    
    describe("Step 1: Understanding Handler Registration", function()
        it("should show us what handlers are registered", function()
            -- Let's see what handlers we have
            print("\n🔍 DEBUGGING: Available Handlers")
            print("   handler_list exists: " .. tostring(handler_list ~= nil))
            
            if handler_list then
                print("   Number of handlers: " .. #handler_list)
                for i, handler in ipairs(handler_list) do
                    print("   Handler " .. i .. ": " .. handler.name)
                end
            end
            
            -- Test a simple Info request first
            local msg = {
                From = "test-user",
                Tags = { Action = "Info" }
            }
            
            print("\n🧪 Testing Info handler...")
            Handlers.evaluate(msg, msg)
            
            local messages = mock_ao.getSentMessages()
            print("   Messages after Info: " .. #messages)
            
            if #messages > 0 then
                print("   Response action: " .. messages[1].Action)
                local data = json.decode(messages[1].Data)
                print("   Process name: " .. (data.name or "unknown"))
            end
            
            assert.is_true(true, "This always passes - we're just debugging")
        end)
    end)
    
    describe("Step 2: Testing MintTIM3 Handler", function()
        it("should test the MintTIM3 handler step by step", function()
            -- Configure the coordinator
            Config.systemActive = true
            Config.mockUsdaProcess = "mock-usda-123"
            Config.collateralRatio = 1.5
            
            print("\n🔍 DEBUGGING: MintTIM3 Handler")
            print("   System active: " .. tostring(Config.systemActive))
            print("   Mock USDA configured: " .. tostring(Config.mockUsdaProcess ~= nil))
            
            local msg = {
                From = "test-user",
                Tags = {
                    Action = "MintTIM3",
                    Amount = "100"
                }
            }
            
            print("\n🧪 Testing MintTIM3 handler...")
            
            -- Find the MintTIM3 handler specifically
            local handlerFound = false
            if handler_list then
                for i, handler in ipairs(handler_list) do
                    if handler.name == "MintTIM3" then
                        print("   Found MintTIM3 handler at position " .. i)
                        print("   Matcher result: " .. tostring(handler.matcher(msg)))
                        handlerFound = true
                        
                        -- Execute it
                        handler.handler(msg)
                        break
                    end
                end
            end
            
            print("   Handler found: " .. tostring(handlerFound))
            
            local messages = mock_ao.getSentMessages()
            print("   Messages after MintTIM3: " .. #messages)
            
            for i, message in ipairs(messages) do
                print("   Message " .. i .. ": " .. message.Action .. " → " .. message.Target)
            end
            
            assert.is_true(handlerFound, "Should find MintTIM3 handler")
        end)
    end)
end)
-- Mock AO Environment for Testing
-- This simulates the AO runtime environment that our processes expect

local mock_ao = {}
local json = require("cjson")

-- Mock Handlers system
local handlers = {}
local handler_list = {}

Handlers = {
    add = function(name, matcher, handler)
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
        for _, h in ipairs(handler_list) do
            if h.matcher(msg) then
                h.handler(msg)
                break
            end
        end
    end
}

-- Mock ao.send function
local sent_messages = {}

ao = {
    send = function(message)
        table.insert(sent_messages, message)
    end,
    
    -- Helper function to get sent messages for testing
    _getSentMessages = function()
        return sent_messages
    end,
    
    -- Helper function to clear sent messages
    _clearSentMessages = function()
        sent_messages = {}
    end
}

-- Reset function for tests
mock_ao.reset = function()
    handler_list = {}
    sent_messages = {}
    
    -- Set up global json object for process.lua
    _G.json = json
    
    -- Reset global state variables
    Balances = {}
    TotalSupply = 0
    Locked = {}
    Name = nil
    Ticker = nil
    Denomination = nil
    Logo = nil
    ProcessInfo = nil
end

-- Helper function to get captured messages
mock_ao.getSentMessages = function()
    return sent_messages
end

-- Helper function to clear captured messages  
mock_ao.clearSentMessages = function()
    sent_messages = {}
end

return mock_ao
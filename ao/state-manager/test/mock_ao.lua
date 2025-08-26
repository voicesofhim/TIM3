-- Mock AO Environment for TIM3 State Manager Testing
-- Provides the basic AO runtime environment for isolated testing

local mock_ao = {}

-- Mock AO global state
local ao_state = {
    id = "state-manager-process-123",
    sent_messages = {}
}

-- Mock AO functions
ao = {
    id = ao_state.id,
    
    send = function(message)
        table.insert(ao_state.sent_messages, message)
    end
}

-- Mock Handlers system
Handlers = {
    list = {},
    
    add = function(name, matcher, handler)
        table.insert(Handlers.list, {
            name = name,
            matcher = matcher,
            handler = handler
        })
    end,
    
    evaluate = function(msg, env)
        for _, handler_info in ipairs(Handlers.list) do
            if handler_info.matcher(msg) then
                handler_info.handler(msg)
                break
            end
        end
    end,
    
    utils = {
        hasMatchingTag = function(tagName, tagValue)
            return function(msg)
                return msg.Tags and msg.Tags[tagName] == tagValue
            end
        end
    }
}

-- Mock utility functions
function mock_ao.reset()
    ao_state.sent_messages = {}
    Handlers.list = {}
    
    -- Reset global state variables
    Name = nil
    Ticker = nil
    Version = nil
    SystemState = nil
    UserPositions = nil
    RiskMetrics = nil
    Config = nil
end

function mock_ao.clearSentMessages()
    ao_state.sent_messages = {}
end

function mock_ao.getSentMessages()
    return ao_state.sent_messages
end

-- Mock os functions for testing
os = os or {}
os.time = os.time or function()
    return 1640995200  -- Fixed timestamp for consistent tests
end

return mock_ao
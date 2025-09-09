-- Fix Mock USDA Lock Handler Script
-- This script updates the Mock USDA process to correctly use the User tag

-- Target Mock USDA Process
local mockUsdaPID = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"

-- Send the fix as an Eval command
Send({
    Target = mockUsdaPID,
    Action = "Eval",
    Data = [[
-- Update Lock handler to use User tag instead of msg.From
Handlers.add(
    "Lock",
    Handlers.utils.hasMatchingTag("Action", "Lock"),
    function(msg)
        local user = msg.Tags.User or msg.From  -- FIXED: Use User tag if provided
        local amount = tonumber(msg.Tags.Amount or msg.Tags.Quantity)
        local locker = msg.Tags.Locker
        
        -- Validate amount
        if not amount or amount <= 0 then
            ao.send({
                Target = msg.From,
                Action = "Lock-Error",
                Data = "Invalid amount"
            })
            return
        end
        
        -- Check if user has sufficient available balance
        local userBalance = Balances[user] or 0
        local userLocked = Locked[user] or 0
        local availableBalance = userBalance - userLocked
        
        if availableBalance < amount then
            ao.send({
                Target = msg.From,
                Action = "Lock-Error", 
                Data = "Insufficient available balance for lock: user=" .. user .. " available=" .. availableBalance .. " requested=" .. amount
            })
            return
        end
        
        -- Lock the amount
        Locked[user] = userLocked + amount
        
        -- Send success response
        ao.send({
            Target = msg.From,
            Action = "Lock-Response",
            Data = json.encode({
                user = user,
                amount = tostring(amount),
                totalLocked = tostring(Locked[user]),
                availableBalance = tostring(userBalance - Locked[user])
            })
        })
        
        -- Notify the locker process if specified
        if locker then
            ao.send({
                Target = locker,
                Action = "Lock-Confirmed",
                Data = json.encode({
                    user = user,
                    amount = tostring(amount),
                    lockId = msg.Tags.LockId or (user .. "-" .. tostring(os.time())),
                    purpose = msg.Tags.Purpose
                })
            })
        end
    end
)
print("✅ Lock handler updated to use User tag from message")
]]
})

print("📨 Sent fix to Mock USDA process: " .. mockUsdaPID)
print("⏳ Waiting for response...")

-- Check inbox for response
Inbox[#Inbox]
-- Simple fix for Mock USDA - send direct command
Send({
  Target = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8",
  Action = "Eval", 
  Data = "Handlers.add('Lock', Handlers.utils.hasMatchingTag('Action', 'Lock'), function(msg) local user = msg.Tags.User or msg.From; local amount = tonumber(msg.Tags.Amount or msg.Tags.Quantity); local locker = msg.Tags.Locker; if not amount or amount <= 0 then ao.send({Target = msg.From, Action = 'Lock-Error', Data = 'Invalid amount'}); return; end; local userBalance = Balances[user] or 0; local userLocked = Locked[user] or 0; local availableBalance = userBalance - userLocked; if availableBalance < amount then ao.send({Target = msg.From, Action = 'Lock-Error', Data = 'Insufficient available balance for lock'}); return; end; Locked[user] = userLocked + amount; ao.send({Target = msg.From, Action = 'Lock-Response', Data = json.encode({user = user, amount = tostring(amount), totalLocked = tostring(Locked[user]), availableBalance = tostring(userBalance - Locked[user])})}); if locker then ao.send({Target = locker, Action = 'Lock-Confirmed', Data = json.encode({user = user, amount = tostring(amount), lockId = msg.Tags.LockId or (user .. '-' .. tostring(os.time())), purpose = msg.Tags.Purpose})}); end; end); print('Lock handler updated')"
})

print("Fix sent to Mock USDA process")
Inbox[#Inbox]
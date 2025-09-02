json = require('json')
print("=== TIM3 HELPER FUNCTIONS ===")
TIM3_PROCESS = ao.id
USDA_PROCESS = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"
function swapUsdaForTim3(amount) print("Swapping " .. amount .. " USDA for TIM3..."); Send({ Target = USDA_PROCESS, Action = "Transfer", Tags = { Recipient = TIM3_PROCESS, Quantity = amount } }); print("Transfer sent to USDA process. Check balance with: checkMyBalance()") end
function burnTim3ForUsda(amount) print("Burning " .. amount .. " TIM3 for USDA..."); Send({ Target = TIM3_PROCESS, Action = "Transfer", Tags = { Recipient = "burn", Quantity = amount } }); print("Burn request sent. USDA will be returned to your address.") end
function checkMyBalance() Send({Target = TIM3_PROCESS, Action = "Balance"}); os.execute("sleep 1"); local msg = Inbox[#Inbox]; if msg and msg.Action == "Balance-Response" then local data = json.decode(msg.Data); print("Your TIM3 Balance: " .. data.balance); return tonumber(data.balance) else print("Could not retrieve balance"); return 0 end end
function checkUserBalance(user) Send({Target = TIM3_PROCESS, Action = "Balance", Tags = {Target = user}}); os.execute("sleep 1"); local msg = Inbox[#Inbox]; if msg and msg.Action == "Balance-Response" then local data = json.decode(msg.Data); print("Balance for " .. user .. ": " .. data.balance); return tonumber(data.balance) else print("Could not retrieve balance"); return 0 end end
function getContractInfo() Send({Target = TIM3_PROCESS, Action = "Info"}); os.execute("sleep 1"); local msg = Inbox[#Inbox]; if msg and msg.Action == "Info-Response" then local data = json.decode(msg.Data); print("\n=== CONTRACT INFO ==="); print("Name: " .. data.Name); print("Ticker: " .. data.Ticker); print("Total Supply: " .. data.TotalSupply); print("USDA Collateral: " .. data.UsdaCollateral); print("Total Swaps: " .. tostring(data.SwapStats.totalSwaps)); print("Total Burns: " .. tostring(data.SwapStats.totalBurns)); print("Total Volume: " .. tostring(data.SwapStats.totalVolume)); return data else print("Could not retrieve info"); return nil end end
function getStats() Send({Target = TIM3_PROCESS, Action = "Stats"}); os.execute("sleep 1"); local msg = Inbox[#Inbox]; if msg and msg.Action == "Stats-Response" then local data = json.decode(msg.Data); print("\n=== STATISTICS ==="); print("Total Supply: " .. data.TotalSupply); print("USDA Collateral: " .. data.UsdaCollateral); print("Collateral Ratio: " .. tostring(data.CollateralRatio)); print("Swaps: " .. tostring(data.SwapStats.totalSwaps)); print("Burns: " .. tostring(data.SwapStats.totalBurns)); print("Volume: " .. tostring(data.SwapStats.totalVolume)); return data else print("Could not retrieve stats"); return nil end end
function getAllBalances() Send({Target = TIM3_PROCESS, Action = "Balances"}); os.execute("sleep 1"); local msg = Inbox[#Inbox]; if msg and msg.Action == "Balances-Response" then local data = json.decode(msg.Data); print("\n=== ALL BALANCES ==="); for user, balance in pairs(data) do if tonumber(balance) > 0 then print(user .. ": " .. balance) end end; return data else print("Could not retrieve balances"); return nil end end
function transferTim3(recipient, amount) print("Transferring " .. amount .. " TIM3 to " .. recipient); Send({ Target = TIM3_PROCESS, Action = "Transfer", Tags = { Recipient = recipient, Quantity = amount } }); print("Transfer sent. Check with: checkUserBalance('" .. recipient .. "')") end
function checkMyUsdaBalance() Send({Target = USDA_PROCESS, Action = "Balance"}); os.execute("sleep 1"); local msg = Inbox[#Inbox]; if msg and msg.Action == "Balance-Response" then local data = json.decode(msg.Data); print("Your USDA Balance: " .. data.balance); return tonumber(data.balance) else print("Could not retrieve USDA balance"); return 0 end end
function simulateSwap(user, amount) print("\n[SIMULATION] Swapping " .. amount .. " USDA for " .. user); Send({ Target = TIM3_PROCESS, From = USDA_PROCESS, Action = "Credit-Notice", Data = json.encode({ Sender = user, Quantity = amount }) }); print("Simulation sent. Check with: checkUserBalance('" .. user .. "')") end
print("\n=== AVAILABLE COMMANDS ===")
print("swapUsdaForTim3(amount) - Swap your USDA for TIM3")
print("burnTim3ForUsda(amount) - Burn TIM3 to get USDA back")
print("checkMyBalance() - Check your TIM3 balance")
print("checkUserBalance(user) - Check another user's balance")
print("transferTim3(recipient, amount) - Transfer TIM3 to another user")
print("getContractInfo() - Get contract information")
print("getStats() - Get detailed statistics")
print("getAllBalances() - View all user balances")
print("checkMyUsdaBalance() - Check your USDA balance")
print("simulateSwap(user, amount) - Simulate a swap (testing)")
print("\nTIM3 Process: " .. TIM3_PROCESS)
print("USDA Process: " .. USDA_PROCESS)
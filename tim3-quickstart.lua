json = require('json')
print("=== TIM3 QUICK START ===")
print("Initializing TIM3 contract...")
print("")
print("Process ID: " .. ao.id)
print("Name: " .. (Name or "TIM3"))
print("Ticker: " .. (Ticker or "TIM3"))
print("USDA Process: " .. (USDA_PROCESS_ID or "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"))
print("")
function quickTest() print("\n🧪 Running Quick Test..."); Send({Target = ao.id, Action = "Info"}); os.execute("sleep 1"); local infoMsg = Inbox[#Inbox]; if infoMsg and infoMsg.Action == "Info-Response" then print("✅ Info handler working") else print("❌ Info handler failed") end; Send({Target = ao.id, Action = "Stats"}); os.execute("sleep 1"); local statsMsg = Inbox[#Inbox]; if statsMsg and statsMsg.Action == "Stats-Response" then print("✅ Stats handler working") else print("❌ Stats handler failed") end; Send({Target = ao.id, Action = "Balance"}); os.execute("sleep 1"); local balMsg = Inbox[#Inbox]; if balMsg and balMsg.Action == "Balance-Response" then print("✅ Balance handler working") else print("❌ Balance handler failed") end; print("\n✅ Basic handlers operational!"); return true end
function displayCommands() print("\n📋 QUICK COMMANDS:"); print("================"); print("quickTest()        - Run basic handler tests"); print("getInfo()          - Get contract information"); print("getStats()         - Get current statistics"); print("simulateSwap()     - Simulate a USDA swap"); print("showSetup()        - Display setup instructions"); print("") end
function getInfo() Send({Target = ao.id, Action = "Info"}); os.execute("sleep 1"); local msg = Inbox[#Inbox]; if msg and msg.Action == "Info-Response" then local data = json.decode(msg.Data); print("\n📊 CONTRACT INFO:"); print("Name: " .. data.Name); print("Ticker: " .. data.Ticker); print("Supply: " .. data.TotalSupply); print("Collateral: " .. data.UsdaCollateral); return data end end
function getStats() Send({Target = ao.id, Action = "Stats"}); os.execute("sleep 1"); local msg = Inbox[#Inbox]; if msg and msg.Action == "Stats-Response" then local data = json.decode(msg.Data); print("\n📈 STATISTICS:"); print("Total Swaps: " .. tostring(data.SwapStats.totalSwaps)); print("Total Burns: " .. tostring(data.SwapStats.totalBurns)); print("Total Volume: " .. tostring(data.SwapStats.totalVolume)); return data end end
function simulateSwap() local testAmount = "1000000"; local testUser = "test_" .. tostring(os.time()); print("\n🔄 Simulating swap of " .. testAmount .. " USDA"); Send({ Target = ao.id, From = USDA_PROCESS_ID or "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Credit-Notice", Data = json.encode({ Sender = testUser, Quantity = testAmount }) }); os.execute("sleep 1"); print("✅ Swap simulated for user: " .. testUser); Send({Target = ao.id, Action = "Balance", Tags = {Target = testUser}}); os.execute("sleep 1"); local msg = Inbox[#Inbox]; if msg and msg.Action == "Balance-Response" then local data = json.decode(msg.Data); print("✅ User balance: " .. data.balance .. " TIM3") end end
function showSetup() print("\n🚀 SETUP INSTRUCTIONS:"); print("===================="); print("1. Your TIM3 Process ID: " .. ao.id); print("2. Add this to your frontend/wallet"); print("3. To receive TIM3: Transfer USDA to this process"); print("4. To get USDA back: Transfer TIM3 to 'burn'"); print(""); print("📝 For production use:"); print("- Ensure USDA process is: FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8"); print("- Test with small amounts first"); print("- Monitor with: .load tim3-monitor.load"); print("") end
print("✅ TIM3 Contract Ready!")
print("")
displayCommands()
print("Run 'quickTest()' to verify everything is working")
print("Run 'showSetup()' for integration instructions")
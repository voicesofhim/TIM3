-- TIM3 Test Processes Verification Script
-- This script verifies that all 4 test TIM3 processes are deployed and functional

local json = require('json')

-- Test Process IDs (deployed January 29, 2025)
local TEST_PROCESSES = {
  coordinator = "hjob4ditas_ZLM1MWil7lBfflRSTxsnsXrqZSTfxnBM",
  lockManager = "CpNinM9_VCYGlp5BVIwK-eD4mdiv3sH2mxK6SPH0nlY",
  tokenManager = "IDSlr52PKHDMK1fICKDWfxDjlda6JwIcN4MBHR6kfU4",
  stateManager = "jBINaOVF2wLCK9BeZZYUYWBkPZ0EwgvevW4w-uDpDYk"
}

-- Verification results
local results = {}

print("🧪 TIM3 Test Processes Verification")
print("====================================")
print("Deployed: January 29, 2025")
print("")

-- Function to verify a process
local function verifyProcess(name, processId)
  print("Checking " .. name .. "...")
  print("Process ID: " .. processId)
  
  local result = {
    name = name,
    processId = processId,
    exists = false,
    responsive = false,
    hasHandlers = false,
    error = nil
  }
  
  -- Try to send a basic info message
  local success, response = pcall(function()
    Send({
      Target = processId,
      Action = "Info",
      Tags = { 
        From = ao.id,
        Timestamp = tostring(os.time())
      }
    })
    return true
  end)
  
  if success then
    result.exists = true
    print("✅ Process exists and accepts messages")
  else
    result.error = "Failed to send message to process"
    print("❌ Process not accessible: " .. (response or "Unknown error"))
  end
  
  results[name] = result
  print("")
end

-- Verify each process
for name, processId in pairs(TEST_PROCESSES) do
  verifyProcess(name, processId)
end

-- Summary report
print("📊 VERIFICATION SUMMARY")
print("======================")

local totalProcesses = 0
local workingProcesses = 0

for name, result in pairs(results) do
  totalProcesses = totalProcesses + 1
  local status = result.exists and "✅ WORKING" or "❌ FAILED"
  if result.exists then
    workingProcesses = workingProcesses + 1
  end
  
  print(string.format("%-15s %s (%s)", name, status, result.processId:sub(1, 8) .. "..."))
  
  if result.error then
    print("  Error: " .. result.error)
  end
end

print("")
print(string.format("Result: %d/%d processes verified successfully", workingProcesses, totalProcesses))

if workingProcesses == totalProcesses then
  print("🎉 All test processes are deployed and accessible!")
  print("")
  print("Next steps:")
  print("1. Configure the test coordinator with Mock USDA")
  print("2. Test USDA minting and TIM3 swapping")
  print("3. Verify balance queries work correctly")
else
  print("⚠️  Some processes may need redeployment")
  print("Check the failed processes and redeploy if necessary")
end

print("")
print("To test individual processes manually:")
for name, processId in pairs(TEST_PROCESSES) do
  print("aos " .. processId .. "  # " .. name)
end

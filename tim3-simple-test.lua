-- Simple test script for TIM3
json = require('json')

print("Testing TIM3 Contract...")
print("Process ID: " .. ao.id)

-- Test 1: Info
Send({Target = ao.id, Action = "Info"})
print("✓ Info request sent")

-- Test 2: Balance
Send({Target = ao.id, Action = "Balance"})
print("✓ Balance request sent")

-- Test 3: Stats
Send({Target = ao.id, Action = "Stats"})
print("✓ Stats request sent")

print("\nAll tests sent! Check Inbox for responses.")
print("Run: Inbox[#Inbox] to see last message")
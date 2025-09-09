-- Update max mint amount in running Coordinator process
Config.maxMintAmount = 1000000000000  -- 1 billion base units = 1000 USDA

print("✅ Updated max mint amount to 1 billion base units (1000 USDA)")
print("   Min: " .. Config.minMintAmount .. " base units (0.000001 USDA)")
print("   Max: " .. Config.maxMintAmount .. " base units (1000 USDA)")
print("")
print("You can now mint up to 1000 USDA worth of TIM3!")
print("Example: mintTIM3(1000) will mint 1000 USDA worth of TIM3")
TIM3 Production Notes 

🚀 PRODUCTION SETUP COMPLETE!

  Deploy Now - 2 Simple Commands:

  1️⃣ In Terminal:
  cd /Users/ryanjames/Documents/CRØSS/W3B/S3ARCH/apps/tim3
  aos tim3-prod --load tim3-production.lua

  2️⃣ In AOS:
  .load tim3-production-helpers.lua
  quickTest()

  Then Test Your Admin Mint:

  adminTestMint(ao.id, "1000000")
  viewBalance()

  ✅ What's Ready:

  1. tim3-production.lua - Production contract with:
    - Full USDA integration
    - Admin testing functions
    - Security validations
    - Health monitoring
    - Statistics tracking
  2. tim3-production-helpers.lua - Helper functions:
    - adminTestMint() - Test minting (you're admin)
    - viewBalance() - Check balances
    - burnTim3() - Burn for USDA
    - quickTest() - Verify everything works
  3. PRODUCTION-INTEGRATION.md - Complete docs for:
    - Wallet integration
    - Frontend setup
    - API endpoints
    - Error handling
  4. PRODUCTION-DEPLOY.md - Step-by-step deployment guide

  🎯 Your Admin Powers:

  Since you're deploying, you're the admin and can:
  - Test mint TIM3 without needing real USDA
  - View detailed statistics
  - Monitor system health
  - Test all functions before going live
  ---
  4uwTbWLfYdYIden0mkcR8VPaXW0Srhkbrn6Al-8qSag

  ---
  💰 MINTING TIM3 WITH REAL USDA

  Method 1: From AOS Terminal (If you have USDA in your AOS 
  wallet)

  -- Send USDA to your TIM3 process
  Send({
      Target = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8",  --
   USDA Process
      Action = "Transfer",
      Recipient = "YOUR_TIM3_PROCESS_ID",  -- Replace with your 
  TIM3 process ID
      Quantity = "1000000"  -- 1 USDA (6 decimals)
  })

  The USDA process will:
  1. Transfer the USDA from your wallet
  2. Send a Credit-Notice to your TIM3 process
  3. TIM3 automatically mints 1:1 tokens to your address

  Method 2: From a Web Wallet (ArConnect, etc.)

  If you have USDA in ArConnect or another web wallet:

  // In browser console or dApp
  await window.arweaveWallet.dispatch({
      process: "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", // 
  USDA
      action: "Transfer",
      tags: [
          { name: "Recipient", value: "YOUR_TIM3_PROCESS_ID" },
          { name: "Quantity", value: "1000000" } // 1 USDA
      ]
  });

  Method 3: Using AO Connect in Code

  import { message, createDataItemSigner } from
  '@permaweb/aoconnect';

  async function swapUsdaForTim3(amount) {
      const result = await message({
          process: "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8",
   // USDA
          signer: createDataItemSigner(wallet),
          tags: [
              { name: "Action", value: "Transfer" },
              { name: "Recipient", value: "YOUR_TIM3_PROCESS_ID"
  },
              { name: "Quantity", value: amount }
          ]
      });
      return result;
  }

  // Swap 1 USDA for 1 TIM3
  swapUsdaForTim3("1000000");

  🔍 First, Check Your USDA Balance

  Before you can swap, make sure you have USDA:

  -- In AOS, check your USDA balance
  Send({Target = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Balance"})

  -- Wait 1 second, then check response
  Inbox[#Inbox].Data

  🎯 Complete Example in AOS

  -- Step 1: Check your USDA balance
  Send({Target = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Balance"})

  -- Step 2: Transfer USDA to TIM3 (replace with your TIM3 
  process ID)
  Send({Target = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Transfer", Recipient = "8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU", Quantity = "1000000"})

  Send({Target = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Transfer", Recipient = "2fSKy8T_MWCk4RRBtZwGL8TECg9wDCuQD90Y2IeyRQg", Quantity = "1000000"})

  -- Step 3: Check your TIM3 balance
  checkBalance()

  ⚠️ Important Notes

  1. You need real USDA first - The production USDA process only
  accepts real transfers
  2. The swap is automatic - Once USDA is received, TIM3 mints
  instantly
  3. It's irreversible - Once swapped, you can only get USDA back
  by burning TIM3

  🚫 If You Don't Have USDA

  You can:
  1. Get USDA from someone who has it
  2. Buy USDA on a DEX that supports AO tokens
  3. Use admin test mint for testing (doesn't require real USDA):
  adminTestMint(ao.id, "1000000")

  The admin test mint is perfect for testing your integration
  without spending real USDA!

  USDA: FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8
  TIM3: 8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU
  wallet process: 4uwTbWLfYdYIden0mkcR8VPaXW0Srhkbrn6Al-8qSag

  -- Check your TIM3 contract info
  Send({Target = "8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU", Action = "Info"})

    -- Check your TIM3 balance (on your TIM3 contract)
    Send({Target = "8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU", Action = "Balance"})
  
    -- Swap USDA for TIM3 (send USDA to your TIM3 contract)
    Send({Target = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Transfer", Recipient = "8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU", Quantity = "1000000000000"})

    Send({Target ="8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU", Action= "Info"})

    Send({Target ="FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Balance"})

    Send({Target = "8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU", Action = "Balance", Tags = {Target = ao.id}})

    Send({Target = "8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU", Action = "Stats"})

    Send({Target = "8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU", Action = "Admin-TestMint",
        Tags = {
            User =
    "4uwTbWLfYdYIden0mkcR8VPaXW0Srhkbrn6Al-8qSag",  -- 
    Your address
            Amount = "1000000000000"  -- 1 TIM3
        }
    })

    -- Check USDA balance in wallet process
    Send({Target = "4uwTbWLfYdYIden0mkcR8VPaXW0Srhkbrn6Al-8qSag", Action = "Balance", Tags = {Target = "2fSKy8T_MWCk4RRBtZwGL8TECg9wDCuQD90Y2IeyRQg"}})


Handlers.add("USDA-Credit-Notice", Handlers.utils.hasMatchingTag("Action", "Credit-Notice"), function(msg) if msg.From ~= "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8" then print("Rejected Credit-Notice from: " .. msg.From) return end local creditData = json.decode(msg.Data or "{}") local user = creditData.Sender or creditData.sender or creditData.from local amount = tonumber(creditData.Quantity or creditData.quantity or "0") if not user or amount <= 0 then print("Invalid credit - user: " .. tostring(user) .. ", amount: " .. tostring(amount)) return end Balances = Balances or {} Balances[user] = (Balances[user] or 0) + amount TotalSupply = (TotalSupply or 0) + amount UsdaCollateral = (UsdaCollateral or 0) + amount print("🎉 MINTED " .. amount .. " TIM3 for " .. user) ao.send({Target = user, Action = "Swap-Success", Data = json.encode({tim3Minted = tostring(amount), newBalance = tostring(Balances[user])})}) end)

Send({Target = ao.id, From = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Credit-Notice", Data = json.encode({Sender = ao.id, Quantity = "1000000000000"})})

Send({Target = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Transfer", Recipient = "8PL5u3vvY_o9hJ9cqzowb1BLHOweT2SEcEIN6JfhVuU", Quantity = "1000000000000"})

print("Raw Balances:") ; for user, balance in pairs(Balances or {}) do; print(user .. ": " .. tostring(balance)) end

Handlers.add("USDA-Credit-Notice-Safe", Handlers.utils.hasMatchingTag("Action", "Credit-Notice"), function(msg) if msg.From ~= "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8" then print("Rejected Credit-Notice from: " .. msg.From) return end local user, amount local success, creditData = pcall(json.decode, msg.Data or "{}") if success and creditData then user = creditData.Sender or creditData.sender or creditData.from amount = tonumber(creditData.Quantity or creditData.quantity or "0") end if not user or not amount then user = msg.Tags.Sender or msg.Tags.From amount = tonumber(msg.Tags.Quantity or "0") end print("Processing Credit-Notice - User: " .. tostring(user) .. ", Amount: " .. tostring(amount)) if not user or amount <= 0 then print("Invalid credit after fallback check") return end Balances = Balances or {} TotalSupply = TotalSupply or 0 UsdaCollateral = UsdaCollateral or 0 Balances[user] = (Balances[user] or 0) + amount TotalSupply = TotalSupply + amount UsdaCollateral = UsdaCollateral + amount print("🎉 MINTED " .. amount .. " TIM3 for " .. user) print("New balance: " .. Balances[user]) print("Total supply: " .. TotalSupply) end)

Handlers.add("USDA-Credit-Notice-Final", Handlers.utils.hasMatchingTag("Action", "Credit-Notice"), function(msg) if msg.From ~= "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8" then print("Rejected Credit-Notice from: " .. msg.From) return end local user, amount local success, creditData = pcall(json.decode, msg.Data or "{}") if success and creditData then user = creditData.Sender or creditData.sender or creditData.from amount = tonumber(creditData.Quantity or creditData.quantity or "0") end if not user or not amount or amount <= 0 then user = msg.Tags.Sender or msg.Tags.From or msg.From amount = tonumber(msg.Tags.Quantity or "0") end print("🔍 Processing: User=" .. tostring(user) .. ", Amount=" .. tostring(amount)) if not user or amount <= 0 then print("❌ Invalid data after all checks") return end Balances = Balances or {} TotalSupply = TotalSupply or 0 UsdaCollateral = UsdaCollateral or 0 Balances[user] = (Balances[user] or 0) + amount TotalSupply = TotalSupply + amount UsdaCollateral = UsdaCollateral + amount print("🎉 SUCCESS! MINTED " .. amount .. " TIM3 for " .. user) print("📊 New balance: " .. Balances[user]) print("📊 Total supply: " .. TotalSupply) end)

Handlers.add("USDA-Credit-Notice-Final",
      Handlers.utils.hasMatchingTag("Action",
  "Credit-Notice"),
      function(msg)
          if msg.From ~=
  "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8" then
              print("Rejected Credit-Notice from: " ..
   msg.From)
              return
          end

          local user, amount

          -- Safe JSON parsing with pcall (the fix 
  from our docs!)
          local success, creditData =
  pcall(json.decode, msg.Data or "{}")
          if success and creditData then
              user = creditData.Sender or
  creditData.sender or creditData.from
              amount = tonumber(creditData.Quantity or
   creditData.quantity or "0")
          end

          -- Fallback to Tags if JSON failed
          if not user or not amount or amount <= 0
  then
              user = msg.Tags.Sender or msg.Tags.From
  or msg.From
              amount = tonumber(msg.Tags.Quantity or
  "0")
          end

          print("🔍 Processing: User=" ..
  tostring(user) .. ", Amount=" .. tostring(amount))

          if not user or amount <= 0 then
              print("❌ Invalid data after all 
  checks")
              return
          end

          -- Initialize if needed
          Balances = Balances or {}
          TotalSupply = TotalSupply or 0
          UsdaCollateral = UsdaCollateral or 0

          -- MINT TIM3!
          Balances[user] = (Balances[user] or 0) +
  amount
          TotalSupply = TotalSupply + amount
          UsdaCollateral = UsdaCollateral + amount

          print("🎉 SUCCESS! MINTED " .. amount .. " 
  TIM3 for " .. user)
          print("📊 New balance: " .. Balances[user])
          print("📊 Total supply: " .. TotalSupply)
      end
  )

  Then test with another USDA transfer:

  Send({
      Target =
  "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8",
      Action = "Transfer",
      Recipient = ao.id,
      Quantity = "1000000000000"
  })

Send({Target = "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8", Action = "Transfer", Recipient = ao.id, Quantity = "1000000000000"})

for i = #Handlers.list, 1, -1 do if string.match(Handlers.list[i].name, "Credit") then table.remove(Handlers.list, i) end end

Handlers.add("Credit-Notice", Handlers.utils.hasMatchingTag("Action", "Credit-Notice"), function(msg) if msg.From ~= "FBt9A5GA_KXMMSxA2DJ0xZbAq8sLLU2ak-YJe9zDvg8" then return end local user = msg.Tags.Sender local amount = tonumber(msg.Tags.Quantity) if user and amount and amount > 0 then Balances = Balances or {} TotalSupply = TotalSupply or 0 Balances[user] = (Balances[user] or 0) + amount TotalSupply = TotalSupply + amount print("✅ MINTED " .. amount .. " TIM3 for " .. user) end end)
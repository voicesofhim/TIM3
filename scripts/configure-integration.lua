-- TIM3 System Integration Configuration Script
-- This script configures all processes with their live AOS Process IDs
-- Run this in each AOS process session to establish inter-process communication

-- Live Process IDs (deployed to AOS)
PROCESS_IDS = {
    MOCK_USDA = "u8DzisIMWnrfGa6nlQvf1J79kYkv8uWjDeXZ489UMXQ",
    COORDINATOR = "uNhmrUij4u6ZZr_39BDI5E2G2afkit8oC7q4vAtRskM", -- Updated to new Orchestrator
    STATE_MANAGER = "K2FjwiTmncglx0pISNMft5-SngxW-HUjs9sctzmXtU4",
    LOCK_MANAGER = "MWxRVsCDoSzQ0MhG4_BWkYs0fhcULB-OO3f2t1RlBAs",
    TOKEN_MANAGER = "DoXrn6DGZZuDMkyun4rmXh7k8BY8pVxFpr3MnBWYJFw" -- Updated to correct Token Manager
}

-- Configuration Functions
function configureCoordinator()
    print("=== Configuring TIM3 Coordinator ===")
    
    -- Configure Mock USDA Process
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "Configure",
        Tags = {
            ConfigType = "MockUsdaProcess",
            Value = PROCESS_IDS.MOCK_USDA
        }
    })
    
    -- Configure State Manager Process
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "Configure", 
        Tags = {
            ConfigType = "StateManagerProcess",
            Value = PROCESS_IDS.STATE_MANAGER
        }
    })
    
    -- Configure Lock Manager Process
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "Configure",
        Tags = {
            ConfigType = "LockManagerProcess", 
            Value = PROCESS_IDS.LOCK_MANAGER
        }
    })
    
    -- Configure Token Manager Process
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "Configure",
        Tags = {
            ConfigType = "TokenManagerProcess",
            Value = PROCESS_IDS.TOKEN_MANAGER
        }
    })
    
    print("Coordinator configuration sent. Check Inbox for responses.")
end

function configureStateManager()
    print("=== Configuring State Manager ===")
    
    Send({
        Target = PROCESS_IDS.STATE_MANAGER,
        Action = "Configure",
        Tags = {
            ConfigType = "CoordinatorProcess",
            Value = PROCESS_IDS.COORDINATOR
        }
    })
    
    Send({
        Target = PROCESS_IDS.STATE_MANAGER,
        Action = "Configure",
        Tags = {
            ConfigType = "LockManagerProcess",
            Value = PROCESS_IDS.LOCK_MANAGER
        }
    })
    
    Send({
        Target = PROCESS_IDS.STATE_MANAGER,
        Action = "Configure",
        Tags = {
            ConfigType = "TokenManagerProcess", 
            Value = PROCESS_IDS.TOKEN_MANAGER
        }
    })
    
    print("State Manager configuration sent. Check Inbox for responses.")
end

function configureLockManager()
    print("=== Configuring Lock Manager ===")
    
    Send({
        Target = PROCESS_IDS.LOCK_MANAGER,
        Action = "Configure",
        Tags = {
            ConfigType = "CoordinatorProcess",
            Value = PROCESS_IDS.COORDINATOR
        }
    })
    
    Send({
        Target = PROCESS_IDS.LOCK_MANAGER,
        Action = "Configure",
        Tags = {
            ConfigType = "StateManagerProcess",
            Value = PROCESS_IDS.STATE_MANAGER
        }
    })
    
    Send({
        Target = PROCESS_IDS.LOCK_MANAGER,
        Action = "Configure",
        Tags = {
            ConfigType = "MockUsdaProcess",
            Value = PROCESS_IDS.MOCK_USDA
        }
    })
    
    print("Lock Manager configuration sent. Check Inbox for responses.")
end

function configureTokenManager()
    print("=== Configuring Token Manager ===")
    
    Send({
        Target = PROCESS_IDS.TOKEN_MANAGER,
        Action = "Configure",
        Tags = {
            ConfigType = "CoordinatorProcess",
            Value = PROCESS_IDS.COORDINATOR
        }
    })
    
    Send({
        Target = PROCESS_IDS.TOKEN_MANAGER,
        Action = "Configure",
        Tags = {
            ConfigType = "StateManagerProcess",
            Value = PROCESS_IDS.STATE_MANAGER
        }
    })
    
    Send({
        Target = PROCESS_IDS.TOKEN_MANAGER,
        Action = "Configure",
        Tags = {
            ConfigType = "LockManagerProcess",
            Value = PROCESS_IDS.LOCK_MANAGER
        }
    })
    
    print("Token Manager configuration sent. Check Inbox for responses.")
end

function testSystemCommunication()
    print("=== Testing System Communication ===")
    
    -- Test Info requests to all processes
    local processes = {
        {"Mock USDA", PROCESS_IDS.MOCK_USDA},
        {"Coordinator", PROCESS_IDS.COORDINATOR},
        {"State Manager", PROCESS_IDS.STATE_MANAGER},
        {"Lock Manager", PROCESS_IDS.LOCK_MANAGER},
        {"Token Manager", PROCESS_IDS.TOKEN_MANAGER}
    }
    
    for _, process in ipairs(processes) do
        local name, id = process[1], process[2]
        print("Testing " .. name .. " (" .. id .. ")...")
        Send({
            Target = id,
            Action = "Info"
        })
    end
    
    print("Info requests sent to all processes. Check Inbox for responses.")
end

function checkSystemHealth()
    print("=== Checking System Health ===")
    
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "SystemHealth"
    })
    
    Send({
        Target = PROCESS_IDS.STATE_MANAGER,
        Action = "SystemHealth" 
    })
    
    print("System health checks sent. Check Inbox for responses.")
end

-- Main Configuration Function
function configureAllProcesses()
    print("========================================")
    print("TIM3 SYSTEM INTEGRATION CONFIGURATION")
    print("========================================")
    print("")
    
    configureCoordinator()
    print("")
    
    configureStateManager()
    print("")
    
    configureLockManager()
    print("")
    
    configureTokenManager()
    print("")
    
    testSystemCommunication()
    print("")
    
    print("========================================")
    print("CONFIGURATION COMPLETE!")
    print("========================================")
    print("")
    print("Next steps:")
    print("1. Check Inbox responses: Inbox[#Inbox]")
    print("2. Run system health check: checkSystemHealth()")
    print("3. Test minting flow: testMintingFlow()")
    print("")
end

-- Test Functions
function testMintingFlow()
    print("=== Testing TIM3 Minting Flow ===")
    print("This will test: USDA Lock → TIM3 Mint")
    
    -- First, ensure user has USDA balance
    Send({
        Target = PROCESS_IDS.MOCK_USDA,
        Action = "Balance"
    })
    
    -- Test mint 10 TIM3 (requires 10 USDA collateral)
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "MintTIM3",
        Tags = {
            Amount = "10"
        }
    })
    
    print("Minting test initiated. Monitor Inbox for progress updates.")
end

function testRedemptionFlow()
    print("=== Testing TIM3 Redemption Flow ===")
    print("This will test: TIM3 Burn → USDA Unlock")
    
    -- Test burn 5 TIM3 (should unlock 5 USDA)
    Send({
        Target = PROCESS_IDS.COORDINATOR,
        Action = "BurnTIM3",
        Tags = {
            Amount = "5"
        }
    })
    
    print("Redemption test initiated. Monitor Inbox for progress updates.")
end

-- Export functions for global use
configureAllProcesses = configureAllProcesses
configureCoordinator = configureCoordinator
configureStateManager = configureStateManager
configureLockManager = configureLockManager
configureTokenManager = configureTokenManager
testSystemCommunication = testSystemCommunication
checkSystemHealth = checkSystemHealth
testMintingFlow = testMintingFlow
testRedemptionFlow = testRedemptionFlow

-- Display usage instructions
print("========================================")
print("TIM3 INTEGRATION SCRIPT LOADED")
print("========================================")
print("")
print("Available functions:")
print("• configureAllProcesses() - Configure all processes")
print("• testSystemCommunication() - Test inter-process communication")
print("• checkSystemHealth() - Check system health")
print("• testMintingFlow() - Test USDA → TIM3 minting")
print("• testRedemptionFlow() - Test TIM3 → USDA redemption")
print("")
print("Quick start: configureAllProcesses()")
print("========================================")

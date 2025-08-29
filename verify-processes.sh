#!/bin/bash

# TIM3 Test Processes Verification Script
# This script checks if all 4 test processes are accessible

echo "🧪 TIM3 Test Processes Verification"
echo "===================================="
echo "Deployed: January 29, 2025"
echo ""

# Test Process IDs
COORDINATOR="hjob4ditas_ZLM1MWil7lBfflRSTxsnsXrqZSTfxnBM"
LOCK_MANAGER="CpNinM9_VCYGlp5BVIwK-eD4mdiv3sH2mxK6SPH0nlY"
TOKEN_MANAGER="IDSlr52PKHDMK1fICKDWfxDjlda6JwIcN4MBHR6kfU4"
STATE_MANAGER="jBINaOVF2wLCK9BeZZYUYWBkPZ0EwgvevW4w-uDpDYk"

# Function to check if a process exists
check_process() {
    local name=$1
    local process_id=$2
    
    echo "Checking $name..."
    echo "Process ID: $process_id"
    
    # Try to connect to the process (this will fail if process doesn't exist)
    if timeout 10s aos $process_id -c "print('Process accessible'); os.exit()" 2>/dev/null | grep -q "Process accessible"; then
        echo "✅ $name is accessible"
        return 0
    else
        echo "❌ $name is not accessible or doesn't exist"
        return 1
    fi
    echo ""
}

# Check each process
working=0
total=4

echo "Checking individual processes..."
echo ""

if check_process "Coordinator" $COORDINATOR; then ((working++)); fi
if check_process "Lock Manager" $LOCK_MANAGER; then ((working++)); fi  
if check_process "Token Manager" $TOKEN_MANAGER; then ((working++)); fi
if check_process "State Manager" $STATE_MANAGER; then ((working++)); fi

echo ""
echo "📊 VERIFICATION SUMMARY"
echo "======================"
echo "Result: $working/$total processes verified successfully"

if [ $working -eq $total ]; then
    echo "🎉 All test processes are deployed and accessible!"
    echo ""
    echo "To connect to individual processes:"
    echo "aos $COORDINATOR  # Coordinator"
    echo "aos $LOCK_MANAGER  # Lock Manager" 
    echo "aos $TOKEN_MANAGER  # Token Manager"
    echo "aos $STATE_MANAGER  # State Manager"
else
    echo "⚠️  Some processes may need redeployment"
    echo "Check the failed processes and redeploy using the .load files"
fi

echo ""
echo "To run the detailed Lua verification:"
echo "aos --load verify-test-processes.lua"

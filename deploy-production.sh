#!/bin/bash

# TIM3 Production Deployment Script
# This script deploys the TIM3 contract to AOS

echo "======================================"
echo "     TIM3 PRODUCTION DEPLOYMENT      "
echo "======================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "tim3-swap-contract.lua" ]; then
    echo -e "${RED}Error: tim3-swap-contract.lua not found!${NC}"
    echo "Please run this script from the /apps/tim3 directory"
    exit 1
fi

echo -e "${YELLOW}📁 Current directory:${NC} $(pwd)"
echo ""

# Display files
echo -e "${GREEN}✅ Found deployment files:${NC}"
ls -la tim3-*.lua
echo ""

# Deployment options
echo -e "${YELLOW}Select deployment option:${NC}"
echo "1) Deploy NEW TIM3 process"
echo "2) Connect to EXISTING TIM3 process"
echo "3) Run tests only"
echo ""
read -p "Enter option (1-3): " option

case $option in
    1)
        echo ""
        echo -e "${GREEN}🚀 Deploying new TIM3 process...${NC}"
        echo ""
        echo "Command to run:"
        echo -e "${YELLOW}aos tim3-production --load tim3-swap-contract.lua${NC}"
        echo ""
        echo "After AOS starts, run:"
        echo -e "${YELLOW}.load tim3-quickstart.lua${NC}"
        echo -e "${YELLOW}quickTest()${NC}"
        echo ""
        echo "Press Enter to continue..."
        read
        aos tim3-production --load tim3-swap-contract.lua
        ;;
    2)
        echo ""
        read -p "Enter existing TIM3 process name: " process_name
        echo ""
        echo -e "${GREEN}📡 Connecting to process: $process_name${NC}"
        echo ""
        echo "After connection, load helpers with:"
        echo -e "${YELLOW}.load tim3-helpers.lua${NC}"
        echo -e "${YELLOW}.load tim3-monitor.lua${NC}"
        echo ""
        echo "Press Enter to continue..."
        read
        aos $process_name
        ;;
    3)
        echo ""
        echo -e "${GREEN}🧪 Starting test environment...${NC}"
        echo ""
        echo "Commands to run in AOS:"
        echo -e "${YELLOW}.load tim3-swap-contract.lua${NC}"
        echo -e "${YELLOW}.load tim3-test-suite.lua${NC}"
        echo -e "${YELLOW}runAllTests()${NC}"
        echo ""
        echo "Press Enter to continue..."
        read
        aos tim3-test --load tim3-swap-contract.lua
        ;;
    *)
        echo -e "${RED}Invalid option${NC}"
        exit 1
        ;;
esac
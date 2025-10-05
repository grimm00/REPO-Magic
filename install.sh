#!/bin/bash

# REPO-Magic Installation Script
# This script sets up the mod management tools for your friends

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "=========================================="
echo "  REPO-Magic Installation Script"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "modrollback.sh" ] || [ ! -f "modinstaller.sh" ]; then
    echo -e "${RED}❌ Error: Please run this script from the REPO-Magic directory${NC}"
    echo "   Make sure you're in the folder containing modrollback.sh and modinstaller.sh"
    exit 1
fi

# Check dependencies
echo -e "${BLUE}Step 1: Checking dependencies...${NC}"
if ! bash check_dependencies.sh; then
    echo ""
    echo -e "${RED}❌ Please install the missing dependencies and run this script again.${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Setting up permissions...${NC}"

# Set executable permissions on all scripts
shopt -s nullglob
chmod +x *.sh 2>/dev/null || true
chmod +x lib/*.sh 2>/dev/null || true
chmod +x scripts/standalone/*.sh 2>/dev/null || true
shopt -u nullglob

echo "✅ Set executable permissions on all scripts"

echo ""
echo -e "${BLUE}Step 3: Testing basic functionality...${NC}"

# Test basic functionality
echo "Testing modrollback.sh..."
if ./modrollback.sh --help >/dev/null 2>&1; then
    echo "✅ modrollback.sh is working"
else
    echo -e "${YELLOW}⚠️  modrollback.sh test failed (this might be normal if no mods are installed)${NC}"
fi

echo "Testing modinstaller.sh..."
if ./modinstaller.sh --help >/dev/null 2>&1; then
    echo "✅ modinstaller.sh is working"
else
    echo -e "${YELLOW}⚠️  modinstaller.sh test failed${NC}"
fi

echo ""
echo "=========================================="
echo -e "🎉 ${GREEN}Installation Complete!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Quick Start Guide:${NC}"
echo "----------------------"
echo ""
echo "1. List your mods:"
echo "   ${GREEN}./modrollback.sh --profile Default${NC}"
echo ""
echo "2. Install a mod from Thunderstore:"
echo "   ${GREEN}./modinstaller.sh <thunderstore-url>${NC}"
echo ""
echo "3. Rollback a mod:"
echo "   ${GREEN}./modrollback.sh --profile Default${NC}"
echo "   (Then select the mod and version to rollback)"
echo ""
echo "4. Use a different profile:"
echo "   ${GREEN}./modrollback.sh --profile Friends${NC}"
echo ""
echo -e "${BLUE}Standalone Scripts:${NC}"
echo "----------------------"
echo "• ${GREEN}./scripts/standalone/modrollback-simple.sh${NC} - Single-file rollback"
echo "• ${GREEN}./scripts/standalone/modinstaller-simple.sh${NC} - Single-file installer"
echo "• ${GREEN}./scripts/standalone/clean_mods_yml.sh${NC} - YAML cleanup tool"
echo ""
echo -e "${BLUE}Documentation:${NC}"
echo "----------------------"
echo "• ${GREEN}README.md${NC} - Main documentation"
echo "• ${GREEN}docs/guides/${NC} - User guides"
echo "• ${GREEN}docs/troubleshooting/${NC} - Troubleshooting help"
echo ""
echo -e "${YELLOW}Note:${NC} Make sure you have r2modmanPlus installed and configured!"
echo ""
echo -e "${GREEN}Happy modding! 🎮${NC}"

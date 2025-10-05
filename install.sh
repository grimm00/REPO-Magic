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

# Check and install dependencies
echo -e "${BLUE}Step 1: Checking and installing dependencies...${NC}"

# Function to detect package manager and install dependencies
install_dependencies() {
    local missing_deps=()
    
    # Check which dependencies are missing
    for dep in "jq" "curl" "openssl" "git" "python3"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        echo "✅ All required dependencies are already installed"
        return 0
    fi
    
    echo -e "${YELLOW}Missing dependencies: ${missing_deps[*]}${NC}"
    echo ""
    
    # Detect package manager and install
    if command -v pacman >/dev/null 2>&1; then
        echo -e "${BLUE}Detected Arch Linux/SteamOS (pacman)${NC}"
        echo "Installing missing dependencies..."
        
        # Map package names for Arch
        local arch_packages=()
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                "python3") arch_packages+=("python") ;;
                *) arch_packages+=("$dep") ;;
            esac
        done
        
        if sudo pacman -S --noconfirm "${arch_packages[@]}"; then
            echo "✅ Dependencies installed successfully"
            return 0
        else
            echo -e "${RED}❌ Failed to install dependencies with pacman${NC}"
            return 1
        fi
        
    elif command -v apt >/dev/null 2>&1; then
        echo -e "${BLUE}Detected Ubuntu/Debian (apt)${NC}"
        echo "Installing missing dependencies..."
        
        if sudo apt update && sudo apt install -y "${missing_deps[@]}"; then
            echo "✅ Dependencies installed successfully"
            return 0
        else
            echo -e "${RED}❌ Failed to install dependencies with apt${NC}"
            return 1
        fi
        
    elif command -v dnf >/dev/null 2>&1; then
        echo -e "${BLUE}Detected Fedora/RHEL (dnf)${NC}"
        echo "Installing missing dependencies..."
        
        if sudo dnf install -y "${missing_deps[@]}"; then
            echo "✅ Dependencies installed successfully"
            return 0
        else
            echo -e "${RED}❌ Failed to install dependencies with dnf${NC}"
            return 1
        fi
        
    else
        echo -e "${RED}❌ Unsupported package manager${NC}"
        echo "Please install the missing dependencies manually:"
        for dep in "${missing_deps[@]}"; do
            echo "  • $dep"
        done
        return 1
    fi
}

# Try to install dependencies automatically
if ! install_dependencies; then
    echo ""
    echo -e "${YELLOW}Automatic installation failed. Running dependency check...${NC}"
    if ! ./check_dependencies.sh; then
        echo ""
        echo -e "${RED}❌ Please install the missing dependencies manually and run this script again.${NC}"
        exit 1
    fi
fi

# Final dependency verification
echo ""
echo -e "${BLUE}Verifying all dependencies are installed...${NC}"
if ! ./check_dependencies.sh; then
    echo -e "${RED}❌ Some dependencies are still missing after installation attempt${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Setting up permissions...${NC}"

# Set executable permissions on all scripts
chmod +x *.sh
chmod +x lib/*.sh
chmod +x scripts/standalone/*.sh

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

#!/bin/bash

# REPO-Magic Installation Script
# This script sets up the mod management tools for your friends

# Colors for output (with fallback for terminals that don't support colors)
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    NC=''
fi

echo "=========================================="
echo "  REPO-Magic Installation Script"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "modrollback.sh" ] || [ ! -f "modinstaller.sh" ]; then
    echo -e "${RED}[ERROR] Error: Please run this script from the REPO-Magic directory${NC}"
    echo "   Make sure you're in the folder containing modrollback.sh and modinstaller.sh"
    exit 1
fi

# Check and install dependencies
echo -e "${BLUE}Step 1: Checking and installing dependencies...${NC}"

# Function to re-enable SteamOS read-only mode
reenable_readonly() {
    if [ -f "/etc/steamos-release" ] || [ -d "/etc/steamos" ]; then
        if command -v steamos-readonly >/dev/null 2>&1; then
            echo -e "${BLUE}Re-enabling SteamOS read-only mode...${NC}"
            sudo steamos-readonly enable
            echo "[OK] Read-only mode re-enabled"
        fi
    fi
}

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
        echo "[OK] All required dependencies are already installed"
        return 0
    fi
    
    echo -e "${YELLOW}Missing dependencies: ${missing_deps[*]}${NC}"
    echo ""
    
    # Detect package manager and install
    if command -v pacman >/dev/null 2>&1; then
        echo -e "${BLUE}Detected Arch Linux/SteamOS (pacman)${NC}"
        
        # Check for SteamOS and handle keyring issues
        if [ -f "/etc/steamos-release" ] || [ -d "/etc/steamos" ]; then
            echo -e "${YELLOW}SteamOS detected - checking system status...${NC}"
            
            # Check if system is in read-only mode
            if command -v steamos-readonly >/dev/null 2>&1; then
                if steamos-readonly status 2>/dev/null | grep -q "enabled"; then
                    echo -e "${YELLOW}[WARNING] SteamOS is in read-only mode. Temporarily disabling...${NC}"
                    sudo steamos-readonly disable
                    echo "[OK] Read-only mode disabled"
                fi
            fi
            
            # Initialize keyring if needed
            if ! sudo pacman-key --list-sigs >/dev/null 2>&1; then
                echo "Initializing pacman keyring..."
                sudo pacman-key --init
                sudo pacman-key --populate archlinux
                sudo pacman-key --populate steamos
                
                # Trust SteamOS package builder key
                echo "Adding SteamOS package builder key..."
                sudo pacman-key --recv-keys AF1D2199EF0A3CCF 2>/dev/null || true
                sudo pacman-key --lsign-key AF1D2199EF0A3CCF 2>/dev/null || true
            fi
        fi
        
        echo "Installing missing dependencies..."
        
        # Map package names for Arch
        local arch_packages=()
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                "python3") arch_packages+=("python") ;;
                *) arch_packages+=("$dep") ;;
            esac
        done
        
        # Try installation with keyring handling
        if sudo pacman -S --noconfirm "${arch_packages[@]}"; then
            echo "[OK] Dependencies installed successfully"
            reenable_readonly
            return 0
        else
            echo -e "${YELLOW}[WARNING]  First attempt failed, trying with keyring refresh...${NC}"
            
            # Refresh keyring and try again
            sudo pacman-key --refresh-keys 2>/dev/null || true
            sudo pacman -Sy 2>/dev/null || true
            
            if sudo pacman -S --noconfirm "${arch_packages[@]}"; then
                echo "[OK] Dependencies installed successfully (after keyring refresh)"
                reenable_readonly
                return 0
            else
                echo -e "${RED}[ERROR] Failed to install dependencies with pacman${NC}"
                echo -e "${YELLOW}This might be a keyring issue. Try running:${NC}"
                echo "  sudo pacman-key --init"
                echo "  sudo pacman-key --populate archlinux"
                echo "  sudo pacman-key --populate steamos"
                return 1
            fi
        fi
        
    elif command -v apt >/dev/null 2>&1; then
        echo -e "${BLUE}Detected Ubuntu/Debian (apt)${NC}"
        echo "Installing missing dependencies..."
        
        if sudo apt update && sudo apt install -y "${missing_deps[@]}"; then
            echo "[OK] Dependencies installed successfully"
            return 0
        else
            echo -e "${RED}[ERROR] Failed to install dependencies with apt${NC}"
            return 1
        fi
        
    elif command -v dnf >/dev/null 2>&1; then
        echo -e "${BLUE}Detected Fedora/RHEL (dnf)${NC}"
        echo "Installing missing dependencies..."
        
        if sudo dnf install -y "${missing_deps[@]}"; then
            echo "[OK] Dependencies installed successfully"
            return 0
        else
            echo -e "${RED}[ERROR] Failed to install dependencies with dnf${NC}"
            return 1
        fi
        
    else
        echo -e "${RED}[ERROR] Unsupported package manager${NC}"
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
        echo -e "${RED}[ERROR] Please install the missing dependencies manually and run this script again.${NC}"
        exit 1
    fi
fi

# Final dependency verification
echo ""
echo -e "${BLUE}Verifying all dependencies are installed...${NC}"
if ! ./check_dependencies.sh; then
    echo -e "${RED}[ERROR] Some dependencies are still missing after installation attempt${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}Step 2: Setting up permissions...${NC}"

# Set executable permissions on all scripts
chmod +x *.sh
chmod +x lib/*.sh
chmod +x scripts/standalone/*.sh

echo "[OK] Set executable permissions on all scripts"

echo ""
echo -e "${BLUE}Step 3: Testing basic functionality...${NC}"

# Test basic functionality
echo "Testing modrollback.sh..."
if ./modrollback.sh --help >/dev/null 2>&1; then
    echo "[OK] modrollback.sh is working"
else
    echo -e "${YELLOW}[WARNING]  modrollback.sh test failed (this might be normal if no mods are installed)${NC}"
fi

echo "Testing modinstaller.sh..."
if ./modinstaller.sh --help >/dev/null 2>&1; then
    echo "[OK] modinstaller.sh is working"
else
    echo -e "${YELLOW}[WARNING]  modinstaller.sh test failed${NC}"
fi

echo ""
echo "=========================================="
echo -e "[SUCCESS] ${GREEN}Installation Complete!${NC}"
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
echo -e "${GREEN}Happy modding! [GAME]${NC}"

#!/bin/bash

# Dependency Check Script for REPO-Magic
# This script checks for all required and optional dependencies

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
echo "  REPO-Magic Dependency Check"
echo "=========================================="
echo ""

# Required dependencies
REQUIRED_DEPS=("bash" "jq" "curl" "openssl" "git" "python3")
OPTIONAL_DEPS=("gh" "sudo")

# Check function
check_dependency() {
    local dep="$1"
    local required="$2"
    
    if command -v "$dep" >/dev/null 2>&1; then
        local version=""
        case "$dep" in
            "bash")
                version=$(bash --version | head -1 | cut -d' ' -f4)
                ;;
            "jq")
                version=$(jq --version 2>/dev/null | cut -d'-' -f2)
                ;;
            "curl")
                version=$(curl --version | head -1 | cut -d' ' -f2)
                ;;
            "openssl")
                version=$(openssl version | cut -d' ' -f2)
                ;;
            "git")
                version=$(git --version | cut -d' ' -f3)
                ;;
            "python3")
                version=$(python3 --version | cut -d' ' -f2)
                ;;
            "gh")
                version=$(gh --version | head -1 | cut -d' ' -f3)
                ;;
            "sudo")
                version=$(sudo --version | head -1 | cut -d' ' -f3)
                ;;
        esac
        
        if [ "$required" = "true" ]; then
            echo -e "[OK] ${GREEN}$dep${NC} - $version ${GREEN}(Required)${NC}"
            return 0
        else
            echo -e "[OK] ${GREEN}$dep${NC} - $version ${BLUE}(Optional)${NC}"
            return 0
        fi
    else
        if [ "$required" = "true" ]; then
            echo -e "[ERROR] ${RED}$dep${NC} - ${RED}NOT FOUND (Required)${NC}"
            return 1
        else
            echo -e "⚠️  ${YELLOW}$dep${NC} - ${YELLOW}NOT FOUND (Optional)${NC}"
            return 0
        fi
    fi
}

# Check required dependencies
echo -e "${BLUE}Checking Required Dependencies:${NC}"
echo "----------------------------------------"
missing_required=0
for dep in "${REQUIRED_DEPS[@]}"; do
    if ! check_dependency "$dep" "true"; then
        missing_required=$((missing_required + 1))
    fi
done

echo ""
echo -e "${BLUE}Checking Optional Dependencies:${NC}"
echo "----------------------------------------"
for dep in "${OPTIONAL_DEPS[@]}"; do
    check_dependency "$dep" "false"
done

echo ""
echo "=========================================="

# Summary
if [ $missing_required -eq 0 ]; then
    echo -e "[SUCCESS] ${GREEN}All required dependencies are installed!${NC}"
    echo -e "   You can run the mod management tools."
    exit 0
else
    echo -e "[ERROR] ${RED}$missing_required required dependencies are missing.${NC}"
    echo ""
    echo -e "${YELLOW}Installation Instructions:${NC}"
    echo "----------------------------------------"
    
    for dep in "${REQUIRED_DEPS[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            case "$dep" in
                "bash")
                    echo "• bash: Usually pre-installed on Linux systems"
                    ;;
                "jq")
                    echo "• jq: Install with 'sudo pacman -S jq' (Arch/SteamOS) or 'sudo apt install jq' (Ubuntu/Debian)"
                    ;;
                "curl")
                    echo "• curl: Install with 'sudo pacman -S curl' (Arch/SteamOS) or 'sudo apt install curl' (Ubuntu/Debian)"
                    ;;
                "openssl")
                    echo "• openssl: Install with 'sudo pacman -S openssl' (Arch/SteamOS) or 'sudo apt install openssl' (Ubuntu/Debian)"
                    ;;
                "git")
                    echo "• git: Install with 'sudo pacman -S git' (Arch/SteamOS) or 'sudo apt install git' (Ubuntu/Debian)"
                    ;;
                "python3")
                    echo "• python3: Install with 'sudo pacman -S python' (Arch/SteamOS) or 'sudo apt install python3' (Ubuntu/Debian)"
                    ;;
            esac
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Optional Dependencies:${NC}"
    echo "• gh (GitHub CLI): For advanced GitHub integration features"
    echo "• sudo: For SteamOS read-only mode changes"
    
    exit 1
fi

#!/bin/bash

# SteamOS Utilities Library
# Provides SteamOS-specific functions for system management

# Define colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to check if running on SteamOS
is_steamos() {
    if [ -f "/etc/os-release" ] && grep -q "SteamOS" /etc/os-release; then
        return 0
    else
        return 1
    fi
}

# Function to disable SteamOS read-only mode
disable_steamos_readonly() {
    if is_steamos; then
        echo "Disabling SteamOS read-only mode..."
        log_message "INFO" "Disabling SteamOS read-only mode"
        
        if sudo steamos-readonly disable; then
            echo -e "${GREEN}SteamOS read-only mode disabled${NC}"
            log_message "INFO" "SteamOS read-only mode disabled successfully"
            return 0
        else
            echo -e "${RED}Failed to disable SteamOS read-only mode${NC}"
            log_message "ERROR" "Failed to disable SteamOS read-only mode"
            return 1
        fi
    else
        echo "Not running on SteamOS, skipping read-only mode changes"
        log_message "INFO" "Not running on SteamOS, skipping read-only mode changes"
        return 0
    fi
}

# Function to enable SteamOS read-only mode
enable_steamos_readonly() {
    if is_steamos; then
        echo "Re-enabling SteamOS read-only mode..."
        log_message "INFO" "Re-enabling SteamOS read-only mode"
        
        if sudo steamos-readonly enable; then
            echo -e "${GREEN}SteamOS read-only mode enabled${NC}"
            log_message "INFO" "SteamOS read-only mode enabled successfully"
            return 0
        else
            echo -e "${RED}Failed to enable SteamOS read-only mode${NC}"
            log_message "ERROR" "Failed to enable SteamOS read-only mode"
            return 1
        fi
    else
        echo "Not running on SteamOS, skipping read-only mode changes"
        log_message "INFO" "Not running on SteamOS, skipping read-only mode changes"
        return 0
    fi
}

# Function to check and install dependencies
check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    for cmd in curl unzip jq python3; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        echo -e "${GREEN}All dependencies are installed${NC}"
        log_message "INFO" "All dependencies are installed"
        return 0
    fi
    
    echo -e "${YELLOW}Missing dependencies: ${missing_deps[*]}${NC}"
    log_message "WARN" "Missing dependencies: ${missing_deps[*]}"
    
    if is_steamos; then
        echo "Installing missing dependencies on SteamOS..."
        log_message "INFO" "Installing missing dependencies on SteamOS"
        
        # Disable read-only mode
        if ! disable_steamos_readonly; then
            echo -e "${RED}Failed to disable read-only mode for dependency installation${NC}"
            log_message "ERROR" "Failed to disable read-only mode for dependency installation"
            return 1
        fi
        
        # Install dependencies with fallback strategy
        for dep in "${missing_deps[@]}"; do
            echo "Installing $dep..."
            if ! install_dependency_steamos "$dep"; then
                echo -e "${RED}Failed to install $dep${NC}"
                log_message "ERROR" "Failed to install $dep"
                return 1
            fi
        done
        
        # Re-enable read-only mode
        if ! enable_steamos_readonly; then
            echo -e "${YELLOW}Warning: Failed to re-enable read-only mode${NC}"
            log_message "WARN" "Failed to re-enable read-only mode"
        fi
        
        echo -e "${GREEN}All dependencies installed successfully${NC}"
        log_message "INFO" "All dependencies installed successfully"
        return 0
    else
        echo -e "${RED}Please install missing dependencies manually: ${missing_deps[*]}${NC}"
        log_message "ERROR" "Please install missing dependencies manually: ${missing_deps[*]}"
        return 1
    fi
}

# Function to install dependency on SteamOS with fallback strategy
install_dependency_steamos() {
    local dep="$1"
    
    # Try standard pacman installation first
    if sudo pacman -S --noconfirm "$dep" >/dev/null 2>&1; then
        echo -e "${GREEN}$dep installed successfully${NC}"
        return 0
    fi
    
    # If that fails, try with SteamOS key trust
    echo "Standard installation failed, trying with SteamOS key trust..."
    if sudo pacman-key --recv-keys AF1D2199EF0A3CCF >/dev/null 2>&1 && \
       sudo pacman-key --lsign-key AF1D2199EF0A3CCF >/dev/null 2>&1 && \
       sudo pacman -S --noconfirm "$dep" >/dev/null 2>&1; then
        echo -e "${GREEN}$dep installed successfully with key trust${NC}"
        return 0
    fi
    
    # Last resort: install without signature verification
    echo "Key trust failed, trying without signature verification..."
    if sudo pacman -S --noconfirm --disable-download-timeout "$dep" >/dev/null 2>&1; then
        echo -e "${GREEN}$dep installed successfully without signature verification${NC}"
        return 0
    fi
    
    echo -e "${RED}Failed to install $dep with all methods${NC}"
    return 1
}

# Function to check network connectivity
check_network() {
    echo "Checking network connectivity..."
    log_message "INFO" "Checking network connectivity"
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        echo -e "${GREEN}Network connectivity OK${NC}"
        log_message "INFO" "Network connectivity OK"
        return 0
    else
        echo -e "${RED}No network connectivity${NC}"
        log_message "ERROR" "No network connectivity"
        return 1
    fi
}

# Function to check disk space
check_disk_space() {
    local required_space_mb=100  # 100MB minimum
    
    echo "Checking available disk space..."
    log_message "INFO" "Checking available disk space"
    
    local available_space=$(df /tmp | awk 'NR==2 {print int($4/1024)}')
    
    if [ "$available_space" -ge "$required_space_mb" ]; then
        echo -e "${GREEN}Sufficient disk space available (${available_space}MB)${NC}"
        log_message "INFO" "Sufficient disk space available (${available_space}MB)"
        return 0
    else
        echo -e "${RED}Insufficient disk space (${available_space}MB available, ${required_space_mb}MB required)${NC}"
        log_message "ERROR" "Insufficient disk space (${available_space}MB available, ${required_space_mb}MB required)"
        return 1
    fi
}

# Function to check if r2modmanPlus is running
check_r2modman_running() {
    if pgrep -f "r2modmanPlus" >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: r2modmanPlus appears to be running${NC}"
        echo "It's recommended to close r2modmanPlus before running this script to avoid conflicts."
        log_message "WARN" "r2modmanPlus appears to be running"
        
        read -p "Continue anyway? (y/N): " continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            echo "Exiting..."
            log_message "INFO" "User chose to exit due to r2modmanPlus running"
            exit 0
        fi
    fi
}

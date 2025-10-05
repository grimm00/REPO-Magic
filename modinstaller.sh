#!/usr/bin/env bash

# Mod Installer for SteamOS (Modular Version)
# Installs the MoreUpgrades mod for Risk of Rain 2
# Uses modular libraries for better maintainability

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library files
source "$SCRIPT_DIR/lib/logging_utils.sh"
source "$SCRIPT_DIR/lib/steamos_utils.sh"
source "$SCRIPT_DIR/lib/yaml_utils.sh"
source "$SCRIPT_DIR/lib/registry_utils.sh"

# Define colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
MOD_NAME="BULLETBOT-MoreUpgrades"
MOD_VERSION="1.4.8"
MOD_AUTHOR="BULLETBOT"
MOD_DESCRIPTION="Adds more upgrade items to the game, has an library and is highly configurable."
MOD_URL="https://thunderstore.io/package/download/BULLETBOT/MoreUpgrades/1.4.8/"
MOD_INSTALL_PATH_REPO="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades"
MODS_YML="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose    Enable verbose logging"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "This script installs the MoreUpgrades mod for Risk of Rain 2 on SteamOS."
}

# Function to parse command line arguments
parse_arguments() {
    VERBOSE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                show_usage
                exit 1
                ;;
            *)
                echo -e "${RED}Unexpected argument: $1${NC}"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Function to initialize the script
init_script() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  MoreUpgrades Mod Installer for SteamOS${NC}"
    echo -e "${BLUE}  (Modular Version)${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "This script will install the MoreUpgrades mod for Risk of Rain 2."
    echo ""
    
    # Initialize logging
    init_logging "modinstaller-modular" "$VERBOSE"
    log_message "INFO" "Mod Installer (Modular) started"
    
    # Check if we should skip dependency checks
    if [ "$SKIP_DEPENDENCY_CHECK" = "true" ]; then
        echo "Skipping dependency check (SKIP_DEPENDENCY_CHECK=true)"
        echo "Skipping sudo check (SKIP_DEPENDENCY_CHECK=true)"
        echo "Skipping SteamOS read-only mode changes (SKIP_DEPENDENCY_CHECK=true)"
        log_message "INFO" "Skipping dependency checks due to SKIP_DEPENDENCY_CHECK=true"
    else
        # Check dependencies
        if ! check_dependencies; then
            echo -e "${RED}Dependency check failed${NC}"
            log_message "ERROR" "Dependency check failed"
            exit 1
        fi
        
        # Check network connectivity
        if ! check_network; then
            echo -e "${RED}Network check failed${NC}"
            log_message "ERROR" "Network check failed"
            exit 1
        fi
        
        # Check disk space
        if ! check_disk_space; then
            echo -e "${RED}Disk space check failed${NC}"
            log_message "ERROR" "Disk space check failed"
            exit 1
        fi
        
        # Check if r2modmanPlus is running
        check_r2modman_running
        
        # Check sudo access
        if ! sudo -n true 2>/dev/null; then
            echo "This script requires sudo privileges for SteamOS system modifications."
            echo "Please enter your password when prompted."
            if ! sudo -v; then
                echo -e "${RED}Failed to obtain sudo privileges${NC}"
                log_message "ERROR" "Failed to obtain sudo privileges"
                exit 1
            fi
        fi
        
        # Disable SteamOS read-only mode
        if ! disable_steamos_readonly; then
            echo -e "${RED}Failed to disable SteamOS read-only mode${NC}"
            log_message "ERROR" "Failed to disable SteamOS read-only mode"
            exit 1
        fi
    fi
    
    # Set up cleanup trap
    trap 'cleanup_on_exit' EXIT
}

# Function to cleanup on exit
cleanup_on_exit() {
    if [ "$SKIP_DEPENDENCY_CHECK" != "true" ]; then
        # Re-enable SteamOS read-only mode
        enable_steamos_readonly
    fi
    
    log_message "INFO" "Mod Installer (Modular) finished"
}

# Function to download and install mod
download_and_install_mod() {
    echo -e "${BLUE}Downloading and installing mod...${NC}"
    log_message "INFO" "Downloading MoreUpgrades mod from $MOD_URL"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local download_file="$temp_dir/MoreUpgrades.zip"
    
    # Download mod
    echo "Downloading mod..."
    if ! curl -L -o "$download_file" "$MOD_URL"; then
        echo -e "${RED}Failed to download mod${NC}"
        log_message "ERROR" "Failed to download mod from $MOD_URL"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Extract mod files
    echo "Extracting mod files..."
    if ! unzip -q "$download_file" -d "$temp_dir"; then
        echo -e "${RED}Failed to extract mod files${NC}"
        log_message "ERROR" "Failed to extract mod files"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Create mod directory
    echo "Creating mod directory..."
    if ! mkdir -p "$MOD_INSTALL_PATH_REPO"; then
        echo -e "${RED}Failed to create mod directory${NC}"
        log_message "ERROR" "Failed to create mod directory: $MOD_INSTALL_PATH_REPO"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Copy mod files
    echo "Installing mod files..."
    if ! cp -r "$temp_dir"/* "$MOD_INSTALL_PATH_REPO/"; then
        echo -e "${RED}Failed to install mod files${NC}"
        log_message "ERROR" "Failed to install mod files"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}Mod installed successfully!${NC}"
    log_message "INFO" "MoreUpgrades mod installed successfully"
}

# Function to register mod with r2modmanPlus
register_mod() {
    if [ -f "$MODS_YML" ]; then
        add_mod_to_registry \
            "$MOD_NAME" \
            "$MOD_INSTALL_PATH_REPO" \
            "$MOD_VERSION" \
            "$MOD_AUTHOR" \
            "$MOD_DESCRIPTION" \
            "$MOD_URL" \
            "$MODS_YML"
    else
        echo -e "${YELLOW}Warning: r2modmanPlus mods.yml not found at $MODS_YML${NC}"
        echo "Mod installed but not registered with r2modmanPlus"
        log_message "WARN" "r2modmanPlus mods.yml not found at $MODS_YML"
    fi
}

# Main execution
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize script
    init_script
    
    # Confirm installation
    echo -e "${BLUE}Installation Summary:${NC}"
    echo -e "  Mod: $MOD_NAME"
    echo -e "  Version: $MOD_VERSION"
    echo -e "  Author: $MOD_AUTHOR"
    echo -e "  Install Path: $MOD_INSTALL_PATH_REPO"
    echo ""
    
    if ! confirm_action "Proceed with installation?"; then
        echo "Installation cancelled."
        log_message "INFO" "Installation cancelled by user"
        exit 0
    fi
    
    # Download and install mod
    download_and_install_mod
    
    # Register the mod with r2modmanPlus
    register_mod
    
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo -e "${GREEN}The MoreUpgrades mod has been successfully installed!${NC}"
    echo ""
    echo "You can now start r2modmanPlus to see the mod in your profile."
    echo ""
    
    log_message "INFO" "MoreUpgrades mod installation completed successfully"
}

# Run main function
main "$@"

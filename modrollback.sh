#!/usr/bin/env bash

# Mod Rollback Tool for r2modmanPlus (Modular Version)
# This script helps you rollback any installed mod to a previous version
# Uses modular libraries for better maintainability

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library files
source "$SCRIPT_DIR/lib/logging_utils.sh"
source "$SCRIPT_DIR/lib/steamos_utils.sh"
source "$SCRIPT_DIR/lib/yaml_utils.sh"
source "$SCRIPT_DIR/lib/registry_utils.sh"
source "$SCRIPT_DIR/lib/mod_utils.sh"

# Define colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuration
MOD_PLUGIN_PATH="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins"
MODS_YML="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml"

# Global variables
mod_info=""
rollback_version=""
selected_mod=""
selected_author=""
current_version=""

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [MOD_NAME]"
    echo ""
    echo "Options:"
    echo "  -v, --verbose    Enable verbose logging"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Arguments:"
    echo "  MOD_NAME         Name of the mod to rollback (optional)"
    echo ""
    echo "Examples:"
    echo "  $0                    # Interactive mode"
    echo "  $0 moreupgrades       # Rollback MoreUpgrades mod"
    echo "  $0 -v moreupgrades    # Verbose mode with specific mod"
}

# Function to parse command line arguments
parse_arguments() {
    SEARCH_TERM=""
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
                if [ -z "$SEARCH_TERM" ]; then
                    SEARCH_TERM=$(validate_input "$1" "search_term")
                else
                    echo -e "${RED}Multiple mod names provided. Please specify only one.${NC}"
                    exit 1
                fi
                shift
                ;;
        esac
    done
}

# Function to initialize the script
init_script() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  Mod Rollback Tool for r2modmanPlus${NC}"
    echo -e "${BLUE}  (Modular Version)${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "This script will help you rollback any installed mod to a previous version."
    echo ""
    
    # Initialize logging
    init_logging "modrollback-modular" "$VERBOSE"
    log_message "INFO" "Mod Rollback Tool (Modular) started"
    
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
    
    # Clean and validate mods.yml file before proceeding
    if [ -f "$MODS_YML" ]; then
        clean_mods_yml "$MODS_YML"
        if [ $? -ne 0 ]; then
            echo -e "${RED}Failed to clean mods.yml file. Please check the file manually.${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Warning: mods.yml not found at $MODS_YML${NC}"
        echo "Registry updates will be skipped."
        log_message "WARN" "mods.yml not found at $MODS_YML"
    fi
}

# Function to cleanup on exit
cleanup_on_exit() {
    if [ "$SKIP_DEPENDENCY_CHECK" != "true" ]; then
        # Re-enable SteamOS read-only mode
        enable_steamos_readonly
    fi
    
    log_message "INFO" "Mod Rollback Tool (Modular) finished"
}

# Function to get download URL for mod version
get_download_url() {
    local mod_name="$1"
    local version="$2"
    local author="$3"
    
    # Construct download URL
    local download_url="https://thunderstore.io/package/download/$author/$mod_name/$version/"
    
    echo "$download_url"
}

# Main execution
main() {
    # Parse command line arguments
    parse_arguments "$@"
    
    # Initialize script
    init_script
    
    # Show search term if provided
    if [ -n "$SEARCH_TERM" ]; then
        echo -e "${BLUE}Search term provided: '$SEARCH_TERM'${NC}"
        log_message "INFO" "Search term provided: '$SEARCH_TERM'"
    fi
    
    echo "Checking installed mods..."
    
    # Get mod selection from user (this will show filtered results)
    get_mod_selection "$SEARCH_TERM"
    
    # Parse mod info
    IFS='|' read -r selected_mod selected_author current_version <<< "$mod_info"
    
    # Get rollback version
    get_rollback_version "$current_version" "$selected_mod"
    
    # Get download URL
    local download_url=$(get_download_url "$selected_mod" "$rollback_version" "$selected_author")
    
    echo ""
    echo -e "${BLUE}Rollback Summary:${NC}"
    echo -e "  Mod: $selected_mod"
    echo -e "  Author: $selected_author"
    echo -e "  Current version: $current_version"
    echo -e "  Rollback version: $rollback_version"
    echo -e "  Download URL: $download_url"
    echo ""
    
    # Confirm rollback
    if ! confirm_action "Proceed with rollback?"; then
        echo "Rollback cancelled."
        log_message "INFO" "Rollback cancelled by user"
        exit 0
    fi
    
    # Download and install mod
    download_and_install_mod "$selected_mod" "$download_url" "$rollback_version"
    
    # Update registry
    update_mod_registry "$selected_mod" "$selected_author" "$current_version" "$rollback_version" "$MODS_YML"
    
    echo ""
    echo -e "${GREEN}==========================================${NC}"
    echo -e "${GREEN}  Rollback Complete!${NC}"
    echo -e "${GREEN}==========================================${NC}"
    echo ""
    echo -e "${GREEN}Mod '$selected_mod' has been successfully rolled back from version $current_version to $rollback_version.${NC}"
    echo ""
    echo "You can now start r2modmanPlus to see the changes."
    echo ""
    
    log_message "INFO" "Rollback completed successfully: $selected_mod from $current_version to $rollback_version"
}

# Run main function
main "$@"

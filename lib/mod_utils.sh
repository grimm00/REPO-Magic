#!/bin/bash

# Mod Utilities Library
# Provides functions for mod discovery, selection, and management

# Define colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to list all installed mods
list_installed_mods() {
    local temp_file=$(mktemp)
    
    if [ ! -d "$MOD_PLUGIN_PATH" ]; then
        echo -e "${RED}Error: Mod plugin path not found: $MOD_PLUGIN_PATH${NC}"
        log_message "ERROR" "Mod plugin path not found: $MOD_PLUGIN_PATH"
        rm "$temp_file"
        return 1
    fi
    
    echo "Scanning installed mods..."
    log_message "INFO" "Scanning installed mods in $MOD_PLUGIN_PATH"
    
    # Find all mod directories
    find "$MOD_PLUGIN_PATH" -maxdepth 1 -type d -name "*-*" | while read -r mod_dir; do
        if [ -f "$mod_dir/manifest.json" ]; then
            local mod_name=$(basename "$mod_dir")
            local author=$(echo "$mod_name" | cut -d'-' -f1)
            local version=$(grep '"version_number"' "$mod_dir/manifest.json" | sed 's/.*"version_number": *"\([^"]*\)".*/\1/')
            
            if [ -z "$version" ]; then
                version="Unknown"
            fi
            
            echo "$mod_name|$author|$version" >> "$temp_file"
        fi
    done
    
    # Sort the results
    sort "$temp_file" > "${temp_file}.sorted"
    mv "${temp_file}.sorted" "$temp_file"
    
    echo "$temp_file"
}

# Function to search for mods matching a term
search_mods() {
    local search_term="$1"
    local temp_file=$(mktemp)
    
    if [ ! -d "$MOD_PLUGIN_PATH" ]; then
        echo -e "${RED}Error: Mod plugin path not found: $MOD_PLUGIN_PATH${NC}"
        log_message "ERROR" "Mod plugin path not found: $MOD_PLUGIN_PATH"
        rm "$temp_file"
        return 1
    fi
    
    echo "Searching for mods matching: '$search_term'"
    log_message "INFO" "Searching for mods matching: '$search_term'"
    
    # Find all mod directories and filter by search term
    find "$MOD_PLUGIN_PATH" -maxdepth 1 -type d -name "*-*" | while read -r mod_dir; do
        if [ -f "$mod_dir/manifest.json" ]; then
            local mod_name=$(basename "$mod_dir")
            local author=$(echo "$mod_name" | cut -d'-' -f1)
            local version=$(grep '"version_number"' "$mod_dir/manifest.json" | sed 's/.*"version_number": *"\([^"]*\)".*/\1/')
            
            if [ -z "$version" ]; then
                version="Unknown"
            fi
            
            # Check if mod name or author matches search term (case insensitive)
            if echo "$mod_name" | grep -qi "$search_term" || echo "$author" | grep -qi "$search_term"; then
                echo "$mod_name|$author|$version" >> "$temp_file"
            fi
        fi
    done
    
    # Sort the results
    sort "$temp_file" > "${temp_file}.sorted"
    mv "${temp_file}.sorted" "$temp_file"
    
    echo "$temp_file"
}

# Function to get user input for mod selection
get_mod_selection() {
    local search_term="$1"
    
    echo ""
    if [ -n "$search_term" ]; then
        echo -e "${YELLOW}Searching for mods matching: '$search_term'${NC}"
    else
        echo -e "${YELLOW}Please select a mod to rollback:${NC}"
    fi
    echo ""
    
    # Create temporary file to store mod list
    local temp_file=$(mktemp)
    
    # Search for mods
    if [ -n "$search_term" ]; then
        if ! search_mods "$search_term" > "$temp_file"; then
            echo -e "${RED}No mods found matching '$search_term'${NC}"
            log_message "ERROR" "No mods found matching '$search_term'"
            rm "$temp_file"
            exit 1
        fi
    else
        if ! list_installed_mods > "$temp_file"; then
            echo -e "${RED}No mods found${NC}"
            log_message "ERROR" "No mods found"
            rm "$temp_file"
            exit 1
        fi
    fi
    
    # Count mods
    local mod_count=$(wc -l < "$temp_file")
    
    if [ "$mod_count" -eq 0 ]; then
        echo -e "${RED}No mods found${NC}"
        log_message "ERROR" "No mods found"
        rm "$temp_file"
        exit 1
    fi
    
    echo -e "${BLUE}Search Results:${NC}"
    echo ""
    
    # Display mods
    local display_count=0
    while IFS='|' read -r name author version; do
        display_count=$((display_count + 1))
        printf "%2d. %-30s by %-20s (v%s)\n" "$display_count" "$name" "$author" "$version"
    done < "$temp_file"
    
    echo ""
    
    # Auto-select if only one mod found
    if [ "$mod_count" -eq 1 ]; then
        selection=1
        echo -e "${GREEN}Only one mod found, auto-selecting...${NC}"
        log_message "INFO" "Auto-selected single mod match"
    else
        read -p "Enter the number of the mod to rollback (1-$mod_count): " selection
        
        # Validate and sanitize selection
        selection=$(validate_input "$selection" "number")
        if [ -z "$selection" ] || [ "$selection" -lt 1 ] || [ "$selection" -gt "$mod_count" ]; then
            echo -e "${RED}Invalid selection. Please enter a number between 1 and $mod_count.${NC}"
            log_message "ERROR" "Invalid mod selection: $selection"
            rm "$temp_file"
            exit 1
        fi
    fi
    
    # Get selected mod info
    local selected_line=$(sed -n "${selection}p" "$temp_file")
    IFS='|' read -r selected_name selected_author selected_version <<< "$selected_line"
    
    rm "$temp_file"
    
    echo ""
    echo -e "${GREEN}Selected mod:${NC} $selected_name"
    echo -e "${GREEN}Author:${NC} $selected_author"
    echo -e "${GREEN}Current version:${NC} $selected_version"
    
    # Set global variable with mod info
    mod_info="$selected_name|$selected_author|$selected_version"
}

# Function to get rollback version
get_rollback_version() {
    local current_version="$1"
    local mod_name="$2"
    
    echo ""
    echo -e "${YELLOW}Rollback Options for: $mod_name${NC}"
    echo -e "${YELLOW}Current version: $current_version${NC}"
    echo ""
    
    # Parse current version
    local current_major=$(echo $current_version | cut -d. -f1)
    local current_minor=$(echo $current_version | cut -d. -f2)
    local current_patch=$(echo $current_version | cut -d. -f3)
    
    echo "Rollback options:"
    echo "1. Previous patch version (e.g., $current_version → $current_major.$current_minor.$((current_patch-1)))"
    echo "2. Previous minor version (e.g., $current_version → $current_major.$((current_minor-1)).0)"
    echo "3. Previous major version (e.g., $current_version → $((current_major-1)).0.0)"
    echo "4. Enter custom version"
    echo ""
    
    read -p "Select rollback option (1-4): " option
    
    # Validate and sanitize option
    option=$(validate_input "$option" "number")
    if [ -z "$option" ] || [ "$option" -lt 1 ] || [ "$option" -gt 4 ]; then
        echo -e "${RED}Invalid option. Please select 1-4.${NC}"
        log_message "ERROR" "Invalid rollback option: $option"
        exit 1
    fi
    
    case $option in
        1)
            # Previous patch version
            rollback_version="$current_major.$current_minor.$((current_patch-1))"
            echo -e "${GREEN}Selected: Previous patch version ($rollback_version)${NC}"
            ;;
        2)
            # Previous minor version
            rollback_version="$current_major.$((current_minor-1)).0"
            echo -e "${GREEN}Selected: Previous minor version ($rollback_version)${NC}"
            ;;
        3)
            # Previous major version
            rollback_version="$((current_major-1)).0.0"
            echo -e "${GREEN}Selected: Previous major version ($rollback_version)${NC}"
            ;;
        4)
            # Custom version
            read -p "Enter custom version (e.g., 1.2.3): " custom_version
            custom_version=$(validate_input "$custom_version" "version")
            if [ -z "$custom_version" ]; then
                echo -e "${RED}Invalid version format. Please use format like 1.2.3${NC}"
                log_message "ERROR" "Invalid custom version: $custom_version"
                exit 1
            fi
            rollback_version="$custom_version"
            echo -e "${GREEN}Selected: Custom version ($rollback_version)${NC}"
            ;;
    esac
    
    log_message "INFO" "Selected rollback version: $rollback_version"
}

# Function to download and install mod
download_and_install_mod() {
    local mod_name="$1"
    local download_url="$2"
    local version="$3"
    
    echo ""
    echo -e "${BLUE}Downloading and installing mod...${NC}"
    log_message "INFO" "Downloading $mod_name version $version from $download_url"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local download_file="$temp_dir/mod.zip"
    
    # Download mod
    echo "Downloading mod..."
    if ! curl -L -o "$download_file" "$download_url"; then
        echo -e "${RED}Failed to download mod${NC}"
        log_message "ERROR" "Failed to download mod from $download_url"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Check if download is a zip file
    if file "$download_file" | grep -q "Zip archive"; then
        echo "Extracting mod files..."
        if ! unzip -q "$download_file" -d "$temp_dir"; then
            echo -e "${RED}Failed to extract mod files${NC}"
            log_message "ERROR" "Failed to extract mod files"
            rm -rf "$temp_dir"
            exit 1
        fi
    else
        echo "Download is not a zip file, treating as extracted content..."
        # Move the downloaded file to the temp directory
        mv "$download_file" "$temp_dir/"
    fi
    
    # Remove existing mod files
    echo "Removing existing mod files..."
    if [ -d "${MOD_PLUGIN_PATH}/${mod_name}" ]; then
        rm -rf "${MOD_PLUGIN_PATH}/${mod_name}"
    fi
    
    # Install new mod files
    echo "Installing new mod files..."
    if ! cp -r "$temp_dir"/* "${MOD_PLUGIN_PATH}/${mod_name}/"; then
        echo -e "${RED}Failed to install mod files${NC}"
        log_message "ERROR" "Failed to install mod files"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Clean up
    rm -rf "$temp_dir"
    
    echo -e "${GREEN}Mod installed successfully!${NC}"
    log_message "INFO" "Mod $mod_name version $version installed successfully"
}

# Function to validate input
validate_input() {
    local input="$1"
    local type="$2"
    
    case $type in
        "number")
            # Remove any non-numeric characters except digits
            echo "$input" | sed 's/[^0-9]//g'
            ;;
        "version")
            # Validate version format (e.g., 1.2.3)
            if echo "$input" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
                echo "$input"
            else
                echo ""
            fi
            ;;
        "search_term")
            # Remove dangerous characters but allow alphanumeric, spaces, hyphens, underscores
            echo "$input" | sed 's/[^a-zA-Z0-9._ -]//g' | head -c 50
            ;;
        *)
            # Default: remove dangerous characters
            echo "$input" | sed 's/[^a-zA-Z0-9._ -]//g' | head -c 100
            ;;
    esac
}

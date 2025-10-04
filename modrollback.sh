#!/usr/bin/env bash

# Mod Rollback Script for r2modmanPlus
# Allows users to rollback any installed mod to a previous version

# Set up cleanup function to re-enable read-only mode on exit
cleanup() {
    if [ "$readonly_disabled" = true ]; then
        echo ""
        echo "Re-enabling SteamOS read-only mode..."
        if sudo steamos-readonly enable; then
            echo "Read-only mode re-enabled successfully."
        else
            echo "Warning: Could not re-enable read-only mode. You may want to run:"
            echo "sudo steamos-readonly enable"
        fi
    fi
}

# Set trap to run cleanup on script exit (success or failure)
trap cleanup EXIT

# Configuration
MODS_YML="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml"
MOD_PLUGIN_PATH="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/"
THUNDERSTORE_BASE_URL="https://thunderstore.io/package/download"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging configuration
LOG_FILE="/tmp/modrollback_$(date +%Y%m%d_%H%M%S).log"
VERBOSE=false

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [ "$VERBOSE" = true ] || [ "$level" = "ERROR" ] || [ "$level" = "WARN" ]; then
        echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
    else
        echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    fi
}

# Function to validate and sanitize input
validate_input() {
    local input="$1"
    local type="$2"
    
    case "$type" in
        "mod_name")
            # Remove dangerous characters and limit length
            echo "$input" | sed 's/[^a-zA-Z0-9._-]//g' | head -c 50
            ;;
        "version")
            # Validate semantic version format
            if [[ "$input" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                echo "$input"
            else
                echo ""
            fi
            ;;
        "number")
            # Validate numeric input
            if [[ "$input" =~ ^[0-9]+$ ]]; then
                echo "$input"
            else
                echo ""
            fi
            ;;
        "search_term")
            # Sanitize search terms
            echo "$input" | sed 's/[^a-zA-Z0-9._ -]//g' | head -c 100
            ;;
        *)
            # Default sanitization
            echo "$input" | sed 's/[^a-zA-Z0-9._-]//g' | head -c 100
            ;;
    esac
}

# Function to check if required tools are available
check_dependencies() {
    local missing_tools=()
    
    for tool in curl unzip file awk sed grep cut tr wc mktemp; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -gt 0 ]; then
        echo -e "${RED}Error: Missing required tools: ${missing_tools[*]}${NC}"
        echo "Please install the missing tools and try again."
        exit 1
    fi
}

# Function to check network connectivity
check_network() {
    if ! ping -c 1 thunderstore.io >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning: Cannot reach thunderstore.io. Network connectivity issues may cause download failures.${NC}"
        read -p "Continue anyway? (y/N): " continue_anyway
        if [[ ! $continue_anyway =~ ^[Yy]$ ]]; then
            echo "Exiting due to network connectivity issues."
            exit 1
        fi
    fi
}

# Function to check disk space
check_disk_space() {
    local required_space_mb=100  # Minimum 100MB
    local available_space_mb=$(df /tmp | awk 'NR==2 {print int($4/1024)}')
    
    if [ "$available_space_mb" -lt "$required_space_mb" ]; then
        echo -e "${RED}Error: Insufficient disk space. Required: ${required_space_mb}MB, Available: ${available_space_mb}MB${NC}"
        echo "Please free up disk space and try again."
        exit 1
    fi
}

# Welcome message
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Mod Rollback Tool for r2modmanPlus${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "This script will help you rollback any installed mod to a previous version."
echo ""

# Initialize logging
log_message "INFO" "Mod rollback script started"
log_message "INFO" "Log file: $LOG_FILE"

# Check dependencies first (skip if environment variable is set)
if [ "$SKIP_DEPENDENCY_CHECK" != "true" ]; then
    echo "Checking dependencies..."
    check_dependencies
    log_message "INFO" "All required dependencies found"
else
    echo "Skipping dependency check (SKIP_DEPENDENCY_CHECK=true)"
    log_message "INFO" "Dependency check skipped"
fi

# Network and disk checks are handled in the dependency check function

# Check if we can run sudo commands (skip if environment variable is set)
if [ "$SKIP_DEPENDENCY_CHECK" != "true" ]; then
    if ! sudo -n true 2>/dev/null; then
        echo "This script needs sudo privileges to install dependencies."
        echo ""
        echo "If this is your first time using sudo on SteamOS, you'll be prompted to:"
        echo "1. Set a new sudo password (if not already set)"
        echo "2. Enter that password to authenticate"
        echo ""
        echo "Note: The password you type will not be visible on screen for security."
        echo ""
        read -p "Press Enter to continue or Ctrl+C to cancel..."
        echo ""
        
        # Test sudo with password prompt
        echo "Authenticating with sudo..."
        if ! sudo -v; then
            echo ""
            echo "Sudo authentication failed. This could be because:"
            echo "- You entered the wrong password"
            echo "- You cancelled the password prompt"
            echo "- There was an issue setting up sudo for the first time"
            echo ""
            echo "Please try running the script again."
            exit 1
        fi
        echo "Sudo authentication successful!"
        echo ""
    fi
else
    echo "Skipping sudo check (SKIP_DEPENDENCY_CHECK=true)"
fi

# Disable SteamOS read-only mode for package installation (skip if environment variable is set)
if [ "$SKIP_DEPENDENCY_CHECK" != "true" ]; then
    echo "Disabling SteamOS read-only mode..."
    if sudo steamos-readonly disable; then
        echo "Read-only mode disabled successfully."
        readonly_disabled=true
    else
        echo "Warning: Could not disable read-only mode. Installation may fail."
        readonly_disabled=false
    fi
    echo ""
else
    echo "Skipping SteamOS read-only mode changes (SKIP_DEPENDENCY_CHECK=true)"
    readonly_disabled=false
fi

# Check if mods.yml exists
if [ ! -f "$MODS_YML" ]; then
    echo -e "${RED}Error: r2modmanPlus mods.yml not found at:${NC}"
    echo "$MODS_YML"
    echo ""
    echo "Please make sure r2modmanPlus is properly installed and configured."
    exit 1
fi

# Function to extract mod information from mods.yml
extract_mod_info() {
    local mod_name="$1"
    local yml_file="$2"
    
    # Use awk to extract mod information
    awk -v target="$mod_name" '
    BEGIN { in_mod = 0; found = 0 }
    /^- manifestVersion:/ { in_mod = 1; current_mod = "" }
    /^  name:/ { 
        gsub(/^  name: /, ""); 
        gsub(/"/, ""); 
        current_mod = $0 
    }
    /^  authorName:/ { 
        if (in_mod && current_mod == target) {
            gsub(/^  authorName: /, ""); 
            gsub(/"/, ""); 
            author = $0 
        }
    }
    /^  versionNumber:/ { 
        if (in_mod && current_mod == target) {
            version_section = 1 
        }
    }
    /^    major:/ { 
        if (in_mod && current_mod == target && version_section) {
            gsub(/^    major: /, ""); 
            major = $0 
        }
    }
    /^    minor:/ { 
        if (in_mod && current_mod == target && version_section) {
            gsub(/^    minor: /, ""); 
            minor = $0 
        }
    }
    /^    patch:/ { 
        if (in_mod && current_mod == target && version_section) {
            gsub(/^    patch: /, ""); 
            patch = $0 
        }
    }
    /^  enabled:/ { 
        if (in_mod && current_mod == target) {
            gsub(/^  enabled: /, ""); 
            enabled = $0 
        }
    }
    /^  installMode:/ { 
        if (in_mod && current_mod == target) {
            gsub(/^  installMode: /, ""); 
            install_mode = $0 
        }
    }
    /^[^-]/ && !/^  / { 
        if (in_mod && current_mod == target) {
            found = 1
            print current_mod "|" author "|" major "." minor "." patch "|" enabled "|" install_mode
            exit
        }
        in_mod = 0
        version_section = 0
    }
    END { 
        if (in_mod && current_mod == target) {
            found = 1
            print current_mod "|" author "|" major "." minor "." patch "|" enabled "|" install_mode
        }
        if (!found) exit 1
    }
    ' "$yml_file"
}

# Function to list all installed mods
list_installed_mods() {
    echo -e "${BLUE}Installed Mods:${NC}"
    echo ""
    
    # Check if plugin directory exists
    if [ ! -d "$MOD_PLUGIN_PATH" ]; then
        echo -e "${RED}Plugin directory not found: $MOD_PLUGIN_PATH${NC}"
        echo "Please make sure r2modmanPlus is properly installed."
        exit 1
    fi
    
    # List all mod directories
    local mod_count=0
    for mod_dir in "$MOD_PLUGIN_PATH"/*; do
        if [ -d "$mod_dir" ]; then
            mod_count=$((mod_count + 1))
            local mod_name=$(basename "$mod_dir")
            # Extract author and mod name from directory name (format: AUTHOR-MODNAME)
            local author=$(echo "$mod_name" | cut -d'-' -f1)
            local display_name=$(echo "$mod_name" | cut -d'-' -f2-)
            
            # Try to get version from manifest.json if it exists
            local version="Unknown"
            if [ -f "$mod_dir/manifest.json" ]; then
                version=$(grep '"version_number"' "$mod_dir/manifest.json" 2>/dev/null | sed 's/.*"version_number": *"\([^"]*\)".*/\1/' || echo "Unknown")
            fi
            
            printf "%2d. %-30s by %-20s (v%s)\n" "$mod_count" "$mod_name" "$author" "$version"
        fi
    done
    
    if [ $mod_count -eq 0 ]; then
        echo "No mods found in plugin directory."
        exit 1
    fi
}

# Function to search for mods by name (fuzzy matching)
search_mods() {
    local search_term="$1"
    
    # Convert search term to lowercase for case-insensitive matching
    local search_lower=$(echo "$search_term" | tr '[:upper:]' '[:lower:]')
    local found_any=false
    
    # Search through plugin directories (same as list_installed_mods)
    if [ -d "$MOD_PLUGIN_PATH" ]; then
        for mod_dir in "$MOD_PLUGIN_PATH"/*; do
            if [ -d "$mod_dir" ]; then
                local mod_name=$(basename "$mod_dir")
                local mod_name_lower=$(echo "$mod_name" | tr '[:upper:]' '[:lower:]')
                
                # Check if mod name contains search term
                if [[ "$mod_name_lower" == *"$search_lower"* ]]; then
                    local author=$(echo "$mod_name" | cut -d'-' -f1)
                    local version="Unknown"
                    
                    # Try to get version from manifest.json if it exists
                    if [ -f "$mod_dir/manifest.json" ]; then
                        version=$(grep '"version_number"' "$mod_dir/manifest.json" 2>/dev/null | sed 's/.*"version_number": *"\([^"]*\)".*/\1/' || echo "Unknown")
                    fi
                    
                    echo "$mod_name|$author|$version"
                    found_any=true
                fi
            fi
        done
    fi
    
    if [ "$found_any" = false ]; then
        return 1
    fi
}

# Function to list all mods to a file
list_all_mods_to_file() {
    local output_file="$1"
    
    # List all mod directories to file
    for mod_dir in "$MOD_PLUGIN_PATH"/*; do
        if [ -d "$mod_dir" ]; then
            local mod_name=$(basename "$mod_dir")
            local author=$(echo "$mod_name" | cut -d'-' -f1)
            local version="Unknown"
            
            # Try to get version from manifest.json if it exists
            if [ -f "$mod_dir/manifest.json" ]; then
                version=$(grep '"version_number"' "$mod_dir/manifest.json" 2>/dev/null | sed 's/.*"version_number": *"\([^"]*\)".*/\1/' || echo "Unknown")
            fi
            
            echo "$mod_name|$author|$version" >> "$output_file"
        fi
    done
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
            echo ""
            echo "Available mods:"
            # Show all mods without the header
            list_all_mods_to_file "$temp_file"
            local display_count=0
            while IFS='|' read -r name author version; do
                display_count=$((display_count + 1))
                printf "%2d. %-30s by %-20s (v%s)\n" "$display_count" "$name" "$author" "$version"
            done < "$temp_file"
            echo ""
            read -p "Enter a mod name to search for (or press Enter to see all): " new_search
            if [ -n "$new_search" ]; then
                if ! search_mods "$new_search" > "$temp_file"; then
                    echo -e "${RED}No mods found matching '$new_search'${NC}"
                    rm "$temp_file"
                    exit 1
                fi
            else
                # Show all mods
                list_all_mods_to_file "$temp_file"
            fi
        fi
    else
        # Show all mods
        list_all_mods_to_file "$temp_file"
    fi
    
    # Count mods in temp file
    local mod_count=$(wc -l < "$temp_file")
    
    if [ "$mod_count" -eq 0 ]; then
        echo -e "${RED}No mods found.${NC}"
        rm "$temp_file"
        exit 1
    fi
    
    # Display mods
    echo -e "${BLUE}Search Results:${NC}"
    echo ""
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
    echo "Rollback options:"
    echo "1. Previous patch version (e.g., 1.4.8 → 1.4.7)"
    echo "2. Previous minor version (e.g., 1.4.8 → 1.3.0)"
    echo "3. Previous major version (e.g., 1.4.8 → 0.0.0)"
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
            local major=$(echo $current_version | cut -d. -f1)
            local minor=$(echo $current_version | cut -d. -f2)
            local patch=$(echo $current_version | cut -d. -f3)
            local new_patch=$((patch - 1))
            if [ $new_patch -lt 0 ]; then
                echo -e "${RED}Error: Cannot rollback patch version below 0${NC}"
                exit 1
            fi
            rollback_version="${major}.${minor}.${new_patch}"
            ;;
        2)
            # Previous minor version
            local major=$(echo $current_version | cut -d. -f1)
            local minor=$(echo $current_version | cut -d. -f2)
            local new_minor=$((minor - 1))
            if [ $new_minor -lt 0 ]; then
                echo -e "${RED}Error: Cannot rollback minor version below 0${NC}"
                exit 1
            fi
            rollback_version="${major}.${new_minor}.0"
            ;;
        3)
            # Previous major version
            local major=$(echo $current_version | cut -d. -f1)
            local new_major=$((major - 1))
            if [ $new_major -lt 0 ]; then
                echo -e "${RED}Error: Cannot rollback major version below 0${NC}"
                exit 1
            fi
            rollback_version="${new_major}.0.0"
            ;;
        4)
            # Custom version
            read -p "Enter the version to rollback to (e.g., 1.3.5): " custom_version
            custom_version=$(validate_input "$custom_version" "version")
            if [ -z "$custom_version" ]; then
                echo -e "${RED}Error: Invalid version format. Please use format like 1.3.5${NC}"
                log_message "ERROR" "Invalid custom version format: $custom_version"
                exit 1
            fi
            rollback_version="$custom_version"
            ;;
    esac
}

# Function to generate Thunderstore download URL
generate_download_url() {
    local mod_name="$1"
    local author="$2"
    local version="$3"
    
    # Convert mod name to package name format
    # Example: "BULLETBOT-MoreUpgrades" -> "BULLETBOT/MoreUpgrades"
    local package_name=$(echo "$mod_name" | sed 's/-/\//')
    
    echo "${THUNDERSTORE_BASE_URL}/${package_name}/${version}/"
}

# Function to download and install mod
download_and_install_mod() {
    local mod_name="$1"
    local download_url="$2"
    local target_version="$3"
    
    local temp_dir="/tmp/${mod_name}_rollback"
    local zip_file="${temp_dir}/${mod_name}.zip"
    
    echo ""
    echo -e "${BLUE}Downloading mod version $target_version...${NC}"
    
    # Create temp directory
    mkdir -p "$temp_dir"
    
    # Download mod
    log_message "INFO" "Downloading mod from: $download_url"
    if curl -L -o "$zip_file" "$download_url"; then
        echo -e "${GREEN}Download completed successfully!${NC}"
        log_message "INFO" "Download completed successfully"
    else
        echo -e "${RED}Failed to download mod. The version may not exist.${NC}"
        echo "URL attempted: $download_url"
        log_message "ERROR" "Download failed for URL: $download_url"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Check if downloaded file is a zip file
    local file_type=$(file "$zip_file")
    log_message "INFO" "Downloaded file type: $file_type"
    
    if echo "$file_type" | grep -q "Zip archive"; then
        # Extract mod
        echo "Extracting mod files..."
        log_message "INFO" "Extracting zip file: $zip_file"
        if unzip "$zip_file" -d "$temp_dir"; then
            echo -e "${GREEN}Extraction completed successfully!${NC}"
            log_message "INFO" "Zip extraction completed successfully"
        else
            echo -e "${RED}Failed to extract mod. The downloaded file may be corrupted.${NC}"
            log_message "ERROR" "Zip extraction failed for file: $zip_file"
            rm -rf "$temp_dir"
            exit 1
        fi
        
        # Remove zip file
        rm "$zip_file"
    else
        # File is not a zip, it's already extracted content
        echo "Downloaded file is not a zip archive, treating as extracted content..."
        log_message "INFO" "File is not a zip archive, treating as extracted content"
        # Move the downloaded file to the temp directory
        mv "$zip_file" "${temp_dir}/"
    fi
    
    # Install mod files
    local mod_install_path="${MOD_PLUGIN_PATH}/${mod_name}"
    echo "Installing mod to: $mod_install_path"
    
    # Remove existing mod files
    if [ -d "$mod_install_path" ]; then
        echo -e "${YELLOW}Warning: Existing mod files will be removed from: $mod_install_path${NC}"
        echo "This will permanently delete the current version of the mod."
        read -p "Continue with removal? (y/N): " confirm_removal
        if [[ ! $confirm_removal =~ ^[Yy]$ ]]; then
            echo "Installation cancelled by user."
            log_message "INFO" "Installation cancelled by user - removal not confirmed"
            rm -rf "$temp_dir"
            exit 0
        fi
        echo "Removing existing mod files..."
        log_message "INFO" "Removing existing mod files from: $mod_install_path"
        rm -rf "$mod_install_path"
    fi
    
    # Create new mod directory
    mkdir -p "$mod_install_path"
    
    # Copy new mod files
    if cp -r "$temp_dir"/* "$mod_install_path/"; then
        echo -e "${GREEN}Mod installed successfully!${NC}"
    else
        echo -e "${RED}Failed to install mod files.${NC}"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    # Cleanup temp directory
    rm -rf "$temp_dir"
}

# Function to clean and validate mods.yml file
clean_mods_yml() {
    local mods_yml="$1"
    
    echo ""
    echo -e "${BLUE}Checking and cleaning mods.yml file...${NC}"
    
    # Check if file exists
    if [ ! -f "$mods_yml" ]; then
        echo -e "${RED}Error: mods.yml file not found at: $mods_yml${NC}"
        log_message "ERROR" "mods.yml file not found at: $mods_yml"
        return 1
    fi
    
    # Create backup before cleaning
    local backup_file="${mods_yml}.backup.$(date +%s)"
    if cp "$mods_yml" "$backup_file"; then
        echo "Backup created: $backup_file"
        log_message "INFO" "Backup created: $backup_file"
    else
        echo -e "${YELLOW}Warning: Could not create backup of mods.yml${NC}"
        log_message "WARN" "Could not create backup of mods.yml"
    fi
    
    # Check for null bytes
    if grep -q $'\0' "$mods_yml"; then
        echo -e "${YELLOW}Found null bytes in mods.yml, cleaning...${NC}"
        log_message "WARN" "Found null bytes in mods.yml, cleaning..."
        
        # Clean null bytes and re-serialize YAML with robust error recovery
        python3 -c "
import yaml
import sys
import re

def fix_yaml_structure(content):
    '''Fix common YAML structural issues in mods.yml'''
    lines = content.split('\n')
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Skip empty lines
        if not line.strip():
            fixed_lines.append(line)
            i += 1
            continue
            
        # Check for malformed mod entries
        # Pattern 1: Line starts with '- authorName:' (missing manifestVersion and name)
        if line.strip().startswith('- authorName:'):
            # Find the mod name by looking at the previous non-empty line or next few lines
            mod_name = None
            
            # Look backwards for a potential mod name
            for j in range(i-1, max(0, i-5), -1):
                if lines[j].strip() and not lines[j].startswith('  ') and not lines[j].startswith('- '):
                    mod_name = lines[j].strip()
                    break
            
            # If no name found, look forward for a pattern
            if not mod_name:
                for j in range(i+1, min(len(lines), i+10)):
                    if lines[j].strip() and not lines[j].startswith('  ') and not lines[j].startswith('- '):
                        # Check if this looks like a mod name (contains hyphen)
                        if '-' in lines[j].strip():
                            mod_name = lines[j].strip()
                            break
            
            if mod_name:
                fixed_lines.append('- manifestVersion: 1')
                fixed_lines.append(f'  name: {mod_name}')
                fixed_lines.append('  ' + line.strip()[2:])  # Add the authorName line with proper indentation
                print(f'Fixed malformed entry for: {mod_name}')
            else:
                # Fallback: create a generic entry
                fixed_lines.append('- manifestVersion: 1')
                fixed_lines.append('  name: Unknown-Mod')
                fixed_lines.append('  ' + line.strip()[2:])
                print('Fixed malformed entry with generic name')
        
        # Pattern 2: Line that should be a name field but is missing proper structure
        elif (line.strip() and 
              not line.startswith('  ') and 
              not line.startswith('- ') and
              not line.startswith('#') and
              i + 1 < len(lines) and
              lines[i + 1].strip().startswith('authorName:')):
            
            mod_name = line.strip()
            fixed_lines.append('- manifestVersion: 1')
            fixed_lines.append(f'  name: {mod_name}')
            print(f'Fixed missing name field for: {mod_name}')
        
        # Pattern 3: Line that starts with '-' but is not properly formatted
        elif (line.strip().startswith('- ') and 
              not line.strip().startswith('- manifestVersion:') and
              not line.strip().startswith('- name:') and
              i + 1 < len(lines) and
              lines[i + 1].strip().startswith('authorName:')):
            
            mod_name = line.strip()[2:]  # Remove the '- ' prefix
            fixed_lines.append('- manifestVersion: 1')
            fixed_lines.append(f'  name: {mod_name}')
            print(f'Fixed malformed entry for: {mod_name}')
        
        else:
            fixed_lines.append(line)
        
        i += 1
    
    return '\n'.join(fixed_lines)

try:
    with open('$mods_yml', 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
        # Remove null bytes and other problematic characters
        content = content.replace('\x00', '')
        content = content.replace('\u0000', '')
        # Remove any remaining control characters except newlines and tabs
        import re
        content = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', content)
    
    # Try to parse the YAML
    try:
        data = yaml.safe_load(content)
        print('✅ YAML parsed successfully without fixes needed')
    except yaml.YAMLError as e:
        print(f'⚠️  YAML parsing failed, attempting to fix structure: {e}')
        
        # Fix the structure
        fixed_content = fix_yaml_structure(content)
        
        # Try to parse the fixed content
        try:
            data = yaml.safe_load(fixed_content)
            content = fixed_content  # Use the fixed content
            print('✅ Successfully fixed YAML structure')
        except yaml.YAMLError as e2:
            print(f'❌ Still unable to parse YAML after fixes: {e2}')
            sys.exit(1)
    
    # Write back clean YAML
    with open('$mods_yml', 'w') as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
    
    print('✅ Successfully cleaned mods.yml of null bytes and re-serialized')
    
except Exception as e:
    print(f'❌ Error cleaning mods.yml: {e}')
    sys.exit(1)
" || {
            echo -e "${RED}Failed to clean mods.yml${NC}"
            log_message "ERROR" "Failed to clean mods.yml"
            return 1
        }
    else
        echo "✅ No null bytes found in mods.yml"
        log_message "INFO" "No null bytes found in mods.yml"
    fi
    
    # Validate YAML syntax
    echo "Validating YAML syntax..."
    if python3 -c "
import yaml
try:
    with open('$mods_yml', 'r') as f:
        yaml.safe_load(f)
    print('✅ YAML syntax is valid')
except yaml.YAMLError as e:
    print(f'❌ YAML syntax error: {e}')
    exit(1)
except Exception as e:
    print(f'❌ Error validating YAML: {e}')
    exit(1)
"; then
        echo -e "${GREEN}mods.yml is clean and valid${NC}"
        log_message "INFO" "mods.yml is clean and valid"
        return 0
    else
        echo -e "${RED}mods.yml has syntax errors${NC}"
        log_message "ERROR" "mods.yml has syntax errors"
        return 1
    fi
}

# Function to update mod registry
update_mod_registry() {
    local mod_name="$1"
    local author="$2"
    local old_version="$3"
    local new_version="$4"
    local mods_yml="$5"
    
    echo ""
    echo -e "${BLUE}Updating mod registry...${NC}"
    
    # Create backup of mods.yml before making changes
    local backup_file="${mods_yml}.backup.$(date +%s)"
    if cp "$mods_yml" "$backup_file"; then
        echo "Backup created: $backup_file"
        log_message "INFO" "Backup created: $backup_file"
    else
        echo -e "${YELLOW}Warning: Could not create backup of mods.yml${NC}"
        log_message "WARN" "Could not create backup of mods.yml"
    fi
    
    # Extract version components
    local major_version=$(echo $new_version | cut -d. -f1)
    local minor_version=$(echo $new_version | cut -d. -f2)
    local patch_version=$(echo $new_version | cut -d. -f3)
    
    # Get current timestamp in milliseconds
    local timestamp=$(date +%s)000
    
    # Create new mod entry
    local new_mod_entry="
- manifestVersion: 1
  name: \"$mod_name\"
  authorName: \"$author\"
  websiteUrl: \"https://thunderstore.io/c/repo/p/${mod_name//-//}/\"
  displayName: \"${mod_name##*-}\"
  description: \"Rolled back to version $new_version\"
  gameVersion: \"0\"
  networkMode: both
  packageType: other
  installMode: unmanaged
  installedAtTime: $timestamp
  loaders: []
  dependencies: []
  incompatibilities: []
  optionalDependencies: []
  versionNumber:
    major: $major_version
    minor: $minor_version
    patch: $patch_version
  enabled: true
  icon: \"${MOD_PLUGIN_PATH}/${mod_name}/icon.png\""

    # Create backup of mods.yml
    cp "$mods_yml" "${mods_yml}.backup.$(date +%s)"
    
    # Remove old entry and add new one
    # This is a simplified approach - in production you'd want more sophisticated YAML manipulation
    awk -v target="$mod_name" -v new_entry="$new_mod_entry" '
    BEGIN { 
        in_target_mod = 0
        skip_until_next_mod = 0
        entry_added = 0
    }
    /^- manifestVersion:/ { 
        if (skip_until_next_mod) {
            skip_until_next_mod = 0
        }
        in_mod = 1
    }
    /^  name:/ { 
        gsub(/^  name: /, ""); 
        gsub(/"/, ""); 
        current_mod = $0
        if (current_mod == target) {
            in_target_mod = 1
            skip_until_next_mod = 1
            next
        }
    }
    /^[^-]/ && !/^  / { 
        if (in_target_mod && !entry_added) {
            print new_entry
            entry_added = 1
        }
        in_mod = 0
        in_target_mod = 0
    }
    !skip_until_next_mod { print }
    END {
        if (!entry_added) {
            print new_entry
        }
    }
    ' "$mods_yml" > "${mods_yml}.tmp" && mv "${mods_yml}.tmp" "$mods_yml"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Mod registry updated successfully!${NC}"
        log_message "INFO" "Mod registry updated successfully for $mod_name"
        
        # Clean up the mods.yml file after writing to prevent corruption
        echo "Cleaning up mods.yml after registry update..."
        if clean_mods_yml "$mods_yml"; then
            echo -e "${GREEN}mods.yml cleaned and validated after update${NC}"
            log_message "INFO" "mods.yml cleaned and validated after registry update"
        else
            echo -e "${YELLOW}Warning: Could not clean mods.yml after update${NC}"
            log_message "WARN" "Could not clean mods.yml after registry update"
        fi
    else
        echo -e "${RED}Failed to update mod registry!${NC}"
        log_message "ERROR" "Failed to update mod registry for $mod_name"
        # Restore from backup if update failed
        if [ -f "$backup_file" ]; then
            cp "$backup_file" "$mods_yml"
            echo "Registry restored from backup."
            log_message "INFO" "Registry restored from backup: $backup_file"
        fi
        exit 1
    fi
}

# Parse command line arguments
SEARCH_TERM=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS] [SEARCH_TERM]"
            echo ""
            echo "Options:"
            echo "  -v, --verbose    Enable verbose logging"
            echo "  -h, --help       Show this help message"
            echo ""
            echo "Arguments:"
            echo "  SEARCH_TERM      Optional search term to filter mods"
            echo ""
            echo "Examples:"
            echo "  $0                    # Show all mods"
            echo "  $0 MoreUpgrades       # Search for mods containing 'MoreUpgrades'"
            echo "  $0 -v BULLETBOT       # Verbose mode with search"
            exit 0
            ;;
        *)
            if [ -z "$SEARCH_TERM" ]; then
                SEARCH_TERM=$(validate_input "$1" "search_term")
                if [ -z "$SEARCH_TERM" ]; then
                    echo -e "${YELLOW}Warning: Invalid search term provided, ignoring: '$1'${NC}"
                    log_message "WARN" "Invalid search term provided: $1"
                else
                    echo -e "${BLUE}Search term provided: '$SEARCH_TERM'${NC}"
                    log_message "INFO" "Search term from command line: $SEARCH_TERM"
                fi
            fi
            shift
            ;;
    esac
done

# Main execution
echo "Checking installed mods..."

# Check if plugin directory exists first
if [ ! -d "$MOD_PLUGIN_PATH" ]; then
    echo -e "${RED}Plugin directory not found: $MOD_PLUGIN_PATH${NC}"
    echo "Please make sure r2modmanPlus is properly installed."
    exit 1
fi

# Count total mods to verify installation
mod_count=$(find "$MOD_PLUGIN_PATH" -maxdepth 1 -type d | wc -l)
if [ $mod_count -le 1 ]; then
    echo -e "${RED}No mods found in plugin directory.${NC}"
    echo "Please install some mods first using r2modmanPlus."
    exit 1
fi

# Clean and validate mods.yml file before proceeding
MODS_YML="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml"
if [ -f "$MODS_YML" ]; then
    clean_mods_yml "$MODS_YML"
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to clean mods.yml file. Please check the file manually.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}Warning: mods.yml not found at $MODS_YML${NC}"
    echo "Registry updates will be skipped."
fi

# Get mod selection from user (this will show filtered results)
get_mod_selection "$SEARCH_TERM"
IFS='|' read -r selected_mod selected_author current_version <<< "$mod_info"

# Get rollback version
get_rollback_version "$current_version" "$selected_mod"

echo ""
echo -e "${YELLOW}Rollback Summary:${NC}"
echo -e "Mod: ${GREEN}$selected_mod${NC}"
echo -e "From: ${RED}$current_version${NC}"
echo -e "To: ${GREEN}$rollback_version${NC}"
echo ""

echo -e "${YELLOW}This will:${NC}"
echo "1. Download the mod version $rollback_version"
echo "2. Remove the current version ($current_version) from your system"
echo "3. Install the new version"
echo "4. Update the r2modmanPlus registry"
echo ""
echo -e "${RED}Warning: This action cannot be undone!${NC}"
read -p "Proceed with rollback? (y/N): " confirm
if [[ ! $confirm =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled."
    log_message "INFO" "Rollback cancelled by user"
    exit 0
fi
log_message "INFO" "User confirmed rollback operation"

# Generate download URL
download_url=$(generate_download_url "$selected_mod" "$selected_author" "$rollback_version")
echo "Download URL: $download_url"

# Download and install mod
download_and_install_mod "$selected_mod" "$download_url" "$rollback_version"

# Update registry
update_mod_registry "$selected_mod" "$selected_author" "$current_version" "$rollback_version" "$MODS_YML"

echo ""
echo -e "${GREEN}==========================================${NC}"
echo -e "${GREEN}  Rollback Complete!${NC}"
echo -e "${GREEN}==========================================${NC}"
echo ""
echo -e "${GREEN}$selected_mod${NC} has been successfully rolled back from ${RED}$current_version${NC} to ${GREEN}$rollback_version${NC}"
echo ""
echo "The mod has been updated in r2modmanPlus and should appear with the new version."
echo "You can now launch your game with r2modmanPlus to use the rolled back mod."
echo ""

# Final logging
log_message "INFO" "Rollback completed successfully"
log_message "INFO" "Mod: $selected_mod, From: $current_version, To: $rollback_version"
log_message "INFO" "Log file location: $LOG_FILE"

if [ "$VERBOSE" = true ]; then
    echo -e "${BLUE}Verbose logging was enabled. Log file: $LOG_FILE${NC}"
fi

exit 0

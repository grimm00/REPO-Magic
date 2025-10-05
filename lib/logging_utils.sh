#!/bin/bash

# Logging Utilities Library
# Provides logging and validation functions

# Define colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Global variables for logging
LOG_FILE=""
VERBOSE=false

# Function to initialize logging
init_logging() {
    local script_name="$1"
    local verbose="$2"
    
    VERBOSE="$verbose"
    LOG_FILE="/tmp/${script_name}.log"
    
    # Create log file
    touch "$LOG_FILE"
    
    if [ "$VERBOSE" = true ]; then
        echo "Logging to: $LOG_FILE"
    fi
}

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [ "$VERBOSE" = true ]; then
        case $level in
            "ERROR")
                echo -e "${RED}[$timestamp] [$level] $message${NC}"
                ;;
            "WARN")
                echo -e "${YELLOW}[$timestamp] [$level] $message${NC}"
                ;;
            "INFO")
                echo -e "${BLUE}[$timestamp] [$level] $message${NC}"
                ;;
            *)
                echo "[$timestamp] [$level] $message"
                ;;
        esac
    fi
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

# Function to confirm action
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        read -p "$message (Y/n): " response
        response="${response:-y}"
    else
        read -p "$message (y/N): " response
        response="${response:-n}"
    fi
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to show progress
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    
    printf "\r${message} ["
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' ' '
    printf "] %d%% (%d/%d)" "$percent" "$current" "$total"
    
    if [ "$current" -eq "$total" ]; then
        echo ""
    fi
}

# Function to check if command exists
command_exists() {
    local cmd="$1"
    command -v "$cmd" >/dev/null 2>&1
}

# Function to get script directory
get_script_dir() {
    local script_path="$1"
    dirname "$(realpath "$script_path")"
}

# Function to create backup
create_backup() {
    local file="$1"
    local backup_dir="${2:-$(dirname "$file")}"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        return 1
    fi
    
    local backup_file="${backup_dir}/$(basename "$file").backup.$(date +%s)"
    
    if cp "$file" "$backup_file"; then
        echo "Backup created: $backup_file"
        log_message "INFO" "Backup created: $backup_file"
        echo "$backup_file"
        return 0
    else
        echo -e "${RED}Failed to create backup of $file${NC}"
        log_message "ERROR" "Failed to create backup of $file"
        return 1
    fi
}

# Function to restore from backup
restore_backup() {
    local backup_file="$1"
    local target_file="$2"
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Error: Backup file not found: $backup_file${NC}"
        return 1
    fi
    
    if cp "$backup_file" "$target_file"; then
        echo "Restored from backup: $backup_file"
        log_message "INFO" "Restored from backup: $backup_file"
        return 0
    else
        echo -e "${RED}Failed to restore from backup: $backup_file${NC}"
        log_message "ERROR" "Failed to restore from backup: $backup_file"
        return 1
    fi
}

# Function to cleanup on exit
cleanup_on_exit() {
    local temp_files=("$@")
    
    for file in "${temp_files[@]}"; do
        if [ -f "$file" ]; then
            rm -f "$file"
            log_message "INFO" "Cleaned up temporary file: $file"
        fi
    done
}

# Function to check file permissions
check_file_permissions() {
    local file="$1"
    local required_perms="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        return 1
    fi
    
    local current_perms=$(stat -c "%a" "$file")
    
    if [ "$current_perms" = "$required_perms" ]; then
        return 0
    else
        echo -e "${YELLOW}Warning: File permissions mismatch for $file (current: $current_perms, required: $required_perms)${NC}"
        log_message "WARN" "File permissions mismatch for $file (current: $current_perms, required: $required_perms)"
        return 1
    fi
}

# Function to set file permissions
set_file_permissions() {
    local file="$1"
    local perms="$2"
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}Error: File not found: $file${NC}"
        return 1
    fi
    
    if chmod "$perms" "$file"; then
        echo "Set permissions $perms for $file"
        log_message "INFO" "Set permissions $perms for $file"
        return 0
    else
        echo -e "${RED}Failed to set permissions $perms for $file${NC}"
        log_message "ERROR" "Failed to set permissions $perms for $file"
        return 1
    fi
}

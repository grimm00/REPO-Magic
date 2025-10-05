#!/bin/bash

# Profile Utilities Library
# Provides shared functions for r2modmanPlus profile resolution and path management

# Define colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to get the base profiles directory
get_profiles_base() {
    echo "${R2MODMAN_BASE:-$HOME/.config/r2modmanPlus-local}/REPO/profiles"
}

# Function to sanitize and validate profile name
sanitize_profile_name() {
    local name="$1"
    
    # Check for empty input
    if [ -z "$name" ]; then
        echo "Default"
        return 0
    fi
    
    # Remove dangerous characters and patterns
    if [[ "$name" =~ \.\. ]] || [[ "$name" =~ / ]] || [[ "$name" =~ \\ ]]; then
        echo "Error: Profile name contains path traversal characters" >&2
        exit 1
    fi
    
    # Check for leading dash (could be interpreted as flag)
    if [[ "$name" =~ ^- ]]; then
        echo "Error: Profile name cannot start with '-'" >&2
        exit 1
    fi
    
    # Validate allowed characters: A-Z, a-z, 0-9, ., _, space, -
    if [[ ! "$name" =~ ^[A-Za-z0-9._\ -]+$ ]]; then
        echo "Error: Profile name contains invalid characters" >&2
        exit 1
    fi
    
    # Limit length
    if [ ${#name} -gt 50 ]; then
        echo "Error: Profile name too long (max 50 characters)" >&2
        exit 1
    fi
    
    # Trim whitespace
    name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    echo "$name"
}

# Function to resolve profile and set derived paths
resolve_profile() {
    local input_profile="$1"
    
    # Sanitize the profile name
    PROFILE_NAME=$(sanitize_profile_name "$input_profile")
    
    # Get profiles base path
    local profiles_base=$(get_profiles_base)
    PROFILE_PATH="$profiles_base/$PROFILE_NAME"
    
    # Check if profile directory exists
    if [ ! -d "$PROFILE_PATH" ]; then
        echo -e "${YELLOW}Profile '$PROFILE_NAME' not found under $profiles_base${NC}"
        if [ "$PROFILE_NAME" != "Default" ] && [ -d "$profiles_base/Default" ]; then
            echo -e "${YELLOW}Falling back to 'Default' profile${NC}"
            PROFILE_NAME="Default"
            PROFILE_PATH="$profiles_base/Default"
        else
            echo -e "${YELLOW}Proceeding with profile path even if not present (it may be created on first run)${NC}"
        fi
    fi
    
    # Set derived paths
    export MOD_PLUGIN_PATH="$PROFILE_PATH/BepInEx/plugins"
    MODS_YML="$PROFILE_PATH/mods.yml"
    
    # Print profile information
    echo -e "${BLUE}Using profile:${NC} $PROFILE_NAME"
    echo -e "${BLUE}Plugins path:${NC} $MOD_PLUGIN_PATH"
    echo -e "${BLUE}mods.yml path:${NC} $MODS_YML"
}

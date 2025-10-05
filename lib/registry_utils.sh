#!/bin/bash

# Registry Utilities Library
# Provides functions for updating r2modmanPlus mod registry using jq

# Define colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to update mod registry with new version using jq
update_mod_registry() {
    local mod_name="$1"
    local author="$2"
    local old_version="$3"
    local new_version="$4"
    local mods_yml="$5"
    
    echo ""
    echo -e "${BLUE}Updating mod registry using jq...${NC}"
    log_message "INFO" "Updating mod registry for $mod_name to version $new_version using jq"
    
    # Extract version components
    local major_version=$(echo $new_version | cut -d. -f1)
    local minor_version=$(echo $new_version | cut -d. -f2)
    local patch_version=$(echo $new_version | cut -d. -f3)
    
    # Create backup of mods_yml before making changes
    local backup_file="${mods_yml}.backup.$(date +%s)"
    if cp "$mods_yml" "$backup_file"; then
        echo "Backup created: $backup_file"
        log_message "INFO" "Backup created: $backup_file"
    else
        echo -e "${YELLOW}Warning: Could not create backup of mods.yml${NC}"
        log_message "WARN" "Could not create backup of mods.yml"
    fi
    
    # Use jq for robust YAML manipulation
    echo "Using jq for registry update..."
    python3 -c "
import yaml
import json
import subprocess
import sys
import tempfile
import os

try:
    # Read and clean the YAML file
    with open('$mods_yml', 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
        # Remove null bytes and control characters
        content = content.replace('\x00', '')
        content = content.replace('\u0000', '')
        import re
        content = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', content)
    
    # Parse YAML
    data = yaml.safe_load(content)
    if not isinstance(data, list):
        print('❌ Error: mods.yml is not a list')
        sys.exit(1)
    
    # Convert to JSON
    json_data = json.dumps(data, indent=2)
    
    # Use jq to remove the old mod entry
    jq_remove_cmd = ['jq', f'del(.[] | select(.name == \"$mod_name\"))']
    result = subprocess.run(jq_remove_cmd, input=json_data, text=True, capture_output=True)
    
    if result.returncode != 0:
        print(f'❌ jq remove failed: {result.stderr}')
        sys.exit(1)
    
    updated_json = result.stdout
    
    # Create new mod entry JSON
    new_mod_json = {
        'manifestVersion': 1,
        'name': '$mod_name',
        'authorName': '$author',
        'websiteUrl': f'https://thunderstore.io/c/repo/p/$mod_name/',
        'displayName': '${mod_name##*-}',
        'description': f'Rolled back to version $new_version',
        'gameVersion': '0',
        'networkMode': 'both',
        'packageType': 'other',
        'installMode': 'unmanaged',
        'installedAtTime': int(subprocess.run(['date', '+%s'], capture_output=True, text=True).stdout.strip()) * 1000,
        'loaders': [],
        'dependencies': [],
        'incompatibilities': [],
        'optionalDependencies': [],
        'versionNumber': {
            'major': int('$major_version'),
            'minor': int('$minor_version'),
            'patch': int('$patch_version')
        },
        'enabled': True,
        'icon': f'${MOD_PLUGIN_PATH}/$mod_name/icon.png'
    }
    
    # Add the new mod entry using jq
    new_mod_json_str = json.dumps(new_mod_json)
    jq_add_cmd = ['jq', f'. + [{new_mod_json_str}]']
    result = subprocess.run(jq_add_cmd, input=updated_json, text=True, capture_output=True)
    
    if result.returncode != 0:
        print(f'❌ jq add failed: {result.stderr}')
        sys.exit(1)
    
    final_json = result.stdout
    
    # Convert back to YAML
    final_data = json.loads(final_json)
    
    # Write back to file
    with open('$mods_yml', 'w') as f:
        yaml.dump(final_data, f, default_flow_style=False, allow_unicode=True)
    
    print('✅ Successfully updated mod registry using jq')
    
except Exception as e:
    print(f'❌ Error updating registry: {e}')
    sys.exit(1)
" || {
        echo -e "${RED}Failed to update mod registry with jq!${NC}"
        log_message "ERROR" "Failed to update mod registry for $mod_name using jq"
        # Restore from backup if update failed
        if [ -f "$backup_file" ]; then
            cp "$backup_file" "$mods_yml"
            echo "Registry restored from backup."
            log_message "INFO" "Registry restored from backup: $backup_file"
        fi
        exit 1
    }
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Mod registry updated successfully using jq!${NC}"
        log_message "INFO" "Mod registry updated successfully for $mod_name using jq"
        
        # Validate the updated YAML
        echo "Validating updated mods.yml..."
        if validate_yaml "$mods_yml"; then
            echo -e "${GREEN}Updated mods.yml is clean and valid${NC}"
            log_message "INFO" "Updated mods.yml is clean and valid"
        else
            echo -e "${YELLOW}Warning: Updated mods.yml has validation issues${NC}"
            log_message "WARN" "Updated mods.yml has validation issues"
        fi
    fi
}

# Function to add mod to registry (for installer)
add_mod_to_registry() {
    local mod_name="$1"
    local mod_path="$2"
    local mod_version="$3"
    local mod_author="$4"
    local mod_description="$5"
    local mod_url="$6"
    local mods_yml="$7"
    
    echo "Registering mod with r2modmanPlus using jq..."
    log_message "INFO" "Adding mod $mod_name to registry using jq"
    
    # Extract version components
    local major_version=$(echo $mod_version | cut -d. -f1)
    local minor_version=$(echo $mod_version | cut -d. -f2)
    local patch_version=$(echo $mod_version | cut -d. -f3)
    
    # Create backup of mods_yml before making changes
    local backup_file="${mods_yml}.backup.$(date +%s)"
    if cp "$mods_yml" "$backup_file"; then
        echo "Backup created: $backup_file"
        log_message "INFO" "Backup created: $backup_file"
    else
        echo -e "${YELLOW}Warning: Could not create backup of mods.yml${NC}"
        log_message "WARN" "Could not create backup of mods.yml"
    fi
    
    # Use jq for robust registry update
    echo "Using jq for registry update..."
    python3 -c "
import yaml
import json
import subprocess
import sys

try:
    # Read and clean the YAML file
    with open('$mods_yml', 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
        # Remove null bytes and control characters
        content = content.replace('\x00', '')
        content = content.replace('\u0000', '')
        import re
        content = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', content)
    
    # Parse YAML
    data = yaml.safe_load(content)
    if not isinstance(data, list):
        print('❌ Error: mods.yml is not a list')
        sys.exit(1)
    
    # Convert to JSON
    json_data = json.dumps(data, indent=2)
    
    # Check if mod already exists
    result = subprocess.run(['jq', f'.[] | select(.name == \"$mod_name\")'], input=json_data, text=True, capture_output=True)
    mod_exists = result.returncode == 0 and result.stdout.strip()
    
    if mod_exists:
        print('Mod already exists in registry, updating entry...')
        # Remove old entry
        jq_remove_cmd = ['jq', f'del(.[] | select(.name == \"$mod_name\"))']
        result = subprocess.run(jq_remove_cmd, input=json_data, text=True, capture_output=True)
        if result.returncode != 0:
            print(f'❌ jq remove failed: {result.stderr}')
            sys.exit(1)
        updated_json = result.stdout
    else:
        print('Adding new mod to r2modmanPlus registry...')
        updated_json = json_data
    
    # Create new mod entry JSON
    new_mod_json = {
        'manifestVersion': 1,
        'name': '$mod_name',
        'authorName': '$mod_author',
        'websiteUrl': '$mod_url',
        'displayName': 'MoreUpgrades',
        'description': '$mod_description',
        'gameVersion': '0',
        'networkMode': 'both',
        'packageType': 'other',
        'installMode': 'unmanaged',
        'installedAtTime': int(subprocess.run(['date', '+%s'], capture_output=True, text=True).stdout.strip()) * 1000,
        'loaders': [],
        'dependencies': [],
        'incompatibilities': [],
        'optionalDependencies': [],
        'versionNumber': {
            'major': int('$major_version'),
            'minor': int('$minor_version'),
            'patch': int('$patch_version')
        },
        'enabled': True,
        'icon': '$mod_path/icon.png'
    }
    
    # Add the new mod entry using jq
    new_mod_json_str = json.dumps(new_mod_json)
    jq_add_cmd = ['jq', f'. + [{new_mod_json_str}]']
    result = subprocess.run(jq_add_cmd, input=updated_json, text=True, capture_output=True)
    
    if result.returncode != 0:
        print(f'❌ jq add failed: {result.stderr}')
        sys.exit(1)
    
    final_json = result.stdout
    
    # Convert back to YAML
    final_data = json.loads(final_json)
    
    # Write back to file
    with open('$mods_yml', 'w') as f:
        yaml.dump(final_data, f, default_flow_style=False, allow_unicode=True)
    
    print('✅ Successfully updated mod registry using jq')
    
except Exception as e:
    print(f'❌ Error updating registry: {e}')
    sys.exit(1)
" || {
        echo -e "${RED}Failed to update mod registry with jq!${NC}"
        log_message "ERROR" "Failed to add mod $mod_name to registry using jq"
        # Restore from backup if update failed
        if [ -f "$backup_file" ]; then
            cp "$backup_file" "$mods_yml"
            echo "Registry restored from backup."
            log_message "INFO" "Registry restored from backup: $backup_file"
        fi
        exit 1
    }
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Mod registry updated successfully using jq!${NC}"
        log_message "INFO" "Mod registry updated successfully for $mod_name using jq"
        
        # Validate the updated YAML
        echo "Validating updated mods.yml..."
        if validate_yaml "$mods_yml"; then
            echo -e "${GREEN}Updated mods.yml is clean and valid${NC}"
            log_message "INFO" "Updated mods.yml is clean and valid"
        else
            echo -e "${YELLOW}Warning: Updated mods.yml has validation issues${NC}"
            log_message "WARN" "Updated mods.yml has validation issues"
        fi
    fi
}

# Function to check if mod exists in registry
mod_exists_in_registry() {
    local mod_name="$1"
    local mods_yml="$2"
    
    if [ ! -f "$mods_yml" ]; then
        return 1
    fi
    
    # Convert to JSON and check with jq
    local json_data=$(yaml_to_json "$mods_yml")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    local result=$(echo "$json_data" | jq -r ".[] | select(.name == \"$mod_name\") | .name")
    if [ "$result" = "$mod_name" ]; then
        return 0
    else
        return 1
    fi
}

# Function to get mod version from registry
get_mod_version_from_registry() {
    local mod_name="$1"
    local mods_yml="$2"
    
    if [ ! -f "$mods_yml" ]; then
        echo ""
        return 1
    fi
    
    # Convert to JSON and extract version with jq
    local json_data=$(yaml_to_json "$mods_yml")
    if [ $? -ne 0 ]; then
        echo ""
        return 1
    fi
    
    local version=$(echo "$json_data" | jq -r ".[] | select(.name == \"$mod_name\") | .versionNumber.major, .versionNumber.minor, .versionNumber.patch" | tr '\n' '.' | sed 's/\.$//')
    echo "$version"
}

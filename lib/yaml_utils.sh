#!/bin/bash

# YAML Utilities Library
# Provides functions for cleaning, validating, and manipulating YAML files

# Define colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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
        echo -e "${GREEN}No null bytes found in mods.yml${NC}"
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

# Function to validate YAML file syntax
validate_yaml() {
    local yaml_file="$1"
    
    if [ ! -f "$yaml_file" ]; then
        echo -e "${RED}Error: YAML file not found: $yaml_file${NC}"
        return 1
    fi
    
    if python3 -c "
import yaml
try:
    with open('$yaml_file', 'r') as f:
        yaml.safe_load(f)
    print('✅ YAML syntax is valid')
except yaml.YAMLError as e:
    print(f'❌ YAML syntax error: {e}')
    exit(1)
except Exception as e:
    print(f'❌ Error validating YAML: {e}')
    exit(1)
"; then
        return 0
    else
        return 1
    fi
}

# Function to convert YAML to JSON for jq processing
yaml_to_json() {
    local yaml_file="$1"
    
    if [ ! -f "$yaml_file" ]; then
        echo -e "${RED}Error: YAML file not found: $yaml_file${NC}"
        return 1
    fi
    
    python3 -c "
import yaml
import json
import sys

try:
    with open('$yaml_file', 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
        # Remove null bytes and control characters
        content = content.replace('\x00', '')
        content = content.replace('\u0000', '')
        import re
        content = re.sub(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '', content)
    
    data = yaml.safe_load(content)
    json_data = json.dumps(data, indent=2)
    print(json_data)
    
except Exception as e:
    print(f'❌ Error converting YAML to JSON: {e}', file=sys.stderr)
    sys.exit(1)
"
}

# Function to convert JSON back to YAML
json_to_yaml() {
    local json_data="$1"
    local yaml_file="$2"
    
    python3 -c "
import yaml
import json
import sys

try:
    data = json.loads('$json_data')
    
    with open('$yaml_file', 'w') as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
    
    print('✅ Successfully converted JSON to YAML')
    
except Exception as e:
    print(f'❌ Error converting JSON to YAML: {e}', file=sys.stderr)
    sys.exit(1)
"
}

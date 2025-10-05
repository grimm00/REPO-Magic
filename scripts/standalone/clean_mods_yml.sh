#!/usr/bin/env bash

# Standalone script to clean and validate mods.yml file
# This script can be run without sudo privileges

PROFILE_NAME=${1:-Default}
MODS_YML="${R2MODMAN_BASE:-$HOME/.config/r2modmanPlus-local}/REPO/profiles/${PROFILE_NAME}/mods.yml"

echo "=========================================="
echo "  mods.yml Cleanup Tool"
echo "=========================================="
echo ""

# Check if file exists
if [ ! -f "$MODS_YML" ]; then
    echo "❌ Error: mods.yml file not found at: $MODS_YML"
    exit 1
fi

echo "Profile: $PROFILE_NAME"
echo "File found: $MODS_YML"
echo "File size: $(ls -lh "$MODS_YML" | awk '{print $5}')"
echo ""

# Create backup before cleaning
backup_file="${MODS_YML}.backup.$(date +%s)"
if cp "$MODS_YML" "$backup_file"; then
    echo "✅ Backup created: $backup_file"
else
    echo "❌ Warning: Could not create backup of mods.yml"
fi

# Check for null bytes
if grep -q $'\0' "$MODS_YML"; then
    echo "⚠️  Found null bytes in mods.yml, cleaning..."
    
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
    with open('$MODS_YML', 'r', encoding='utf-8', errors='ignore') as f:
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
    with open('$MODS_YML', 'w') as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
    
    print('✅ Successfully cleaned mods.yml of null bytes and re-serialized')
    
except Exception as e:
    print(f'❌ Error cleaning mods.yml: {e}')
    sys.exit(1)
" || {
        echo "❌ Failed to clean mods.yml"
        exit 1
    }
else
    echo "✅ No null bytes found in mods.yml"
fi

# Validate YAML syntax
echo ""
echo "Validating YAML syntax..."
if python3 -c "
import yaml
try:
    with open('$MODS_YML', 'r') as f:
        yaml.safe_load(f)
    print('✅ YAML syntax is valid')
except yaml.YAMLError as e:
    print(f'❌ YAML syntax error: {e}')
    exit(1)
except Exception as e:
    print(f'❌ Error validating YAML: {e}')
    exit(1)
"; then
    echo ""
    echo "🎉 mods.yml is clean and valid!"
    echo "r2modmanPlus should now be able to parse the file without errors."
else
    echo ""
    echo "❌ mods.yml still has syntax errors"
    echo "You may need to restore from a backup or let r2modmanPlus recreate the file."
    exit 1
fi

echo ""
echo "New file size: $(ls -lh "$MODS_YML" | awk '{print $5}')"
echo "Backup location: $backup_file"

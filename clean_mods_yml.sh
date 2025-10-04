#!/usr/bin/env bash

# Standalone script to clean and validate mods.yml file
# This script can be run without sudo privileges

MODS_YML="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml"

echo "=========================================="
echo "  mods.yml Cleanup Tool"
echo "=========================================="
echo ""

# Check if file exists
if [ ! -f "$MODS_YML" ]; then
    echo "❌ Error: mods.yml file not found at: $MODS_YML"
    exit 1
fi

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
    
    # Clean null bytes and re-serialize YAML
    python3 -c "
import yaml
import sys

try:
    with open('$MODS_YML', 'r') as f:
        content = f.read()
        # Remove null bytes
        content = content.replace('\x00', '')
        
    # Parse and re-serialize to clean up the YAML
    data = yaml.safe_load(content)
    
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

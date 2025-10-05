# r2modmanPlus Integration Guide

This guide explains how to properly integrate manual mod installations with r2modmanPlus's management system.

## Understanding r2modmanPlus Structure

### Key Files and Directories

```
/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/
├── mods.yml                           # Main mod registry
├── _state/
│   └── installation_state.yml        # Installation tracking
├── BepInEx/
│   └── plugins/                      # Where mod DLLs go
├── doorstop_config.ini               # BepInEx configuration
└── winhttp.dll                       # BepInEx loader
```

## Mod Registry (`mods.yml`)

The `mods.yml` file is the heart of r2modmanPlus's mod management. Each mod entry contains:

### Required Fields for Manual Installation

```yaml
- manifestVersion: 1
  name: "BULLETBOT-MoreUpgrades"           # Unique mod identifier
  authorName: "BULLETBOT"                  # Mod author
  websiteUrl: "https://thunderstore.io/c/repo/p/BULLETBOT/MoreUpgrades/"
  displayName: "MoreUpgrades"              # Display name in UI
  description: "Mod description here"
  gameVersion: "0"                         # Game version (0 = any)
  networkMode: "both"                      # both/singleplayer/multiplayer
  packageType: "other"                     # other/dependency
  installMode: "unmanaged"                 # managed/unmanaged
  installedAtTime: 1759605219453           # Unix timestamp
  loaders: []                              # Required loaders
  dependencies: []                         # Required mods
  incompatibilities: []                    # Incompatible mods
  optionalDependencies: []                 # Optional mods
  versionNumber:
    major: 1
    minor: 4
    patch: 8
  enabled: true                            # Mod enabled state
  icon: "path/to/icon.png"                 # Mod icon path
```

## Adding Your Manual Installation to r2modmanPlus

### Method 1: Update the Script to Modify mods.yml

Add this to your `modinstaller.sh` script:

```bash
# Function to add mod to r2modmanPlus registry
add_to_mod_registry() {
    local mod_name="$1"
    local mod_path="$2"
    local mod_version="$3"
    local mod_author="$4"
    local mod_description="$5"
    local mod_url="$6"
    
    # Create mod entry
    local mod_entry="
- manifestVersion: 1
  name: \"$mod_name\"
  authorName: \"$mod_author\"
  websiteUrl: \"$mod_url\"
  displayName: \"$mod_name\"
  description: \"$mod_description\"
  gameVersion: \"0\"
  networkMode: both
  packageType: other
  installMode: unmanaged
  installedAtTime: $(date +%s)000
  loaders: []
  dependencies: []
  incompatibilities: []
  optionalDependencies: []
  versionNumber:
    major: $(echo $mod_version | cut -d. -f1)
    minor: $(echo $mod_version | cut -d. -f2)
    patch: $(echo $mod_version | cut -d. -f3)
  enabled: true
  icon: \"$mod_path/icon.png\""

    # Check if mod already exists in registry
    if grep -q "name: \"$mod_name\"" "$MOD_PLUGIN_PATH/../mods.yml"; then
        echo "Mod already exists in registry, updating..."
        # Remove existing entry (complex operation)
        # This would require more sophisticated YAML manipulation
    else
        echo "Adding mod to r2modmanPlus registry..."
        # Add new entry to mods.yml
        echo "$mod_entry" >> "$MOD_PLUGIN_PATH/../mods.yml"
    fi
}

# Call this function after successful installation
add_to_mod_registry \
    "BULLETBOT-MoreUpgrades" \
    "$MOD_INSTALL_PATH_REPO" \
    "1.4.8" \
    "BULLETBOT" \
    "Adds more upgrade items to the game, has an library and is highly configurable." \
    "https://thunderstore.io/package/download/BULLETBOT/MoreUpgrades/1.4.8/"
```

### Method 2: Create a Separate Registration Script

Create `register_mod.sh`:

```bash
#!/bin/bash

# Script to register manually installed mods with r2modmanPlus

MOD_NAME="BULLETBOT-MoreUpgrades"
MOD_VERSION="1.4.8"
MOD_AUTHOR="BULLETBOT"
MOD_DESCRIPTION="Adds more upgrade items to the game, has an library and is highly configurable."
MOD_URL="https://thunderstore.io/package/download/BULLETBOT/MoreUpgrades/1.4.8/"
MOD_PATH="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades"
MODS_YML="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml"

# Create mod entry
MOD_ENTRY="
- manifestVersion: 1
  name: \"$MOD_NAME\"
  authorName: \"$MOD_AUTHOR\"
  websiteUrl: \"$MOD_URL\"
  displayName: \"MoreUpgrades\"
  description: \"$MOD_DESCRIPTION\"
  gameVersion: \"0\"
  networkMode: both
  packageType: other
  installMode: unmanaged
  installedAtTime: $(date +%s)000
  loaders: []
  dependencies: []
  incompatibilities: []
  optionalDependencies: []
  versionNumber:
    major: 1
    minor: 4
    patch: 8
  enabled: true
  icon: \"$MOD_PATH/icon.png\""

# Check if mod exists
if grep -q "name: \"$MOD_NAME\"" "$MODS_YML"; then
    echo "Mod $MOD_NAME already exists in registry"
    exit 0
fi

# Add to registry
echo "Adding $MOD_NAME to r2modmanPlus registry..."
echo "$MOD_ENTRY" >> "$MODS_YML"
echo "Mod registered successfully!"
```

## Important Considerations

### 1. **Install Mode**
- Use `installMode: "unmanaged"` for manually installed mods
- This tells r2modmanPlus not to try to manage the mod files

### 2. **Dependencies**
- If your mod depends on other mods, list them in the `dependencies` array
- Example: `dependencies: ["BepInEx-BepInExPack-5.4.2100"]`

### 3. **Version Numbers**
- Use semantic versioning (major.minor.patch)
- Make sure version numbers match the actual mod version

### 4. **Icons**
- r2modmanPlus expects mod icons to be in the mod directory
- Use relative paths from the mod directory

### 5. **Timestamps**
- `installedAtTime` should be in milliseconds since Unix epoch
- Use `$(date +%s)000` to get current time in milliseconds

## Advanced Integration

### YAML Manipulation
For more sophisticated registry management, consider using `yq`:

```bash
# Install yq (if not already installed)
sudo pacman -S yq

# Add mod to registry
yq eval '. += [{"manifestVersion": 1, "name": "BULLETBOT-MoreUpgrades", ...}]' -i "$MODS_YML"

# Remove mod from registry
yq eval 'del(.[] | select(.name == "BULLETBOT-MoreUpgrades"))' -i "$MODS_YML"

# Update mod version
yq eval '(.[] | select(.name == "BULLETBOT-MoreUpgrades") | .versionNumber) = {"major": 1, "minor": 4, "patch": 8}' -i "$MODS_YML"
```

### Backup and Restore
Always backup the mods.yml before making changes:

```bash
# Backup
cp "$MODS_YML" "$MODS_YML.backup.$(date +%s)"

# Restore if needed
cp "$MODS_YML.backup.1234567890" "$MODS_YML"
```

## Troubleshooting

### Common Issues

1. **Mod not showing in r2modmanPlus**
   - Check YAML syntax in mods.yml
   - Verify file paths are correct
   - Ensure mod files are in the right location

2. **Mod showing as disabled**
   - Check `enabled: true` in the registry entry
   - Verify mod files are present and readable

3. **Dependency issues**
   - List all required dependencies in the `dependencies` array
   - Ensure dependencies are installed first

### Validation
Use this script to validate your mods.yml:

```bash
#!/bin/bash
# Validate mods.yml syntax
python3 -c "import yaml; yaml.safe_load(open('$MODS_YML'))" && echo "YAML is valid" || echo "YAML syntax error"
```

## Best Practices

1. **Always backup** mods.yml before making changes
2. **Use consistent naming** for mod identifiers
3. **Include proper metadata** (description, author, etc.)
4. **Test thoroughly** after registry changes
5. **Document your changes** for future reference

This integration will make your manually installed mods appear properly in r2modmanPlus's interface, allowing users to enable/disable them and see their status alongside other managed mods.

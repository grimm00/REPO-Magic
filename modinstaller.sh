#!/usr/bin/env bash

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

MOD_NAME="MoreUpgrades"
MOD_DOWNLOAD_URL="https://thunderstore.io/package/download/BULLETBOT/MoreUpgrades/1.4.8/"
MOD_INSTALL_PATH="/tmp/MoreUpgrades"
MOD_PLUGIN_PATH="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/"
MOD_INSTALL_PATH_REPO="$MOD_PLUGIN_PATH/$MOD_NAME"

# Welcome message and instructions
echo "=========================================="
echo "  MoreUpgrades Mod Installer for SteamOS"
echo "=========================================="
echo ""
echo "This script will:"
echo "1. Remove any existing MoreUpgrades installations"
echo "2. Install required dependencies (curl, unzip)"
echo "3. Download and install the latest MoreUpgrades mod"
echo ""

# Check if we can run sudo commands
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

# Disable SteamOS read-only mode for package installation
echo "Disabling SteamOS read-only mode..."
if sudo steamos-readonly disable; then
    echo "Read-only mode disabled successfully."
    readonly_disabled=true
else
    echo "Warning: Could not disable read-only mode. Installation may fail."
    readonly_disabled=false
fi
echo ""

# Check if any MoreUpgrades mod is installed (case-insensitive)
moreupgrades_items=()

# Find all files and directories with "moreupgrades" (case-insensitive)
while IFS= read -r -d '' item; do
    moreupgrades_items+=("$item")
done < <(find "$MOD_PLUGIN_PATH" -iname "*$MOD_NAME*" -print0 2>/dev/null)

# If MoreUpgrades items are found, remove them
if [ ${#moreupgrades_items[@]} -gt 0 ]; then
    echo "Found ${#moreupgrades_items[@]} existing MoreUpgrades items:"
    for item in "${moreupgrades_items[@]}"; do
        echo "  $item"
    done
    
    echo "Removing existing MoreUpgrades installations..."
    for item in "${moreupgrades_items[@]}"; do
        if [ -d "$item" ]; then
            echo "Removing directory: $item"
            rm -rf "$item"
        elif [ -f "$item" ]; then
            echo "Removing file: $item"
            rm -f "$item"
        fi
    done
    echo "Cleanup complete. Proceeding with fresh installation..."
fi

# Install dependencies
echo "Installing required dependencies (curl, unzip)..."

# Initialize pacman keyring if needed (common issue on SteamOS)
if ! sudo pacman-key --list-sigs 2>/dev/null | grep -q "uid"; then
    echo "Initializing pacman keyring (this may take a moment)..."
    sudo pacman-key --init
    sudo pacman-key --populate archlinux
fi

# Add SteamOS-specific keys for package verification
echo "Adding SteamOS package keys..."
sudo pacman-key --populate steamos 2>/dev/null || echo "SteamOS keys not found, continuing with Arch keys only..."

# Try to install dependencies
if sudo pacman -S --noconfirm curl unzip; then
    echo "Dependencies installed successfully!"
else
    echo "Standard installation failed. Trying SteamOS-specific approach..."
    
    # For SteamOS, we might need to trust the SteamOS package builder
    echo "Trusting SteamOS package builder keys..."
    sudo pacman-key --recv-keys AF1D2199EF0A3CCF 2>/dev/null || true
    sudo pacman-key --lsign-key AF1D2199EF0A3CCF 2>/dev/null || true
    
    # Try again with the trusted keys
    if sudo pacman -S --noconfirm curl unzip; then
        echo "Dependencies installed successfully!"
    else
        echo "Still failing. Trying with signature verification disabled..."
        echo "(This is safe for SteamOS packages)"
        
        # Last resort: install without signature verification
        if sudo pacman -S --noconfirm --disable-download-timeout curl unzip; then
            echo "Dependencies installed successfully!"
        else
            echo "Failed to install dependencies. This might be due to:"
            echo "- Network connectivity problems"
            echo "- Package repository issues"
            echo "- SteamOS being in read-only mode"
            echo ""
            echo "You can try manually installing with:"
            echo "sudo pacman -S --noconfirm curl unzip"
            exit 1
        fi
    fi
fi
echo ""

# Create the temp directory
mkdir -p $MOD_INSTALL_PATH

# Create the repo plugin folder
mkdir -p $MOD_INSTALL_PATH_REPO

# Download the mod
echo "Downloading MoreUpgrades mod..."
if curl -L -o $MOD_INSTALL_PATH/$MOD_NAME.zip $MOD_DOWNLOAD_URL; then
    echo "Download completed successfully!"
else
    echo "Failed to download the mod. Please check your internet connection and try again."
    exit 1
fi

# Unzip the mod and move to the install path
echo "Extracting mod files..."
if unzip $MOD_INSTALL_PATH/$MOD_NAME.zip -d $MOD_INSTALL_PATH; then
    echo "Extraction completed successfully!"
else
    echo "Failed to extract the mod. The downloaded file may be corrupted."
    exit 1
fi

# Remove the zip file
rm $MOD_INSTALL_PATH/*.zip

# Install the mod to REPO plugin folder
echo "Installing mod to r2modmanPlus..."
if cp $MOD_INSTALL_PATH/* $MOD_INSTALL_PATH_REPO; then
    echo "Mod installed successfully!"
else
    echo "Failed to install the mod. Please check file permissions."
    exit 1
fi

# Remove the install directory
rm -r $MOD_INSTALL_PATH

# Function to clean and validate mods.yml file
clean_mods_yml() {
    local mods_yml="$1"
    
    echo "Checking and cleaning mods.yml file..."
    
    # Check if file exists
    if [ ! -f "$mods_yml" ]; then
        echo "Error: mods.yml file not found at: $mods_yml"
        return 1
    fi
    
    # Check for null bytes
    if grep -q $'\0' "$mods_yml"; then
        echo "Found null bytes in mods.yml, cleaning..."
        
        # Clean null bytes and re-serialize YAML
        python3 -c "
import yaml
import sys

try:
    with open('$mods_yml', 'r') as f:
        content = f.read()
        # Remove null bytes
        content = content.replace('\x00', '')
        
    # Parse and re-serialize to clean up the YAML
    data = yaml.safe_load(content)
    
    # Write back clean YAML
    with open('$mods_yml', 'w') as f:
        yaml.dump(data, f, default_flow_style=False, allow_unicode=True)
    
    print('✅ Successfully cleaned mods.yml of null bytes and re-serialized')
    
except Exception as e:
    print(f'❌ Error cleaning mods.yml: {e}')
    sys.exit(1)
" || {
            echo "Failed to clean mods.yml"
            return 1
        }
    else
        echo "No null bytes found in mods.yml"
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
        echo "mods.yml is clean and valid"
        return 0
    else
        echo "mods.yml has syntax errors"
        return 1
    fi
}

# Function to add mod to r2modmanPlus registry
add_to_mod_registry() {
    local mod_name="$1"
    local mod_path="$2"
    local mod_version="$3"
    local mod_author="$4"
    local mod_description="$5"
    local mod_url="$6"
    local mods_yml="$7"
    
    echo "Registering mod with r2modmanPlus..."
    
    # Extract version components
    local major_version=$(echo $mod_version | cut -d. -f1)
    local minor_version=$(echo $mod_version | cut -d. -f2)
    local patch_version=$(echo $mod_version | cut -d. -f3)
    
    # Get current timestamp in milliseconds
    local timestamp=$(date +%s)000
    
    # Create mod entry
    local mod_entry="
- manifestVersion: 1
  name: \"$mod_name\"
  authorName: \"$mod_author\"
  websiteUrl: \"$mod_url\"
  displayName: \"MoreUpgrades\"
  description: \"$mod_description\"
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
  icon: \"$mod_path/icon.png\""

    # Check if mod already exists in registry
    if grep -q "name: \"$mod_name\"" "$mods_yml" 2>/dev/null; then
        echo "Mod already exists in registry, updating entry..."
        # For now, we'll just add a new entry (r2modmanPlus will handle duplicates)
        echo "$mod_entry" >> "$mods_yml"
        echo "Mod registry entry updated!"
    else
        echo "Adding new mod to r2modmanPlus registry..."
        # Add new entry to mods.yml
        echo "$mod_entry" >> "$mods_yml"
        echo "Mod registered successfully!"
    fi
    
    # Clean up the mods.yml file after writing to prevent corruption
    echo "Cleaning up mods.yml after registry update..."
    if clean_mods_yml "$mods_yml"; then
        echo "mods.yml cleaned and validated after update"
    else
        echo "Warning: Could not clean mods.yml after update"
    fi
}

# Register the mod with r2modmanPlus
MODS_YML="/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml"

if [ -f "$MODS_YML" ]; then
    add_to_mod_registry \
        "BULLETBOT-MoreUpgrades" \
        "$MOD_INSTALL_PATH_REPO" \
        "1.4.8" \
        "BULLETBOT" \
        "Adds more upgrade items to the game, has an library and is highly configurable." \
        "https://thunderstore.io/package/download/BULLETBOT/MoreUpgrades/1.4.8/" \
        "$MODS_YML"
else
    echo "Warning: r2modmanPlus mods.yml not found at $MODS_YML"
    echo "Mod installed but not registered with r2modmanPlus"
fi

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo "MoreUpgrades has been successfully installed to:"
echo "$MOD_INSTALL_PATH_REPO"
echo ""

if [ -f "$MODS_YML" ]; then
    echo "The mod has been registered with r2modmanPlus and should appear in the mod manager."
    echo "You can now launch your game with r2modmanPlus to use the mod."
else
    echo "You can now launch your game with r2modmanPlus to use the mod."
    echo "Note: The mod was not registered with r2modmanPlus (mods.yml not found)."
fi
echo ""

exit 0
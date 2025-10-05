#!/bin/bash

# REPO-Magic User Package Creation Script
# Creates a streamlined package for end users (friends)

set -e

# Colors for output (with fallback for terminals that don't support colors)
if [ -t 1 ] && command -v tput >/dev/null 2>&1 && [ "$(tput colors 2>/dev/null || echo 0)" -ge 8 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    BLUE=''
    YELLOW=''
    NC=''
fi

# Package configuration
PACKAGE_NAME="REPO-Magic-User-v1.0"
PACKAGE_DIR="/tmp/$PACKAGE_NAME"

echo "=========================================="
echo "  REPO-Magic User Package Creation"
echo "=========================================="
echo ""

# Clean up any existing package
if [ -d "$PACKAGE_DIR" ]; then
    echo -e "${BLUE}Cleaning up existing package directory...${NC}"
    rm -rf "$PACKAGE_DIR"
fi

# Create package directory
echo -e "${BLUE}Creating package directory: $PACKAGE_DIR${NC}"
mkdir -p "$PACKAGE_DIR"
echo ""

# Copy core files
echo -e "${BLUE}Copying core files...${NC}"

# Main scripts
cp modrollback.sh "$PACKAGE_DIR/"
cp modinstaller.sh "$PACKAGE_DIR/"
cp clean_mods_yml.sh "$PACKAGE_DIR/"
echo "[OK] Core scripts copied"

# Library files
mkdir -p "$PACKAGE_DIR/lib"
cp lib/*.sh "$PACKAGE_DIR/lib/" 2>/dev/null || true
echo "[OK] Library files copied"

# Standalone scripts
mkdir -p "$PACKAGE_DIR/scripts/standalone"
cp scripts/standalone/*.sh "$PACKAGE_DIR/scripts/standalone/" 2>/dev/null || true
echo "[OK] Standalone scripts copied"

# Essential documentation only (no admin files)
mkdir -p "$PACKAGE_DIR/docs"
cp -r docs/guides "$PACKAGE_DIR/docs/" 2>/dev/null || true
cp -r docs/troubleshooting "$PACKAGE_DIR/docs/" 2>/dev/null || true
echo "[OK] Essential documentation copied"

# Installation and dependency scripts
cp install.sh "$PACKAGE_DIR/"
cp check_dependencies.sh "$PACKAGE_DIR/"
echo "[OK] Installation scripts copied"

# Create user-friendly README
cat > "$PACKAGE_DIR/README.md" << 'EOL'
# REPO-Magic - Mod Management Tools

🎮 **Simple mod management tools for Risk of Rain 2 with r2modmanPlus**

## 🚀 Quick Start

1. **Extract** this package anywhere on your Steam Deck
2. **Run setup**: `./install.sh`
3. **Start using**: `./modrollback.sh --profile Default`

## 📋 What's Included

- **modrollback.sh** - Rollback mods to previous versions
- **modinstaller.sh** - Install mods from Thunderstore URLs
- **clean_mods_yml.sh** - Clean and validate mods.yml files
- **Standalone versions** - Single-file scripts in `scripts/standalone/`

## 🎯 Usage Examples

```bash
# Rollback mods in Default profile
./modrollback.sh --profile Default

# Install a mod from Thunderstore
./modinstaller.sh https://thunderstore.io/c/risk-of-rain-2/p/Author/ModName/

# Clean mods.yml file
./clean_mods_yml.sh Default
```

## 📁 Profile Support

- Use `--profile Friends` for your custom profile
- Use `--profile Default` for the default r2modmanPlus profile
- Leave empty to use Default profile

## 🛠️ Requirements

- SteamOS/Linux
- r2modmanPlus installed
- Required tools: jq, curl, openssl, git, python3

## 🆘 Need Help?

Check the `docs/` folder for detailed guides and troubleshooting.

## [SUCCESS] Happy Modding!

EOL

echo "[OK] User-friendly README created"
echo ""

# Set up package permissions
echo -e "${BLUE}Setting up package permissions...${NC}"
find "$PACKAGE_DIR" -name "*.sh" -exec chmod +x {} \;
echo "[OK] Set executable permissions"
echo ""

# Create package archive
echo -e "${BLUE}Creating package archive...${NC}"
cd /tmp
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" >/dev/null
echo "[OK] Package created: /tmp/${PACKAGE_NAME}.zip"

# Show package info
PACKAGE_SIZE=$(du -h "/tmp/${PACKAGE_NAME}.zip" | cut -f1)
echo -e "📦 Package size: ${PACKAGE_SIZE}"
echo ""

# Show package contents
echo -e "${BLUE}Package contents:${NC}"
echo "----------------------"
unzip -l "/tmp/${PACKAGE_NAME}.zip" | head -20
echo "... (and more files)"
echo ""

echo "=========================================="
echo -e "[SUCCESS] ${GREEN}User package creation complete!${NC}"
echo "=========================================="
echo ""
echo -e "${BLUE}Package location:${NC} /tmp/${PACKAGE_NAME}.zip"
echo -e "${BLUE}Package size:${NC} ${PACKAGE_SIZE}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Test the package by extracting it to a temporary location"
echo "2. Run the install.sh script in the extracted package"
echo "3. Upload to GitHub releases or share with friends"
echo ""
echo -e "${GREEN}Your friends can now:${NC}"
echo "• Download the zip file"
echo "• Extract it anywhere"
echo "• Run ./install.sh to set up"
echo "• Start using the mod management tools!"
echo ""

# Clean up temporary directory
echo -e "${BLUE}Cleaning up temporary directory...${NC}"
rm -rf "$PACKAGE_DIR"
echo "[OK] Cleanup complete"

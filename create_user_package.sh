#!/bin/bash

# REPO-Magic User Package Creation Script
# This script creates a minimal package for end users (friends)
# Strips out development docs, admin files, and internal tooling

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERSION="1.0"
PACKAGE_NAME="REPO-Magic-User-v${VERSION}"
PACKAGE_DIR="/tmp/${PACKAGE_NAME}"

echo "=========================================="
echo "  REPO-Magic User Package Creation"
echo "=========================================="
echo ""

# Check if we're in the right directory
if [ ! -f "modrollback.sh" ] || [ ! -f "modinstaller.sh" ]; then
    echo -e "${RED}❌ Error: Please run this script from the REPO-Magic directory${NC}"
    exit 1
fi

# Clean up any existing package
if [ -d "$PACKAGE_DIR" ]; then
    echo "Cleaning up existing package directory..."
    rm -rf "$PACKAGE_DIR"
fi

echo -e "${BLUE}Creating user package directory: $PACKAGE_DIR${NC}"
mkdir -p "$PACKAGE_DIR"

echo ""
echo -e "${BLUE}Copying core user files...${NC}"

# Copy main scripts (the essential tools)
cp modrollback.sh "$PACKAGE_DIR/"
cp modinstaller.sh "$PACKAGE_DIR/"
cp clean_mods_yml.sh "$PACKAGE_DIR/"

# Copy library files (required for main scripts to work)
mkdir -p "$PACKAGE_DIR/lib"
shopt -s nullglob
cp lib/*.sh "$PACKAGE_DIR/lib/" 2>/dev/null || true
shopt -u nullglob

# Copy standalone scripts (alternative single-file versions)
mkdir -p "$PACKAGE_DIR/scripts/standalone"
shopt -s nullglob
cp scripts/standalone/*.sh "$PACKAGE_DIR/scripts/standalone/" 2>/dev/null || true
shopt -u nullglob

# Copy only essential documentation
mkdir -p "$PACKAGE_DIR/docs"
cp README.md "$PACKAGE_DIR/"
cp -r docs/guides "$PACKAGE_DIR/docs/" 2>/dev/null || true
cp -r docs/troubleshooting "$PACKAGE_DIR/docs/" 2>/dev/null || true

# Copy user-facing tools
cp install.sh "$PACKAGE_DIR/"
cp check_dependencies.sh "$PACKAGE_DIR/"

echo "✅ Main scripts copied"
echo "✅ Library files copied"
echo "✅ Standalone scripts copied"
echo "✅ Essential documentation copied"
echo "✅ User tools copied"

echo ""
echo -e "${BLUE}Setting up package permissions...${NC}"

# Set executable permissions
shopt -s nullglob
chmod +x "$PACKAGE_DIR"/*.sh 2>/dev/null || true
chmod +x "$PACKAGE_DIR/lib"/*.sh 2>/dev/null || true
chmod +x "$PACKAGE_DIR/scripts/standalone"/*.sh 2>/dev/null || true
shopt -u nullglob

echo "✅ Set executable permissions"

echo ""
echo -e "${BLUE}Creating user-friendly README...${NC}"

# Create a simplified README for users
cat > "$PACKAGE_DIR/README.md" << 'EOL'
# REPO-Magic - Mod Management Tools

Simple tools to manage your r2modmanPlus mods with profile support.

## 🚀 Quick Start

1. **Install**: Run `./install.sh` to set up dependencies
2. **List mods**: `./modrollback.sh --profile Default`
3. **Install mod**: `./modinstaller.sh <thunderstore-url>`
4. **Rollback mod**: `./modrollback.sh --profile Default`

## 📁 What's Included

### Main Scripts
- `modrollback.sh` - Rollback mods to previous versions
- `modinstaller.sh` - Install mods from Thunderstore
- `clean_mods_yml.sh` - Clean up mods.yml file

### Standalone Scripts (Single-file versions)
- `scripts/standalone/modrollback-simple.sh`
- `scripts/standalone/modinstaller-simple.sh`
- `scripts/standalone/clean_mods_yml.sh`

### Setup Tools
- `install.sh` - Automatic setup and dependency checking
- `check_dependencies.sh` - Check if required tools are installed

## 🎮 Profile Support

Use different r2modmanPlus profiles:
```bash
./modrollback.sh --profile Friends
./modrollback.sh --profile Default
./modinstaller.sh --profile MyProfile <url>
```

## 📋 Requirements

- SteamOS/Linux with bash
- r2modmanPlus installed
- Required tools: jq, curl, openssl, git, python3

## 🆘 Need Help?

Check the `docs/` folder for guides and troubleshooting.

## 🎯 Happy Modding!

These tools make managing your mods easier with profile support and reliable mod discovery.
EOL

echo "✅ Created user-friendly README"

echo ""
echo -e "${BLUE}Creating package archive...${NC}"

# Create the zip file
cd /tmp
zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME" >/dev/null

if [ $? -eq 0 ]; then
    echo "✅ Package created: /tmp/${PACKAGE_NAME}.zip"
    
    # Get package size
    PACKAGE_SIZE=$(du -h "/tmp/${PACKAGE_NAME}.zip" | cut -f1)
    echo "📦 Package size: $PACKAGE_SIZE"
    
    # List package contents
    echo ""
    echo -e "${BLUE}Package contents:${NC}"
    echo "----------------------"
    unzip -l "/tmp/${PACKAGE_NAME}.zip" | grep -E "\.(sh|md)$" | head -15
    echo "... (and more files)"
    
    echo ""
    echo "=========================================="
    echo -e "🎉 ${GREEN}User package creation complete!${NC}"
    echo "=========================================="
    echo ""
    echo -e "${BLUE}Package location:${NC} /tmp/${PACKAGE_NAME}.zip"
    echo -e "${BLUE}Package size:${NC} $PACKAGE_SIZE"
    echo ""
    echo -e "${YELLOW}What's included:${NC}"
    echo "• Core mod management scripts"
    echo "• Required library files"
    echo "• Standalone single-file versions"
    echo "• Essential documentation only"
    echo "• Setup and dependency checking tools"
    echo ""
    echo -e "${YELLOW}What's excluded:${NC}"
    echo "• Development documentation"
    echo "• Admin and planning files"
    echo "• Internal tooling and scripts"
    echo "• GitHub integration tools"
    echo ""
    echo -e "${GREEN}Perfect for sharing with friends! 🎮${NC}"
    
else
    echo -e "${RED}❌ Failed to create package${NC}"
    exit 1
fi

# Clean up
echo ""
echo "Cleaning up temporary directory..."
rm -rf "$PACKAGE_DIR"
echo "✅ Cleanup complete"

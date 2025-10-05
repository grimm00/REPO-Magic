#!/bin/bash

# REPO-Magic Package Creation Script
# This script creates a release package for distribution

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

VERSION="1.0"
PACKAGE_NAME="REPO-Magic-v${VERSION}"
PACKAGE_DIR="/tmp/${PACKAGE_NAME}"

echo "=========================================="
echo "  REPO-Magic Package Creation"
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

echo -e "${BLUE}Creating package directory: $PACKAGE_DIR${NC}"
mkdir -p "$PACKAGE_DIR"

echo ""
echo -e "${BLUE}Copying core files...${NC}"

# Copy main scripts
cp modrollback.sh "$PACKAGE_DIR/"
cp modinstaller.sh "$PACKAGE_DIR/"
cp clean_mods_yml.sh "$PACKAGE_DIR/"

# Copy library files
mkdir -p "$PACKAGE_DIR/lib"
shopt -s nullglob
cp lib/*.sh "$PACKAGE_DIR/lib/" 2>/dev/null || true
shopt -u nullglob

# Copy standalone scripts
mkdir -p "$PACKAGE_DIR/scripts/standalone"
shopt -s nullglob
cp scripts/standalone/*.sh "$PACKAGE_DIR/scripts/standalone/" 2>/dev/null || true
shopt -u nullglob

# Copy documentation
mkdir -p "$PACKAGE_DIR/docs"
cp -r docs/guides "$PACKAGE_DIR/docs/"
cp -r docs/troubleshooting "$PACKAGE_DIR/docs/"

# Copy main documentation
cp README.md "$PACKAGE_DIR/"

# Copy installation and dependency check scripts
cp install.sh "$PACKAGE_DIR/"
cp check_dependencies.sh "$PACKAGE_DIR/"

echo "✅ Core scripts copied"
echo "✅ Library files copied"
echo "✅ Standalone scripts copied"
echo "✅ Documentation copied"
echo "✅ Installation scripts copied"

echo ""
echo -e "${BLUE}Setting up package permissions...${NC}"

# Set executable permissions
chmod +x "$PACKAGE_DIR"/*.sh
chmod +x "$PACKAGE_DIR/lib"/*.sh
chmod +x "$PACKAGE_DIR/scripts/standalone"/*.sh

echo "✅ Set executable permissions"

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
    unzip -l "/tmp/${PACKAGE_NAME}.zip" | grep -E "\.(sh|md)$" | head -20
    echo "... (and more files)"
    
    echo ""
    echo "=========================================="
    echo -e "🎉 ${GREEN}Package creation complete!${NC}"
    echo "=========================================="
    echo ""
    echo -e "${BLUE}Package location:${NC} /tmp/${PACKAGE_NAME}.zip"
    echo -e "${BLUE}Package size:${NC} $PACKAGE_SIZE"
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
    
else
    echo -e "${RED}❌ Failed to create package${NC}"
    exit 1
fi

# Clean up
echo ""
echo "Cleaning up temporary directory..."
rm -rf "$PACKAGE_DIR"
echo "✅ Cleanup complete"

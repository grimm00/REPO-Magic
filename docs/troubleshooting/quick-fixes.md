# Quick Fixes for MoreUpgrades Mod Installer

> **For detailed troubleshooting, see [README.md](README.md)**

## Most Common Issues and Quick Solutions

### 🔧 Permission Denied
```bash
chmod +x modinstaller.sh
# or for rollback script
chmod +x modrollback.sh
```

### 🔑 Sudo Password Issues
- First time: Set a new password when prompted
- Wrong password: Try again or reset sudo password

### 🔄 Mod Rollback Issues
- **No mods found:** Check r2modmanPlus installation
- **Version not found:** Try different version number
- **Download fails:** Check internet connection
- **Registry update fails:** Close r2modmanPlus and retry
- **For detailed rollback troubleshooting:** See [rollback-troubleshooting.md](rollback-troubleshooting.md)

### 📦 Package Installation Fails
```bash
# Try manual installation
sudo pacman -S --noconfirm curl unzip

# If keyring issues:
sudo pacman-key --init
sudo pacman-key --populate archlinux
```

### 🌐 Download Fails
```bash
# Test internet connection
ping google.com

# Test Thunderstore access
curl -I https://thunderstore.io
```

### 📁 Read-Only File System
```bash
sudo steamos-readonly disable
# Run script
sudo steamos-readonly enable
```

### 🎮 Mod Not Showing in r2modmanPlus
1. Restart r2modmanPlus
2. Check profile is set to "Friends"
3. Verify mod files exist:
   ```bash
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades/
   ```

## Emergency Commands

### Reset Everything and Start Over
```bash
# Remove existing mod
rm -rf /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades*

# Disable read-only
sudo steamos-readonly disable

# Install dependencies
sudo pacman -S --noconfirm curl unzip

# Run script
./modinstaller.sh
```

### Manual Mod Installation
```bash
# Download manually
curl -L -o /tmp/MoreUpgrades.zip "https://thunderstore.io/package/download/BULLETBOT/MoreUpgrades/1.4.8/"

# Extract
unzip /tmp/MoreUpgrades.zip -d /tmp/MoreUpgrades/

# Install
mkdir -p /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades
cp /tmp/MoreUpgrades/* /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades/

# Cleanup
rm -rf /tmp/MoreUpgrades*
```

## Status Check Commands

```bash
# Check if script is executable
ls -la modinstaller.sh

# Check if dependencies are installed
pacman -Q curl unzip

# Check if mod is installed
ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades/

# Check read-only status
sudo steamos-readonly status

# Check sudo status
sudo -v
```

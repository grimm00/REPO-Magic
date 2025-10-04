# Troubleshooting Guide for MoreUpgrades Mod Installer

This guide helps you resolve common issues when running the MoreUpgrades mod installer on SteamOS.

## Table of Contents
- [Permission Issues](#permission-issues)
- [Sudo Problems](#sudo-problems)
- [Package Installation Failures](#package-installation-failures)
- [Network Issues](#network-issues)
- [SteamOS Read-Only Mode](#steamos-read-only-mode)
- [Mod Installation Issues](#mod-installation-issues)
- [r2modmanPlus Issues](#r2modmanplus-issues)
- [SteamOS-Specific Issues](#steamos-specific-issues)
- [Advanced Troubleshooting](#advanced-troubleshooting)

---

## Permission Issues

### Problem: "Permission denied" when running the script

**Symptoms:**
```bash
bash: ./modinstaller.sh: Permission denied
```

**Solution:**
```bash
chmod +x modinstaller.sh
./modinstaller.sh
```

**Explanation:** The script needs execute permissions to run.

---

## Sudo Problems

### Problem: First-time sudo setup

**Symptoms:**
- Script prompts for password but you've never set one
- "sudo: command not found" errors

**Solution:**
1. When prompted, set a new sudo password (choose something memorable)
2. Confirm the password by typing it again
3. Use this password for future sudo operations

**Note:** The password won't be visible as you type (this is normal for security).

### Problem: Sudo authentication fails

**Symptoms:**
```
Sudo authentication failed. This could be because:
- You entered the wrong password
- You cancelled the password prompt
```

**Solution:**
1. Make sure you're typing the correct password
2. Try running the script again
3. If you forgot your password, you may need to reset it

---

## Package Installation Failures

### Problem: "keyring is not writable" or "required key missing"

**Symptoms:**
```
error: keyring is not writable
error: required key missing from keyring
error: failed to commit transaction (unexpected error)
```

**Solution:**
The script should handle this automatically, but if it persists:

1. **Manual keyring initialization:**
   ```bash
   sudo pacman-key --init
   sudo pacman-key --populate archlinux
   sudo pacman-key --populate steamos
   ```

2. **Trust SteamOS package builder:**
   ```bash
   sudo pacman-key --recv-keys AF1D2199EF0A3CCF
   sudo pacman-key --lsign-key AF1D2199EF0A3CCF
   ```

3. **Try installing manually:**
   ```bash
   sudo pacman -S --noconfirm curl unzip
   ```

### Problem: "signature from GitLab CI Package Builder is unknown trust"

**Symptoms:**
```
error: curl: signature from "GitLab CI Package Builder <ci-package-builder-1@steamos.cloud>" is unknown trust
```

**Solution:**
This is a SteamOS-specific issue. The script should handle it automatically, but you can:

1. **Trust the SteamOS key:**
   ```bash
   sudo pacman-key --recv-keys AF1D2199EF0A3CCF
   sudo pacman-key --lsign-key AF1D2199EF0A3CCF
   ```

2. **Install without signature verification (safe for SteamOS):**
   ```bash
   sudo pacman -S --noconfirm --disable-download-timeout curl unzip
   ```

### Problem: "Package not found" errors

**Symptoms:**
```
error: target not found: curl
error: target not found: unzip
```

**Solution:**
1. **Update package database:**
   ```bash
   sudo pacman -Sy
   ```

2. **Check if packages are available:**
   ```bash
   pacman -Ss curl
   pacman -Ss unzip
   ```

---

## Network Issues

### Problem: Download failures

**Symptoms:**
```
Failed to download the mod. Please check your internet connection and try again.
```

**Solution:**
1. **Check internet connection:**
   ```bash
   ping google.com
   ```

2. **Test curl manually:**
   ```bash
   curl -I https://thunderstore.io
   ```

3. **Try downloading the mod manually:**
   ```bash
   curl -L -o /tmp/MoreUpgrades.zip "https://thunderstore.io/package/download/BULLETBOT/MoreUpgrades/1.4.8/"
   ```

4. **Check if Thunderstore is accessible:**
   - Open a web browser and go to https://thunderstore.io
   - If it doesn't load, there may be network restrictions

### Problem: Slow downloads or timeouts

**Solution:**
1. **Try with a different DNS server:**
   ```bash
   echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
   ```

2. **Check if you're behind a firewall or proxy**

---

## SteamOS Read-Only Mode

### Problem: "Read-only file system" errors

**Symptoms:**
```
mkdir: cannot create directory: Read-only file system
```

**Solution:**
1. **Disable read-only mode:**
   ```bash
   sudo steamos-readonly disable
   ```

2. **Run the script again**

3. **Re-enable read-only mode when done:**
   ```bash
   sudo steamos-readonly enable
   ```

**Note:** The script should handle this automatically, but you can do it manually if needed.

---

## Mod Installation Issues

### Problem: "Failed to install the mod"

**Symptoms:**
```
Failed to install the mod. Please check file permissions.
```

**Solution:**
1. **Check if the target directory exists:**
   ```bash
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/
   ```

2. **Create the directory manually if needed:**
   ```bash
   mkdir -p /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades
   ```

3. **Check file permissions:**
   ```bash
   ls -la /tmp/MoreUpgrades/
   ```

4. **Try copying manually:**
   ```bash
   cp /tmp/MoreUpgrades/* /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades/
   ```

### Problem: Mod files are corrupted

**Symptoms:**
```
Failed to extract the mod. The downloaded file may be corrupted.
```

**Solution:**
1. **Check the downloaded file:**
   ```bash
   file /tmp/MoreUpgrades/MoreUpgrades.zip
   ```

2. **Try downloading again:**
   ```bash
   rm /tmp/MoreUpgrades/MoreUpgrades.zip
   curl -L -o /tmp/MoreUpgrades/MoreUpgrades.zip "https://thunderstore.io/package/download/BULLETBOT/MoreUpgrades/1.4.8/"
   ```

3. **Test extraction manually:**
   ```bash
   unzip -t /tmp/MoreUpgrades/MoreUpgrades.zip
   ```

---

## r2modmanPlus Issues

### Problem: Mod doesn't appear in r2modmanPlus

**Symptoms:**
- Script completes successfully but mod doesn't show up in r2modmanPlus

**Solution:**
1. **Check if the mod files are in the right location:**
   ```bash
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades/
   ```

2. **Restart r2modmanPlus:**
   - Close r2modmanPlus completely
   - Reopen it
   - Check if the mod appears

3. **Check r2modmanPlus profile:**
   - Make sure you're using the "Friends" profile
   - Verify the profile path is correct

4. **Check BepInEx installation:**
   ```bash
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/
   ```

### Problem: Game crashes with the mod

**Solution:**
1. **Check BepInEx logs:**
   ```bash
   cat /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/LogOutput.log
   ```

2. **Verify mod compatibility:**
   - Make sure you're using the correct game version
   - Check if other mods are conflicting

3. **Try a clean installation:**
   - Remove the mod completely
   - Reinstall using the script

---

## SteamOS-Specific Issues

### Problem: SteamOS Package Signatures

**Issue:** SteamOS packages are signed by "GitLab CI Package Builder" which isn't in the standard Arch keyring.

**Symptoms:**
```
error: curl: signature from "GitLab CI Package Builder <ci-package-builder-1@steamos.cloud>" is unknown trust
```

**Solution:**
The script handles this automatically, but if it fails:

```bash
# Trust the SteamOS package builder key
sudo pacman-key --recv-keys AF1D2199EF0A3CCF
sudo pacman-key --lsign-key AF1D2199EF0A3CCF

# Try installing again
sudo pacman -S --noconfirm curl unzip
```

### Problem: SteamOS Keyring Not Initialized

**Issue:** SteamOS may not have pacman keyring initialized.

**Symptoms:**
```
warning: Public keyring not found; have you run 'pacman-key --init'?
error: keyring is not writable
```

**Solution:**
```bash
# Initialize keyring
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman-key --populate steamos
```

### Problem: SteamOS Network Configuration

**Issue:** SteamOS may have different network settings.

**Symptoms:**
- Downloads fail
- Package updates fail
- DNS resolution issues

**Solution:**
```bash
# Check network status
ip addr show

# Test connectivity
ping 8.8.8.8
ping google.com

# Check DNS
cat /etc/resolv.conf

# Try different DNS
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf
echo "nameserver 1.1.1.1" | sudo tee -a /etc/resolv.conf
```

### Problem: SteamOS File Permissions

**Issue:** SteamOS may have different default permissions.

**Symptoms:**
```
Permission denied
Operation not permitted
```

**Solution:**
```bash
# Check current permissions
ls -la /home/deck/.config/r2modmanPlus-local/

# Fix permissions if needed
sudo chown -R deck:deck /home/deck/.config/r2modmanPlus-local/
chmod -R 755 /home/deck/.config/r2modmanPlus-local/
```

### Problem: Gaming Mode vs Desktop Mode

**Issue:** Some operations may behave differently in Gaming Mode vs Desktop Mode.

**Solution:**
- Run the script in **Desktop Mode** for best results
- Gaming Mode may have restrictions on file system access
- Desktop Mode provides full terminal access

### Problem: r2modmanPlus Path Differences

**Issue:** r2modmanPlus paths may differ between SteamOS versions.

**Solution:**
```bash
# Find the correct r2modmanPlus path
find /home/deck -name "r2modmanPlus*" -type d 2>/dev/null

# Check common locations
ls -la /home/deck/.config/r2modmanPlus-local/
ls -la /home/deck/.local/share/r2modmanPlus/
```

### Problem: SteamOS Updates Breaking Mods

**Issue:** SteamOS updates may reset system changes.

**Solution:**
1. **After SteamOS updates:**
   - Re-run the mod installer script
   - Check if read-only mode was re-enabled
   - Verify r2modmanPlus still works

2. **Prevent issues:**
   - Keep a backup of your mod configuration
   - Document any manual changes you make

### Problem: SteamOS Version Compatibility

**Issue:** Script behavior may vary between SteamOS versions.

**Solution:**
```bash
# Check SteamOS version
cat /etc/os-release
cat /etc/steamos-release

# Check kernel version
uname -r

# Check if you're on stable or beta
cat /etc/steamos-release | grep -i beta
```

### Problem: SteamOS Recovery

**Issue:** Something went wrong and you need to recover.

**Solution:**
```bash
# Re-enable read-only mode
sudo steamos-readonly enable

# Reset pacman keyring if corrupted
sudo rm -rf /etc/pacman.d/gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux

# Remove mod files if needed
rm -rf /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades*

# Restart r2modmanPlus
# (Close and reopen the application)
```

---

## Advanced Troubleshooting

### Problem: Script fails with cryptic errors

**Solution:**
1. **Run the script with debug output:**
   ```bash
   bash -x ./modinstaller.sh
   ```

2. **Check system logs:**
   ```bash
   journalctl -f
   ```

3. **Verify SteamOS version:**
   ```bash
   cat /etc/os-release
   ```

### Problem: Dependencies are already installed but script fails

**Solution:**
1. **Check if packages are actually installed:**
   ```bash
   pacman -Q curl unzip
   ```

2. **Force reinstall:**
   ```bash
   sudo pacman -S --noconfirm --force curl unzip
   ```

### Problem: Script works but mod doesn't load in game

**Solution:**
1. **Check BepInEx is properly installed:**
   ```bash
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/
   ```

2. **Verify mod files:**
   ```bash
   file /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades/MoreUpgrades.dll
   ```

3. **Check game compatibility:**
   - Make sure you're using the correct version of Risk of Rain 2
   - Verify BepInEx version compatibility

---

## Getting Help

If none of these solutions work:

1. **Check the script output carefully** - look for specific error messages
2. **Try running each step manually** to isolate the problem
3. **Check SteamOS and r2modmanPlus documentation**
4. **Verify your SteamOS version** and mod compatibility

## Common Commands Reference

```bash
# Check script permissions
ls -la modinstaller.sh

# Make script executable
chmod +x modinstaller.sh

# Check sudo status
sudo -v

# Check read-only mode
sudo steamos-readonly status

# Disable read-only mode
sudo steamos-readonly disable

# Enable read-only mode
sudo steamos-readonly enable

# Check installed packages
pacman -Q curl unzip

# Check mod installation
ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades/

# Check BepInEx logs
cat /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/LogOutput.log
```

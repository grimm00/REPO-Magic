# Mod Rollback Script Troubleshooting Guide

This guide helps you resolve issues with the `modrollback.sh` script for r2modmanPlus on SteamOS.

## Quick Reference

| Problem | Quick Fix |
|---------|-----------|
| Script won't run | `chmod +x modrollback.sh` |
| No mods found | Check r2modmanPlus installation |
| Download fails | Check internet connection |
| Registry update fails | Check file permissions |
| Version not found | Try different version number |
| Missing dependencies | Script now checks automatically |
| Network issues | Script now checks connectivity |
| Disk space issues | Script now checks available space |
| Invalid input | Script now validates all inputs |

## Proactive Improvements

The script now includes several proactive improvements to prevent common issues:

### Automatic Checks
- **Dependency validation**: Checks for required tools (curl, unzip, file, etc.)
- **Network connectivity**: Tests connection to thunderstore.io before downloads
- **Disk space**: Verifies sufficient space (100MB minimum) before operations
- **Input validation**: Sanitizes and validates all user inputs

### Enhanced Logging
- **Automatic logging**: All operations logged to `/tmp/modrollback_YYYYMMDD_HHMMSS.log`
- **Verbose mode**: Use `-v` or `--verbose` flag for detailed logging
- **Error tracking**: Comprehensive error logging for troubleshooting

### Safety Features
- **Confirmation prompts**: Multiple confirmation steps for destructive operations
- **Automatic backups**: Creates backups of mods.yml before registry updates
- **Rollback protection**: Registry restoration if updates fail
- **Input sanitization**: Prevents injection attacks and invalid data

### Usage Examples
```bash
# Basic usage
./modrollback.sh

# Search for specific mod
./modrollback.sh MoreUpgrades

# Verbose logging
./modrollback.sh -v BULLETBOT

# Help
./modrollback.sh --help
```

## Recent Fixes and Issues

### Sed Character Class Error (FIXED)
```
sed: -e expression #1, char 21: Invalid range end
```

**Problem:** The hyphen `-` in sed character class `[^a-zA-Z0-9._- ]` was being interpreted as a range operator, causing validation failures.

**Solution:** Moved hyphen to end of character class: `[^a-zA-Z0-9._ -]`

### Search Function Not Finding Mods (FIXED)
```
No mods found matching 'moreupgrades'
```
But "BULLETBOT-MoreUpgrades" is visible in the list.

**Problem:** The `search_mods()` function was trying to parse the encrypted `mods.yml` file instead of searching plugin directories.

**Solution:** Updated search function to use directory-based search like the listing functions. Now correctly finds "BULLETBOT-MoreUpgrades" when searching for "moreupgrades".

### YAML File Corruption (FIXED)
```
YAML file can't be parsed... says there is trailing content
```

**Problem:** The mods.yml file was corrupted from manual edits, causing r2modmanPlus to show parsing errors. The file had duplicate content at the end and was missing proper YAML structure.

**Solution:** Cleaned the file by removing duplicate content:
```bash
# Remove duplicate content at the end of the file
head -1401 /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml > /tmp/mods_clean.yml
cp /tmp/mods_clean.yml /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
```

**Important Discovery:** The mods.yml file contains base64-encoded icon data embedded directly in the YAML structure. This is why the file is so large (9.6MB) and why it takes time to load. The base64 encoding is the correct format for r2modmanPlus.

**Null Bytes Issue:** The mods.yml file may contain null bytes (`\x00`) which can cause parsing issues in r2modmanPlus. These null bytes appear to be part of how r2modmanPlus stores the data, but they can cause "trailing content" errors.

**Prevention:** The mods.yml file contains complex base64-encoded data and should never be edited manually. Always use r2modmanPlus interface or our script's registry update functions.

## Common Issues and Solutions

### 1. Script Execution Problems

#### Problem: Permission Denied
```
bash: ./modrollback.sh: Permission denied
```

**Solution:**
```bash
chmod +x modrollback.sh
./modrollback.sh
```

#### Problem: Command Not Found
```
bash: ./modrollback.sh: No such file or directory
```

**Solutions:**
1. Check you're in the right directory:
   ```bash
   ls -la modrollback.sh
   ```

2. Use full path:
   ```bash
   /home/deck/Projects/REPO-Magic/modrollback.sh
   ```

3. Run with bash explicitly:
   ```bash
   bash modrollback.sh
   ```

### 2. Mod Discovery Issues

#### Problem: No Mods Found
```
No mods found in r2modmanPlus registry.
```

**Causes and Solutions:**

1. **r2modmanPlus not installed:**
   ```bash
   # Check if r2modmanPlus is installed
   ls -la /home/deck/.config/r2modmanPlus-local/
   ```

2. **Wrong profile path:**
   - Check your r2modmanPlus profile name
   - Default path assumes "Friends" profile
   - Update script if using different profile

3. **mods.yml missing:**
   ```bash
   # Check if mods.yml exists
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
   ```

4. **No mods installed:**
   - Install some mods through r2modmanPlus first
   - The rollback script only works with existing mods

#### Problem: Mod Search Not Working
```
No mods found matching 'searchterm'
```

**Solutions:**

1. **Try partial matches:**
   - Search for "MoreUpgrades" instead of "BULLETBOT-MoreUpgrades"
   - Search is case-insensitive

2. **Check exact mod name:**
   ```bash
   # View all installed mods
   cat /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml | grep "name:"
   ```

3. **Use broader search:**
   - Try searching for just the author name
   - Try searching for part of the mod name

### 3. Version Management Issues

#### Problem: Invalid Version Format
```
Error: Invalid version format. Please use format like 1.3.5
```

**Solution:**
- Use semantic versioning: `MAJOR.MINOR.PATCH`
- Examples: `1.4.8`, `2.0.0`, `1.3.5`
- Don't use: `v1.4.8`, `1.4`, `1.4.8.1`

#### Problem: Version Rollback Below Zero
```
Error: Cannot rollback patch version below 0
```

**Solutions:**

1. **Choose different rollback option:**
   - Instead of patch rollback, try minor rollback
   - Use custom version input

2. **Check current version:**
   - Make sure you're not already at version 0.0.0
   - Some mods start at version 1.0.0

#### Problem: Custom Version Not Found
```
Failed to download mod. The version may not exist.
```

**Solutions:**

1. **Check version exists on Thunderstore:**
   - Visit: `https://thunderstore.io/c/repo/p/AUTHOR/MODNAME/`
   - Look for available versions

2. **Try different version:**
   - Use a version you know exists
   - Check the mod's release history

3. **Verify mod name format:**
   - Thunderstore uses `AUTHOR/MODNAME` format
   - Script converts `AUTHOR-MODNAME` automatically

### 4. Download and Installation Issues

#### Problem: Download Fails
```
Failed to download mod. The version may not exist.
```

**Causes and Solutions:**

1. **Network connectivity:**
   ```bash
   # Test internet connection
   ping -c 3 thunderstore.io
   ```

2. **Version doesn't exist:**
   - Check Thunderstore for available versions
   - Try a different version number

3. **URL generation error:**
   - Check mod name format in registry
   - Should be `AUTHOR-MODNAME` format

4. **Thunderstore server issues:**
   - Wait a few minutes and try again
   - Check Thunderstore status

#### Problem: Extraction Fails
```
Failed to extract mod. The downloaded file may be corrupted.
End-of-central-directory signature not found. Either this file is not
a zipfile, or it constitutes one disk of a multi-part archive.
```

**Causes and Solutions:**

1. **Download URL already points to zip file:**
   - Thunderstore download URLs often point directly to `.zip` files
   - Script may be trying to extract a file that's already extracted
   - **Solution:** Check if downloaded file is already a zip file before extraction

2. **Corrupted download:**
   ```bash
   # Check file size and type
   ls -la /tmp/*/MoreUpgrades.zip
   file /tmp/*/MoreUpgrades.zip
   ```

3. **Incomplete download:**
   - Check internet connection stability
   - Try downloading again

**Solutions:**

1. **Re-download:**
   - Run the script again
   - The issue might be temporary

2. **Check disk space:**
   ```bash
   df -h /tmp
   ```

3. **Manual download test:**
   ```bash
   # Test download manually
   curl -L -o test.zip "DOWNLOAD_URL"
   unzip -t test.zip
   ```

#### Problem: Installation Fails
```
Failed to install mod files.
```

**Causes and Solutions:**

1. **Permission issues:**
   ```bash
   # Check plugin directory permissions
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/
   ```

2. **Directory doesn't exist:**
   ```bash
   # Create plugin directory if missing
   mkdir -p /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/
   ```

3. **Disk space:**
   ```bash
   df -h /home/deck/.config/
   ```

### 5. Registry Management Issues

#### Problem: YAML File Corruption
```
YAML file can't be parsed... says there is trailing content
```

**Causes and Solutions:**

1. **Manual edits to mods.yml:**
   - The mods.yml file is base64 encoded/encrypted and should not be edited manually
   - Manual edits can corrupt the file structure
   - **Solution:** Restore from backup

2. **Restore from backup:**
   ```bash
   # Check for backup files
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml*
   
   # Restore from backup (replace timestamp with actual backup file)
   cp /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml.backup.TIMESTAMP /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
   ```

3. **Prevention:**
   - Always backup mods.yml before making changes
   - Use r2modmanPlus interface for mod management when possible
   - Only use the rollback script for version changes

#### Problem: Version Mismatch Between Registry and Plugin Directory
```
Registry shows version 1.5.1 but plugin directory shows 1.4.8
```

**Causes and Solutions:**

1. **Multiple installations:**
   - Managed installation (tracked by r2modmanPlus registry)
   - Unmanaged installation (manually installed files)
   - **Solution:** The rollback script reads from plugin directories, which shows the actual installed version

2. **Registry vs Reality:**
   - The mods.yml registry may show different versions than what's actually installed
   - This is normal when mods are installed manually or through different methods
   - **Solution:** Trust the plugin directory version as the source of truth

3. **Verification:**
   ```bash
   # Check actual installed version
   cat /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades/manifest.json | grep version_number
   
   # Check registry version (encoded, not easily readable)
   head -20 /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
   ```

#### Problem: Registry Update Fails
```
Failed to update mod registry.
```

**Causes and Solutions:**

1. **File permissions:**
   ```bash
   # Check mods.yml permissions
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
   ```

2. **File locked:**
   - Close r2modmanPlus if it's running
   - Try running the script again

3. **Backup creation fails:**
   ```bash
   # Check backup directory permissions
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/
   ```

#### Problem: Mod Not Appearing in r2modmanPlus
After successful rollback, mod doesn't show in r2modmanPlus.

**Solutions:**

1. **Restart r2modmanPlus:**
   - Close the application completely
   - Reopen r2modmanPlus

2. **Check registry format:**
   ```bash
   # Verify YAML format
   tail -20 /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
   ```

3. **Manual registry check:**
   ```bash
   # Look for your mod in the registry
   grep -A 10 "YourModName" /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
   ```

### 6. SteamOS-Specific Issues

#### Problem: Read-Only Mode Issues
```
Warning: Could not disable read-only mode.
```

**Solutions:**

1. **Manual disable:**
   ```bash
   sudo steamos-readonly disable
   ```

2. **Check if already disabled:**
   ```bash
   steamos-readonly status
   ```

3. **Re-enable after script:**
   ```bash
   sudo steamos-readonly enable
   ```

#### Problem: Sudo Authentication Issues
```
Sudo authentication failed.
```

**Solutions:**

1. **First-time sudo setup:**
   - Follow the prompts to set a password
   - Use a password you'll remember

2. **Wrong password:**
   - Try again with correct password
   - Password won't be visible as you type

3. **Sudo not configured:**
   ```bash
   # Test sudo access
   sudo -v
   ```

#### Problem: Package Installation Fails
```
Failed to install dependencies.
```

**Solutions:**

1. **SteamOS keyring issues:**
   ```bash
   # Initialize keyring
   sudo pacman-key --init
   sudo pacman-key --populate archlinux
   sudo pacman-key --populate steamos
   ```

2. **Trust SteamOS keys:**
   ```bash
   sudo pacman-key --recv-keys AF1D2199EF0A3CCF
   sudo pacman-key --lsign-key AF1D2199EF0A3CCF
   ```

3. **Manual dependency install:**
   ```bash
   sudo pacman -S --noconfirm curl unzip
   ```

### 7. Advanced Troubleshooting

#### Problem: Script Hangs or Freezes
The script stops responding during execution.

**Solutions:**

1. **Check for stuck processes:**
   ```bash
   ps aux | grep modrollback
   ```

2. **Kill stuck processes:**
   ```bash
   pkill -f modrollback
   ```

3. **Check system resources:**
   ```bash
   top
   df -h
   ```

#### Problem: Corrupted Registry
The mods.yml file becomes corrupted after rollback.

**Solutions:**

1. **Restore from backup:**
   ```bash
   # List available backups
   ls -la /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml.backup.*
   
   # Restore most recent backup
   cp /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml.backup.* /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
   ```

2. **Recreate registry:**
   - Uninstall and reinstall mods through r2modmanPlus
   - This will recreate a clean registry

#### Problem: Multiple Mod Versions
Multiple entries for the same mod in registry.

**Solutions:**

1. **Clean registry manually:**
   ```bash
   # Edit mods.yml to remove duplicates
   nano /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
   ```

2. **Use r2modmanPlus:**
   - Uninstall the mod through r2modmanPlus
   - Reinstall the desired version

## Debugging Tips

### Enable Verbose Output
Add debug information to the script:
```bash
# Add this line near the top of the script
set -x
```

### Check Script Logs
The script creates temporary files that can help debug:
```bash
# Check temp directory
ls -la /tmp/*rollback*
```

### Manual Testing
Test individual components:
```bash
# Test mod discovery
awk '/^  name:/ {print}' /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml

# Test download URL
curl -I "https://thunderstore.io/package/download/AUTHOR/MODNAME/VERSION/"

# Test registry format
grep -A 5 -B 5 "YourModName" /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
```

## Getting Help

If you're still having issues:

1. **Check the main troubleshooting guide:** [README.md](README.md)
2. **Review SteamOS-specific issues:** [README.md#steamos-specific-issues](README.md#steamos-specific-issues)
3. **Check r2modmanPlus documentation:** [r2modmanplus-integration.md](../r2modmanplus-integration.md)

## Prevention Tips

1. **Always backup before rollback:**
   - The script creates automatic backups
   - Keep manual backups of important mods

2. **Test rollbacks on non-critical mods first:**
   - Try rolling back a simple mod first
   - Verify the process works before important rollbacks

3. **Keep r2modmanPlus updated:**
   - Use the latest version of r2modmanPlus
   - Check for updates regularly

4. **Monitor disk space:**
   - Ensure adequate free space for downloads
   - Clean up old backups periodically

5. **Use version control:**
   - Keep track of which mod versions work well
   - Document successful rollback procedures

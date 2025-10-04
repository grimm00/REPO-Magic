# MoreUpgrades Mod Installer for SteamOS

This script helps you easily install a rollback version of the MoreUpgrades mod for Risk of Rain 2 on SteamOS.

## What this script does:
- Automatically removes any existing MoreUpgrades installations
- Temporarily disables SteamOS read-only mode (re-enabled automatically)
- Installs required dependencies (curl, unzip)
- Downloads and installs the MoreUpgrades mod version 1.4.8
- Installs the mod to your r2modmanPlus profile
- Re-enables SteamOS read-only mode for security

## How to use:

1. **Open Konsole** (Terminal) on your Steam Deck
2. **Navigate to the script location:**
   ```bash
   cd /path/to/this/folder
   ```
3. **Make the script executable:**
   ```bash
   chmod +x modinstaller.sh
   ```
4. **Run the script:**
   ```bash
   ./modinstaller.sh
   ```
5. **Enter your SteamOS password** when prompted
   - If this is your first time using sudo, you'll be prompted to set a new password
   - The password won't be visible as you type (this is normal for security)
6. **Wait for installation to complete**

## Requirements:
- SteamOS with r2modmanPlus installed
- Internet connection
- Sudo privileges (you'll be prompted for password)

## First-time sudo setup:
If you've never used the terminal before, the first time you run `sudo`, SteamOS will ask you to:
1. Set a new sudo password (choose something you'll remember)
2. Confirm the password by typing it again
3. Use this password for future sudo operations

## Troubleshooting:
- **Documentation index:** See [docs/troubleshooting/index.md](docs/troubleshooting/index.md) for overview
- **Quick fixes:** See [docs/troubleshooting/quick-fixes.md](docs/troubleshooting/quick-fixes.md) for common solutions
- **Detailed guide:** See [docs/troubleshooting/README.md](docs/troubleshooting/README.md) for comprehensive troubleshooting
- **SteamOS issues:** The troubleshooting guide includes SteamOS-specific solutions

### Common Issues:
- If you get "permission denied", make sure you ran `chmod +x modinstaller.sh`
- If download fails, check your internet connection
- If installation fails, make sure r2modmanPlus is properly set up
- If you get "keyring is not writable" or "required key missing" errors:
  1. The script will try to fix this automatically
  2. If it still fails, try: `sudo steamos-readonly disable` then run the script again
  3. This is a common SteamOS issue with package management

The mod will be installed to: `/home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/BepInEx/plugins/MoreUpgrades/` 

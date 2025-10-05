# Modular Structure Documentation

This document describes the new modular structure of the REPO-Magic project, which provides both single-file scripts for ease of use and modular libraries for maintainability.

## Overview

The project now offers two approaches:

1. **Single Script Files** - Easy to use, self-contained scripts for your friends
2. **Modular Libraries** - Organized, maintainable code structure for developers

## File Structure

```
REPO-Magic/
├── modinstaller.sh              # Modular installer (main version)
├── modrollback.sh               # Modular rollback script (main version)
├── modinstaller-simple.sh       # Single-file installer (simple version)
├── modrollback-simple.sh        # Single-file rollback script (simple version)
├── clean_mods_yml.sh            # Standalone YAML cleanup tool
├── lib/                         # Modular libraries
│   ├── yaml_utils.sh           # YAML manipulation functions
│   ├── registry_utils.sh       # Registry update functions
│   ├── mod_utils.sh            # Mod discovery and selection
│   ├── steamos_utils.sh        # SteamOS-specific functions
│   └── logging_utils.sh        # Logging and validation
└── docs/                        # Documentation
    ├── modular-structure.md    # This file
    └── troubleshooting/        # Troubleshooting guides
```

## Library Descriptions

### `lib/yaml_utils.sh`
**Purpose**: YAML file manipulation and validation
**Functions**:
- `clean_mods_yml()` - Clean and validate mods.yml files
- `validate_yaml()` - Validate YAML syntax
- `yaml_to_json()` - Convert YAML to JSON for jq processing
- `json_to_yaml()` - Convert JSON back to YAML

### `lib/registry_utils.sh`
**Purpose**: r2modmanPlus registry management using jq
**Functions**:
- `update_mod_registry()` - Update mod registry for rollbacks
- `add_mod_to_registry()` - Add new mod to registry
- `mod_exists_in_registry()` - Check if mod exists in registry
- `get_mod_version_from_registry()` - Get mod version from registry

### `lib/mod_utils.sh`
**Purpose**: Mod discovery, selection, and installation
**Functions**:
- `list_installed_mods()` - List all installed mods
- `search_mods()` - Search for mods by name/author
- `get_mod_selection()` - Interactive mod selection
- `get_rollback_version()` - Get rollback version from user
- `download_and_install_mod()` - Download and install mod
- `validate_input()` - Input validation and sanitization

### `lib/steamos_utils.sh`
**Purpose**: SteamOS-specific system management
**Functions**:
- `is_steamos()` - Check if running on SteamOS
- `disable_steamos_readonly()` - Disable read-only mode
- `enable_steamos_readonly()` - Enable read-only mode
- `check_dependencies()` - Check and install dependencies
- `check_network()` - Check network connectivity
- `check_disk_space()` - Check available disk space
- `check_r2modman_running()` - Check if r2modmanPlus is running

### `lib/logging_utils.sh`
**Purpose**: Logging, validation, and utility functions
**Functions**:
- `init_logging()` - Initialize logging system
- `log_message()` - Log messages with levels
- `validate_input()` - Input validation
- `confirm_action()` - User confirmation prompts
- `create_backup()` - Create file backups
- `restore_backup()` - Restore from backups
- `cleanup_on_exit()` - Cleanup temporary files

## Usage Examples

### Main Scripts (Modular - Recommended)

```bash
# Install MoreUpgrades mod
./modinstaller.sh

# Rollback a mod (interactive)
./modrollback.sh

# Rollback specific mod
./modrollback.sh moreupgrades

# Verbose mode
./modrollback.sh -v moreupgrades

# Clean corrupted mods.yml
./clean_mods_yml.sh
```

### Simple Scripts (Single-file - For Friends)

```bash
# Install MoreUpgrades mod (simple)
./modinstaller-simple.sh

# Rollback a mod (simple)
./modrollback-simple.sh

# Rollback specific mod (simple)
./modrollback-simple.sh moreupgrades
```

## Benefits of Modular Structure

### For Users (Main Scripts - Modular)
- ✅ **Maintainable**: Code organized into logical modules
- ✅ **Reusable**: Libraries can be used in other projects
- ✅ **Testable**: Individual functions can be tested
- ✅ **Extensible**: Easy to add new functionality
- ✅ **Readable**: Smaller, focused files
- ✅ **Robust**: Better error handling and validation

### For Friends (Simple Scripts - Single-file)
- ✅ **Simple**: One file to download and run
- ✅ **Self-contained**: All functionality in one script
- ✅ **Easy to share**: Just send one file to friends
- ✅ **No dependencies**: Works out of the box

## Adding New Features

### To Single Scripts
1. Add the function directly to the script
2. Update the main execution flow
3. Test the complete script

### To Modular Scripts
1. Add the function to the appropriate library
2. Source the library in the main script
3. Call the function from the main execution flow
4. Test both the library and the main script

## Migration Guide

### From Simple to Main (Modular)
If you want to use the main modular version:

1. **Use the main scripts**:
   ```bash
   # Instead of modrollback-simple.sh, use:
   ./modrollback.sh
   ```

2. **All libraries are included** - no additional setup needed

3. **Enhanced functionality** - the main version has additional features

### From Main to Simple
If you prefer the single-file approach:

1. **Use the simple scripts**:
   ```bash
   ./modrollback-simple.sh
   ./modinstaller-simple.sh
   ```

2. **No changes needed** - the simple scripts remain unchanged

## Troubleshooting

### Library Loading Issues
If you get "library not found" errors:

1. **Check file permissions**:
   ```bash
   chmod +x lib/*.sh
   ```

2. **Verify library paths**:
   ```bash
   ls -la lib/
   ```

3. **Check script directory**:
   ```bash
   pwd
   ```

### Function Not Found
If you get "function not found" errors:

1. **Check library sourcing**:
   ```bash
   grep "source.*lib" modrollback-modular.sh
   ```

2. **Verify function exists**:
   ```bash
   grep "function_name" lib/*.sh
   ```

## Future Enhancements

The modular structure makes it easy to add:

- **New mod managers** (Thunderstore, Nexus, etc.)
- **Additional platforms** (Windows, macOS, Linux)
- **Advanced features** (mod dependencies, conflict detection)
- **GUI interfaces** (using the same libraries)
- **API integrations** (mod database lookups)

## Contributing

When contributing to the project:

1. **For bug fixes**: Update both single and modular versions
2. **For new features**: Add to modular libraries first, then integrate into single scripts
3. **For documentation**: Update both this file and individual library documentation
4. **For testing**: Test both single and modular versions

This ensures that users get the benefits of both approaches while maintaining code quality and consistency.

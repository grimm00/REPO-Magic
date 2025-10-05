# Profile Resolution Issues

## Problem: Scripts showing mods from wrong profile

### Symptoms
- Running `./modrollback.sh --profile Friends` shows mods from Default profile
- Profile resolution appears correct (shows "Using profile: Friends")
- But mod discovery finds mods from a different profile

### Root Cause
The issue is in the library sourcing order in `modrollback.sh` and `modinstaller.sh`:

```bash
# Current (problematic) order:
source "$SCRIPT_DIR/lib/mod_utils.sh"      # MOD_PLUGIN_PATH is empty here
source "$SCRIPT_DIR/lib/profile_utils.sh"  # resolve_profile() sets MOD_PLUGIN_PATH later
```

When `mod_utils.sh` is sourced, `MOD_PLUGIN_PATH` is still empty. The `resolve_profile()` function is called later in the script execution, but the `mod_utils.sh` functions are already loaded with the empty `MOD_PLUGIN_PATH` value.

### Solution
Move `profile_utils.sh` sourcing before `mod_utils.sh`:

```bash
# Fixed order:
source "$SCRIPT_DIR/lib/profile_utils.sh"  # Load profile utilities first
source "$SCRIPT_DIR/lib/mod_utils.sh"      # Now MOD_PLUGIN_PATH will be set when needed
```

### Files to Fix
- `modrollback.sh` - Reorder library sourcing
- `modinstaller.sh` - Reorder library sourcing

### Testing
After fixing, test with:
```bash
# Should show Friends profile mods
./modrollback.sh --profile Friends

# Should show Default profile mods  
./modrollback.sh --profile Default

# Should show Kat profile mods
./modrollback.sh --profile Kat
```

### Prevention
- Always source profile utilities before mod utilities
- Consider making MOD_PLUGIN_PATH a parameter to mod utility functions instead of relying on global variables
- Add validation in mod utility functions to ensure MOD_PLUGIN_PATH is set

## Related Issues

### Profile Fallback Logic
The current fallback logic in `resolve_profile()` may be too aggressive:
- If Friends profile doesn't exist, it falls back to Default
- This could mask the real issue if profile paths are wrong

### Global Variable Dependencies
The mod utilities rely on global variables set by profile utilities:
- `MOD_PLUGIN_PATH`
- `MODS_YML`
- `PROFILE_PATH`

Consider refactoring to pass these as parameters to avoid dependency issues.

## Solution: Switch to mods.yml-based Discovery

### Root Cause Analysis
After investigation, the issue is not just library sourcing order, but the fundamental approach to mod discovery. The current filesystem-based approach has several problems:

1. **Variable scope issues** with MOD_PLUGIN_PATH in subshells
2. **Filesystem sync issues** between actual files and r2modmanPlus state
3. **Complex logic** prone to edge cases and bugs

### New Approach: mods.yml-based Discovery
Instead of scanning the filesystem for `manifest.json` files, we'll use the `mods.yml` file as the authoritative source:

**Advantages**:
- ✅ Single source of truth (r2modmanPlus managed)
- ✅ Already parsed and validated
- ✅ Contains all metadata (author, version, enabled status)
- ✅ More reliable and consistent
- ✅ Simpler implementation
- ✅ No variable scope issues

**Implementation**:
- Parse `mods.yml` using `jq` (already available)
- Extract mod names, authors, versions directly
- Use existing YAML utilities in `lib/yaml_utils.sh`

### Files to Update
- `lib/mod_utils.sh` - Replace filesystem scanning with mods.yml parsing
- `lib/yaml_utils.sh` - Add mod discovery functions
- Update all scripts that use mod discovery

## Status
- **Identified**: October 5, 2025
- **Root Cause**: Filesystem-based discovery approach
- **Solution**: Switch to mods.yml-based discovery
- **Priority**: High (affects core functionality)
- **Implementation**: Part of Task 2

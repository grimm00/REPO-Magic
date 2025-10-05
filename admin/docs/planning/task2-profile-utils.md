# Task 2: Shared Profile Helper and Path Portability

## Objective
Create a shared profile utility library to eliminate duplicate `resolve_profile()` logic between `modinstaller.sh` and `modrollback.sh`, add path portability via `R2MODMAN_BASE` environment variable, and implement profile name sanitization for security.

## Current State Analysis

### Duplicate Code Identified
Both scripts have nearly identical `resolve_profile()` functions:

**modinstaller.sh (lines 142-166)**:
```bash
resolve_profile() {
    local profiles_base="/home/deck/.config/r2modmanPlus-local/REPO/profiles"
    if [ -z "$PROFILE_NAME" ]; then
        PROFILE_NAME="Default"
    fi
    PROFILE_PATH="$profiles_base/$PROFILE_NAME"
    # ... rest of function
}
```

**modrollback.sh (lines 93-114)**:
```bash
resolve_profile() {
    local profiles_base="/home/deck/.config/r2modmanPlus-local/REPO/profiles"
    if [ -z "$PROFILE_NAME" ]; then
        PROFILE_NAME="Default"
    fi
    PROFILE_PATH="$profiles_base/$PROFILE_NAME"
    # ... rest of function
}
```

### Hardcoded Paths
- Both scripts use hardcoded `/home/deck/.config/r2modmanPlus-local`
- `scripts/standalone/clean_mods_yml.sh` also has hardcoded path on line 7

## Implementation Plan

### 1. Create lib/profile_utils.sh

**File**: `lib/profile_utils.sh` (new)

**Functions to implement**:

#### `get_profiles_base()`
```bash
get_profiles_base() {
    echo "${R2MODMAN_BASE:-$HOME/.config/r2modmanPlus-local}/REPO/profiles"
}
```
- Returns configurable base path
- Uses `R2MODMAN_BASE` environment variable if set
- Falls back to default SteamOS path

#### `sanitize_profile_name(name)`
```bash
sanitize_profile_name() {
    local name="$1"
    
    # Check for empty input
    if [ -z "$name" ]; then
        echo "Default"
        return 0
    fi
    
    # Remove dangerous characters and patterns
    if [[ "$name" =~ \.\. ]] || [[ "$name" =~ / ]] || [[ "$name" =~ \\ ]]; then
        echo "Error: Profile name contains path traversal characters" >&2
        exit 1
    fi
    
    # Check for leading dash (could be interpreted as flag)
    if [[ "$name" =~ ^- ]]; then
        echo "Error: Profile name cannot start with '-'" >&2
        exit 1
    fi
    
    # Validate allowed characters: A-Z, a-z, 0-9, ., _, space, -
    if [[ ! "$name" =~ ^[A-Za-z0-9._ -]+$ ]]; then
        echo "Error: Profile name contains invalid characters" >&2
        exit 1
    fi
    
    # Limit length
    if [ ${#name} -gt 50 ]; then
        echo "Error: Profile name too long (max 50 characters)" >&2
        exit 1
    fi
    
    # Trim whitespace
    name=$(echo "$name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    echo "$name"
}
```

#### `resolve_profile(profile_name)`
```bash
resolve_profile() {
    local input_profile="$1"
    
    # Sanitize the profile name
    PROFILE_NAME=$(sanitize_profile_name "$input_profile")
    
    # Get profiles base path
    local profiles_base=$(get_profiles_base)
    PROFILE_PATH="$profiles_base/$PROFILE_NAME"
    
    # Check if profile directory exists
    if [ ! -d "$PROFILE_PATH" ]; then
        echo -e "${YELLOW}Profile '$PROFILE_NAME' not found under $profiles_base${NC}"
        if [ "$PROFILE_NAME" != "Default" ] && [ -d "$profiles_base/Default" ]; then
            echo -e "${YELLOW}Falling back to 'Default' profile${NC}"
            PROFILE_NAME="Default"
            PROFILE_PATH="$profiles_base/Default"
        else
            echo -e "${YELLOW}Proceeding with profile path even if not present (it may be created on first run)${NC}"
        fi
    fi
    
    # Set derived paths
    export MOD_PLUGIN_PATH="$PROFILE_PATH/BepInEx/plugins"
    MODS_YML="$PROFILE_PATH/mods.yml"
    
    # Print profile information
    echo -e "${BLUE}Using profile:${NC} $PROFILE_NAME"
    echo -e "${BLUE}Plugins path:${NC} $MOD_PLUGIN_PATH"
    echo -e "${BLUE}mods.yml path:${NC} $MODS_YML"
}
```

### 2. Update modinstaller.sh

**Changes needed**:
- Add `source "$SCRIPT_DIR/lib/profile_utils.sh"` after line 14
- Remove `resolve_profile()` function (lines 142-166)
- Keep existing call to `resolve_profile()` in `init_script()`
- Update `MOD_INSTALL_PATH_REPO` assignment to use `MOD_PLUGIN_PATH`

### 3. Update modrollback.sh

**Changes needed**:
- Add `source "$SCRIPT_DIR/lib/profile_utils.sh"` after line 15
- Remove `resolve_profile()` function (lines 93-114)
- Keep existing call to `resolve_profile()` in `init_script()`

### 4. Update scripts/standalone/clean_mods_yml.sh

**Changes needed**:
- Replace line 7: `MODS_YML="/home/deck/.config/r2modmanPlus-local/REPO/profiles/${PROFILE_NAME}/mods.yml"`
- Change to: `MODS_YML="${R2MODMAN_BASE:-$HOME/.config/r2modmanPlus-local}/REPO/profiles/${PROFILE_NAME}/mods.yml"`

### 5. Switch to mods.yml-based Mod Discovery

**Problem Identified**: The current filesystem-based mod discovery has variable scope issues and filesystem sync problems, causing scripts to show mods from wrong profiles.

**New Approach**: Use `mods.yml` as the authoritative source for mod discovery instead of scanning filesystem for `manifest.json` files.

**Implementation**:
- Add new functions to `lib/yaml_utils.sh`:
  - `list_mods_from_yml()` - Parse mods.yml and return mod list
  - `search_mods_from_yml()` - Search mods in mods.yml by name
- Update `lib/mod_utils.sh`:
  - Replace `list_installed_mods()` with mods.yml-based version
  - Replace `search_mods()` with mods.yml-based version
  - Remove filesystem scanning logic
- Benefits:
  - ✅ Single source of truth (r2modmanPlus managed)
  - ✅ No variable scope issues
  - ✅ More reliable and consistent
  - ✅ Simpler implementation
  - ✅ Contains all metadata (author, version, enabled status)

### 6. Address HIGH Priority Sourcery Code Quality Issues

**Problem Identified**: Sourcery review identified 2 HIGH priority bug risks in the profile utilities implementation.

**Issues Found**:
1. **Comment #2**: Whitespace trimming happened after validation, rejecting valid profile names with leading/trailing spaces
2. **Comment #3**: `MODS_YML` variable wasn't exported, potentially causing issues in subshells

**Implementation**:
- **Fix Comment #2**: Move whitespace trimming to beginning of `sanitize_profile_name()` function
  - Trim whitespace before validation checks
  - Add check for empty names after trimming
  - Prevents rejection of valid profile names like `" Friends "`
- **Fix Comment #3**: Export `MODS_YML` variable in `resolve_profile()` function
  - Add `export` keyword to make it consistent with `MOD_PLUGIN_PATH`
  - Ensures `MODS_YML` is available in subshells and downstream scripts
- Benefits:
  - ✅ Prevents user issues with profile names containing whitespace
  - ✅ Ensures mod discovery works correctly in all contexts
  - ✅ Simple one-line fixes with high impact
  - ✅ No breaking changes, only improvements

## Files to Change

### New Files
- `lib/profile_utils.sh` - Shared profile utility library

### Modified Files
- `modinstaller.sh` - Source new lib, remove duplicate function
- `modrollback.sh` - Source new lib, remove duplicate function  
- `scripts/standalone/clean_mods_yml.sh` - Use R2MODMAN_BASE
- `lib/yaml_utils.sh` - Add mods.yml-based discovery functions
- `lib/mod_utils.sh` - Replace filesystem scanning with mods.yml parsing

## Testing Strategy

### Basic Functionality Tests
```bash
# Test default profile
SKIP_DEPENDENCY_CHECK=true ./modrollback.sh --profile Default
SKIP_DEPENDENCY_CHECK=true ./modinstaller.sh --profile Default

# Test without profile argument (should default to "Default")
SKIP_DEPENDENCY_CHECK=true ./modrollback.sh
```

### Path Portability Tests
```bash
# Test custom R2MODMAN_BASE
R2MODMAN_BASE=/tmp/test-r2modman ./modrollback.sh --profile Default
R2MODMAN_BASE=/tmp/test-r2modman ./scripts/standalone/clean_mods_yml.sh Default
```

### Input Validation Tests
```bash
# Test invalid profile names (should reject)
./modrollback.sh --profile "../../etc"
./modrollback.sh --profile "/etc/passwd"
./modrollback.sh --profile "-malicious"
./modrollback.sh --profile "profile with spaces and symbols!@#"

# Test valid profile names (should work)
./modrollback.sh --profile "MyProfile"
./modrollback.sh --profile "test-profile_123"
```

### Edge Case Tests
```bash
# Test very long profile name (should reject)
./modrollback.sh --profile "this_is_a_very_long_profile_name_that_exceeds_fifty_characters"

# Test empty profile name (should default to "Default")
./modrollback.sh --profile ""
```

### Mod Discovery Tests (mods.yml-based)
```bash
# Test mod discovery with different profiles
./modrollback.sh --profile Friends  # Should show Friends profile mods from mods.yml
./modrollback.sh --profile Default  # Should show Default profile mods from mods.yml
./modrollback.sh --profile Kat      # Should show Kat profile mods from mods.yml

# Test mod search functionality
./modrollback.sh --profile Friends --search "Spindles"  # Should find Spindles mods
./modrollback.sh --profile Default --search "MoreUpgrades"  # Should find MoreUpgrades

# Test mods.yml parsing
jq -r '.[].name' /home/deck/.config/r2modmanPlus-local/REPO/profiles/Friends/mods.yml
```

## Acceptance Criteria

- ✅ Both main scripts source shared lib, no duplication
- ✅ `R2MODMAN_BASE` environment variable works for custom paths
- ✅ Invalid profile names are rejected with clear error messages
- ✅ Default fallback behavior preserved
- ✅ All three scripts use consistent path logic
- ✅ Profile name sanitization prevents path traversal attacks
- ✅ **Mod discovery uses mods.yml as authoritative source**
- ✅ **Scripts show correct mods for each profile**
- ✅ **No variable scope issues with mod discovery**
- ✅ **HIGH priority Sourcery bug fixes implemented (Comments #2 & #3)**
- ✅ **Whitespace trimming works correctly in profile names**
- ✅ **MODS_YML properly exported for subshell compatibility**
- ✅ Existing functionality unchanged for valid inputs

## Risk Mitigation

### Potential Issues
1. **Breaking existing functionality**: Mitigated by preserving exact same behavior for valid inputs
2. **Path resolution errors**: Mitigated by comprehensive testing with various R2MODMAN_BASE values
3. **Profile name validation too strict**: Mitigated by allowing common valid characters

### Rollback Plan
If issues arise, we can quickly revert by:
1. Restoring the duplicate `resolve_profile()` functions
2. Removing the `source` statements
3. Reverting `clean_mods_yml.sh` path change

## Implementation Order

1. Create `lib/profile_utils.sh` with all three functions
2. Test the library functions independently
3. Update `modinstaller.sh` and test
4. Update `modrollback.sh` and test
5. Update `scripts/standalone/clean_mods_yml.sh` and test
6. **Add mods.yml-based discovery functions to `lib/yaml_utils.sh`**
7. **Update `lib/mod_utils.sh` to use mods.yml instead of filesystem scanning**
8. **Test mod discovery with different profiles**
9. **Address HIGH priority Sourcery code quality issues (Comments #2 & #3)**
10. Run comprehensive test suite
11. Commit and push changes

## Success Metrics

- Code duplication eliminated (DRY principle)
- Path portability achieved via R2MODMAN_BASE
- Security improved with input validation
- **Mod discovery reliability improved (mods.yml-based)**
- **Profile-specific mod lists working correctly**
- **HIGH priority code quality issues addressed (Sourcery Comments #2 & #3)**
- **Profile name whitespace handling improved**
- **MODS_YML export consistency achieved**
- All existing functionality preserved
- Clear error messages for invalid inputs

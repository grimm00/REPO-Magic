# Maintenance Plan Progress

## Overview
Tracking progress on the maintenance and refactor plan outlined in `maintenance-plan.md`.

## Completed Tasks

### ✅ Task 1: Folder Restructure for Standalone Tools
**Status**: COMPLETED  
**Date**: October 5, 2025  
**Commit**: `d477af6`

**What was done**:
- Created `scripts/standalone/` directory
- Moved standalone scripts:
  - `clean_mods_yml.sh` → `scripts/standalone/clean_mods_yml.sh`
  - `modinstaller-simple.sh` → `scripts/standalone/modinstaller-simple.sh`
  - `modrollback-simple.sh` → `scripts/standalone/modrollback-simple.sh`
- Added backward compatibility wrapper for `clean_mods_yml.sh` in project root
- Updated documentation in `scripts/README.md` and `docs/README.md`
- Tested functionality from new locations

**Acceptance criteria met**:
- ✅ Old commands still discoverable via documentation
- ✅ New path reflected in README and docs
- ✅ Backward compatibility maintained with wrapper script

## In Progress

### 🔄 Task 2: Shared Profile Helper + Mod Discovery Fix
**Status**: IN PROGRESS  
**Priority**: HIGH

**Objective**: Create `lib/profile_utils.sh` to eliminate duplicate `resolve_profile()` logic between `modinstaller.sh` and `modrollback.sh`, and fix mod discovery by switching to mods.yml-based approach.

**Implementation plan**:
1. Create `lib/profile_utils.sh` with three functions:
   - `get_profiles_base()` - Returns `${R2MODMAN_BASE:-$HOME/.config/r2modmanPlus-local}/REPO/profiles`
   - `sanitize_profile_name(name)` - Validates profile names, rejects path traversal
   - `resolve_profile(profile_name)` - Sets/exports profile variables, handles fallbacks

2. Update `modinstaller.sh`:
   - Source `lib/profile_utils.sh`
   - Remove duplicate `resolve_profile()` function (lines 142-166)

3. Update `modrollback.sh`:
   - Source `lib/profile_utils.sh`
   - Remove duplicate `resolve_profile()` function (lines 93-114)

4. Update `scripts/standalone/clean_mods_yml.sh`:
   - Replace hardcoded path with `R2MODMAN_BASE` support

5. **NEW: Fix Mod Discovery Issue**:
   - **Problem**: Scripts showing mods from wrong profile due to filesystem-based discovery
   - **Solution**: Switch to mods.yml-based discovery
   - Add functions to `lib/yaml_utils.sh`: `list_mods_from_yml()`, `search_mods_from_yml()`
   - Update `lib/mod_utils.sh` to use mods.yml instead of filesystem scanning
   - Benefits: Single source of truth, no variable scope issues, more reliable

**Files to change**:
- `lib/profile_utils.sh` (new)
- `modinstaller.sh` (source lib, remove duplicate)
- `modrollback.sh` (source lib, remove duplicate)
- `scripts/standalone/clean_mods_yml.sh` (path portability)
- `lib/yaml_utils.sh` (add mods.yml discovery functions)
- `lib/mod_utils.sh` (replace filesystem scanning with mods.yml parsing)

## Pending Tasks

### 📋 Task 3: Path Portability
**Status**: PENDING  
**Dependencies**: Task 2 (will be completed as part of Task 2)

### 📋 Task 4: Input Validation for PROFILE_NAME
**Status**: PENDING  
**Dependencies**: Task 2 (will be completed as part of Task 2)

### 📋 Task 5: Standalone Cleaner De-duplication
**Status**: PENDING  
**Dependencies**: Task 2

### 📋 Task 6: Sourcery Review Parser Documentation
**Status**: PENDING  
**Dependencies**: None

## Next Steps

1. **Immediate**: Complete Task 2 (Shared Profile Helper + Mod Discovery Fix)
   - ✅ Create `lib/profile_utils.sh` (COMPLETED)
   - ✅ Update main scripts to use shared library (COMPLETED)
   - 🔄 **NEXT**: Add mods.yml-based discovery functions to `lib/yaml_utils.sh`
   - 🔄 **NEXT**: Update `lib/mod_utils.sh` to use mods.yml instead of filesystem scanning
   - 🔄 **NEXT**: Test mod discovery with different profiles

2. **After Task 2**: Tasks 3-4 will be automatically completed as part of Task 2 implementation

3. **Then**: Task 5 (Standalone Cleaner De-duplication)

4. **Finally**: Task 6 (Sourcery Parser Documentation)

## Testing Strategy

For each task, we'll run:
```bash
# Basic functionality
SKIP_DEPENDENCY_CHECK=true ./modrollback.sh --profile Default
SKIP_DEPENDENCY_CHECK=true ./modinstaller.sh --profile Default

# Path portability
R2MODMAN_BASE=/tmp/test ./modrollback.sh --profile Default

# Input validation
./modrollback.sh --profile "../../etc"  # Should reject
./modrollback.sh --profile "Default"    # Should work
```

## Notes

- All tasks are being implemented directly on `develop` branch as they are organizational/refactoring changes
- No functional changes to user-facing behavior
- Backward compatibility maintained throughout
- Documentation updated as changes are made

---

**Last Updated**: October 5, 2025  
**Next Review**: After Task 2 completion

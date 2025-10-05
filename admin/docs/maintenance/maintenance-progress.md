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

### 🔄 Task 2: Shared Profile Helper (DRY)
**Status**: READY TO START  
**Priority**: HIGH

**Objective**: Create `lib/profile_utils.sh` to eliminate duplicate `resolve_profile()` logic between `modinstaller.sh` and `modrollback.sh`.

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

**Files to change**:
- `lib/profile_utils.sh` (new)
- `modinstaller.sh` (source lib, remove duplicate)
- `modrollback.sh` (source lib, remove duplicate)
- `scripts/standalone/clean_mods_yml.sh` (path portability)

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

1. **Immediate**: Start Task 2 (Shared Profile Helper)
   - Create `lib/profile_utils.sh`
   - Implement the three core functions
   - Test with existing scripts

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

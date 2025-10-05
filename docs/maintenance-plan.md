## Mod Manager Maintenance and Refactor Plan

### Goals
- Consolidate duplicated profile resolution logic into a single shared helper.
- Remove hardcoded absolute paths; use $HOME with an overridable base directory.
- Validate/sanitize profile names to prevent path traversal and invalid inputs.
- Clarify standalone tooling location; keep overlap intentionally minimal.
- Document Sourcery parser limitations and the manual-context workflow.

### 1) Folder Restructure for Standalone Tools
- Create `scripts/standalone/` and move these scripts:
  - `modinstaller-simple.sh`
  - `modrollback-simple.sh`
  - `clean_mods_yml.sh`
- Keep their CLIs unchanged; update docs/README references.
- Add thin wrappers if needed for backwards compatibility (optional).

Acceptance criteria:
- Old commands still discoverable via documentation; new path is reflected in README and docs.

### 2) Shared Profile Helper (DRY)
- New library: `lib/profile_utils.sh`
  - `get_profiles_base()`: returns `${R2MODMAN_BASE:-$HOME/.config/r2modmanPlus-local}/REPO/profiles`
  - `sanitize_profile_name(name)`: allow `[A-Za-z0-9._ -]`, trim; reject `..`, `/`, `\\`, leading `-`, or >50 chars
  - `resolve_profile(profile_name)`: sets/exports `PROFILE_NAME`, `PROFILE_PATH`, `MOD_PLUGIN_PATH`, `MODS_YML`; falls back to `Default` with warning
- Replace duplicate `resolve_profile` in `modinstaller.sh` and `modrollback.sh` to use this lib.

Acceptance criteria:
- Both scripts source `lib/profile_utils.sh` and no longer duplicate profile logic.

### 3) Path Portability
- Replace hardcoded `/home/deck/.config/r2modmanPlus-local` with `"${R2MODMAN_BASE:-$HOME/.config/r2modmanPlus-local}"` everywhere.
- Update `lib/mod_utils.sh`, `lib/registry_utils.sh`, `modinstaller.sh`, `modrollback.sh`, `clean_mods_yml.sh` accordingly.

Acceptance criteria:
- Running with `R2MODMAN_BASE=/custom/path` uses that location for profiles/plugins.

### 4) Input Validation for PROFILE_NAME
- Use `sanitize_profile_name` before any filesystem access.
- On invalid input: warn and exit, or fallback to `Default` (configurable; default to exit for safety).

Acceptance criteria:
- Attempting `--profile "../../etc"` is rejected with a clear error.

### 5) Standalone Cleaner De-duplication
- `clean_mods_yml.sh` stays as a standalone tool (useful UX), but refactor to import `lib/yaml_utils.sh` and `lib/profile_utils.sh` for shared logic.
- If custom logic remains (e.g., extra heuristics), keep it isolated and documented.

Acceptance criteria:
- Cleaner works via shared helpers; no duplicate path logic.

### 6) Sourcery Review Parser: Incomplete Review Handling
- Update `docs/sourcery-review-parser.md` with a section on partial reviews:
  - Limitation: sometimes the GitHub UI comments are truncated or missing blocks.
  - Workflow: re-run the parser, then append missing context manually beneath the comment row (or via a `--append file.md` flag in a future enhancement).
  - Clearly label manual additions.

Acceptance criteria:
- Docs explain limitations and a manual augmentation workflow.

### Testing
- Non-interactive smoke tests:
  - `SKIP_DEPENDENCY_CHECK=true ./modrollback.sh --profile Default` → list mods
  - `SKIP_DEPENDENCY_CHECK=true ./modinstaller.sh --profile Default <URL>` → path resolution only (no write)
- Edge cases: missing profile, custom `R2MODMAN_BASE`, invalid profile names.

### Migration/Docs
- Update `README.md`, `docs/modular-structure.md`, and `docs/r2modmanplus-integration.md` to reflect new paths and env var.

### Timeline (suggested)
- Day 1: Add `profile_utils.sh`, path portability in both main scripts.
- Day 2: Refactor standalone cleaner, move simple scripts, docs updates.
- Day 3: Parser docs update; optional `--append` design for future.

### Risks
- User environments with nonstandard paths: mitigated by `R2MODMAN_BASE` env var.
- Silent fallbacks: choose explicit warnings with clear output.



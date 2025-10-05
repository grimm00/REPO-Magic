# Documentation

This directory contains all project documentation organized by purpose.

## Structure

- **`guides/`** - Step-by-step guides and tutorials
  - `github-integration.md` - GitHub setup and integration guide
  - `git-workflow.md` - Git Flow branching strategy
  - `modular-structure.md` - Modular script architecture
  - `r2modmanplus-integration.md` - r2modmanPlus integration guide

- **`reference/`** - Technical reference documentation
  - `sourcery-priority-matrix.md` - Sourcery priority matrix tool
  - `sourcery-review-parser.md` - Sourcery review parser tool

- **`feedback/`** - Exported PR reviews and feedback
  - Contains Sourcery review exports and manual feedback

- **`troubleshooting/`** - Troubleshooting guides
  - `index.md` - Troubleshooting overview
  - `quick-fixes.md` - Common quick fixes
  - `rollback-troubleshooting.md` - Rollback-specific issues

- **Root level** - Project overview and quick access
  - `README.md` - This documentation index

## Quick Commands

### Generate PR feedback
```bash
scripts/monitoring/pr-feedback.sh <PR_NUMBER> [optional-name]
# Example:
scripts/monitoring/pr-feedback.sh 12 my-review.md
```

### Alias (if configured)
```bash
pr-feedback <PR_NUMBER> [optional-name]
```

## Related Documentation

- **Project Management**: See `../admin/` for maintenance plans, project status, and internal planning
- **User Guides**: This directory focuses on user-facing documentation

## Contributing

When adding new documentation:
- Place guides in `guides/`
- Place technical references in `reference/`
- Place troubleshooting content in `troubleshooting/`
- Place exported reviews in `feedback/`
- Place project management docs in `../admin/docs/`
- Update this README if adding new categories
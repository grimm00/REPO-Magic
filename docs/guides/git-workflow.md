# Git Workflow Guide

## Overview

This project follows the **Git Flow** branching strategy with `main` as the production branch and `develop` as the integration branch.

## Branch Structure

```
main (production)
  ↑
develop (integration)
  ↑
feature/feature-name (development)
```

## Branch Roles

### 🌟 `main` Branch
- **Purpose**: Production-ready code
- **Protection**: Direct pushes are restricted
- **Updates**: Only via pull requests from `develop`
- **Releases**: Tagged versions are created from this branch

### 🔧 `develop` Branch
- **Purpose**: Integration branch for features
- **Protection**: Direct pushes allowed for maintainers
- **Updates**: Regular integration of feature branches
- **Testing**: CI/CD runs on every push

### 🚀 Feature Branches
- **Purpose**: Individual feature development
- **Naming**: `feature/description` (e.g., `feature/add-logging`)
- **Updates**: Regular pushes to track progress
- **Integration**: Merged into `develop` via pull requests

## Workflow Process

### 1. Starting New Work

```bash
# Ensure you're on develop and it's up to date
git checkout develop
git pull origin develop

# Create a new feature branch
git checkout -b feature/your-feature-name

# Start developing...
```

### 2. During Development

```bash
# Regular commits as you work
git add .
git commit -m "Add feature X"

# Push to track progress
git push origin feature/your-feature-name
```

### 3. Completing a Feature

```bash
# Ensure your feature is up to date with develop
git checkout develop
git pull origin develop
git checkout feature/your-feature-name
git rebase develop

# Push updated feature branch
git push origin feature/your-feature-name

# Create pull request: feature/your-feature-name → develop
```

### 4. Releasing to Production

```bash
# Merge develop into main (via pull request)
# Create release tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

## Branch Protection Rules

### Main Branch Protection
- ✅ Require pull request reviews
- ✅ Require status checks to pass
- ✅ Require branches to be up to date
- ✅ Restrict pushes to main
- ✅ Allow force pushes: ❌
- ✅ Allow deletions: ❌

### Develop Branch Protection
- ✅ Require pull request reviews
- ✅ Require status checks to pass
- ✅ Allow maintainers to bypass restrictions
- ✅ Allow force pushes: ❌
- ✅ Allow deletions: ❌

## Naming Conventions

### Branches
- **Features**: `feature/description` (e.g., `feature/add-error-handling`)
- **Hotfixes**: `hotfix/description` (e.g., `hotfix/fix-installation-bug`)
- **Releases**: `release/version` (e.g., `release/v1.1.0`)

### Commits
- **Format**: `type(scope): description`
- **Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`
- **Examples**:
  - `feat(installer): add dependency validation`
  - `fix(rollback): resolve YAML parsing error`
  - `docs(readme): update installation instructions`

### Pull Requests
- **Title**: Clear, descriptive summary
- **Description**: What, why, and how
- **Template**: Use provided PR template

## Best Practices

### ✅ Do
- Create feature branches for all new work
- Keep feature branches focused and small
- Write clear commit messages
- Update documentation with changes
- Test thoroughly before merging
- Use pull requests for all merges

### ❌ Don't
- Push directly to `main`
- Work directly on `develop` for features
- Merge without testing
- Create overly large feature branches
- Force push to shared branches
- Leave feature branches unmerged

## Emergency Procedures

### Hotfixes
For critical production issues:

```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-fix

# Make minimal fix
git add .
git commit -m "fix: resolve critical installation issue"

# Push and create PR to main
git push origin hotfix/critical-fix

# After merge to main, merge back to develop
git checkout develop
git merge main
git push origin develop
```

### Rollback
If a release has issues:

```bash
# Revert the problematic commit
git checkout main
git revert <commit-hash>
git push origin main

# Tag the rollback
git tag -a v1.0.1-rollback -m "Rollback to stable version"
git push origin v1.0.1-rollback
```

## Tools and Automation

### GitHub CLI
```bash
# Create pull request
gh pr create --title "Feature: Add logging" --body "Description"

# List pull requests
gh pr list

# Check out pull request
gh pr checkout 123
```

### Git Aliases (Optional)
Add to `~/.gitconfig`:
```ini
[alias]
    co = checkout
    br = branch
    ci = commit
    st = status
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
    lg = log --oneline --graph --decorate --all
```

## Migration from Current State

Since we've been developing on `main`, here's how to transition:

1. ✅ **Created `develop` branch** from current `main`
2. ✅ **Pushed `develop`** to GitHub
3. 🔄 **Set up branch protection** (next step)
4. 🔄 **Update CI/CD** to work with new workflow
5. 🔄 **Create first feature branch** for testing

## Next Steps

1. Set up branch protection rules on GitHub
2. Update CI/CD workflows for develop/main strategy
3. Create a feature branch to test the workflow
4. Document any project-specific conventions

---

**Remember**: This workflow ensures code quality, enables collaboration, and maintains a stable production branch while allowing rapid development on feature branches.

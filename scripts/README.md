# REPO-Magic Scripts

This directory contains advanced GitHub integration scripts based on professional development practices from the pokedex project.

## 📁 Directory Structure

```
scripts/
├── core/                    # Shared utilities and libraries
│   └── github-utils.sh     # Centralized GitHub integration utilities
├── setup/                   # Setup and configuration scripts
│   └── github-setup.sh     # Comprehensive GitHub setup automation
├── monitoring/              # Monitoring and status checking
│   ├── project-status.sh   # Project health and status dashboard
│   ├── sourcery-priority-matrix.sh  # Sourcery review analysis
│   ├── sourcery-review-parser.sh   # Sourcery review parser
│   └── pr-feedback.sh      # PR feedback generation helper
├── standalone/              # Standalone single-file tools
│   ├── modinstaller-simple.sh  # Single-file mod installer
│   ├── modrollback-simple.sh   # Single-file mod rollback
│   └── clean_mods_yml.sh   # YAML cleanup tool
└── README.md               # This file
```

## 🚀 Quick Start

### 1. Complete GitHub Setup
```bash
# Run comprehensive GitHub setup
./scripts/setup/github-setup.sh all
```

### 2. Check Project Status
```bash
# Run full project status check
./scripts/monitoring/project-status.sh all
```

## 📋 Available Scripts

### Core Utilities (`scripts/core/`)

#### `github-utils.sh`
**Purpose**: Centralized utilities for GitHub CLI operations and project management

**Features**:
- ✅ Color-coded status messages and logging
- ✅ Comprehensive dependency checking (required + optional)
- ✅ GitHub authentication and repository validation
- ✅ Safe GitHub API operations with error handling
- ✅ Configuration management (environment variables + config files)
- ✅ Branch validation and protection checking
- ✅ Secure random value generation

**Usage**:
```bash
# Source the utilities in other scripts
source scripts/core/github-utils.sh

# Use utility functions
gh_print_status "SUCCESS" "Operation completed"
gh_check_dependencies
gh_validate_repository
```

### Setup Scripts (`scripts/setup/`)

#### `github-setup.sh`
**Purpose**: Comprehensive GitHub integration setup automation

**Features**:
- ✅ GitHub Actions permissions configuration
- ✅ Repository secrets management (JWT, API keys, webhooks)
- ✅ Environment creation (staging, production, development)
- ✅ CI/CD workflow generation
- ✅ Branch protection rules setup
- ✅ Complete setup verification

**Usage**:
```bash
# Run all setup steps
./scripts/setup/github-setup.sh all

# Run specific setup steps
./scripts/setup/github-setup.sh permissions
./scripts/setup/github-setup.sh secrets
./scripts/setup/github-setup.sh environments
./scripts/setup/github-setup.sh ci-cd
./scripts/setup/github-setup.sh protection
./scripts/setup/github-setup.sh verify
```

### Standalone Tools (`scripts/standalone/`)

These are single-file scripts that can be used independently:

#### `modinstaller-simple.sh`
**Purpose**: Single-file mod installer (original version)

**Usage**:
```bash
./scripts/standalone/modinstaller-simple.sh
```

#### `modrollback-simple.sh`
**Purpose**: Single-file mod rollback tool (original version)

**Usage**:
```bash
./scripts/standalone/modrollback-simple.sh
```

#### `clean_mods_yml.sh`
**Purpose**: YAML cleanup tool for mods.yml files

**Usage**:
```bash
# Clean mods.yml for Default profile
./scripts/standalone/clean_mods_yml.sh Default

# Or use the backward compatibility wrapper
./clean_mods_yml.sh Default
```

### Monitoring Scripts (`scripts/monitoring/`)

#### `project-status.sh`
**Purpose**: Comprehensive project health and status monitoring

**Features**:
- ✅ Repository status checking (branch, working directory, sync)
- ✅ GitHub integration validation (webhooks, secrets, environments)
- ✅ CI/CD status monitoring (workflows, recent runs)
- ✅ Project health assessment (scripts, documentation, config)
- ✅ Pull request status tracking
- ✅ Overall project summary with recommendations

**Usage**:
```bash
# Run all status checks
./scripts/monitoring/project-status.sh all

# Run specific checks
./scripts/monitoring/project-status.sh repo
./scripts/monitoring/project-status.sh github
./scripts/monitoring/project-status.sh cicd
./scripts/monitoring/project-status.sh health
./scripts/monitoring/project-status.sh prs
```

## 🔧 Configuration

### Environment Variables
```bash
# GitHub integration settings
export GITHUB_MAIN_BRANCH=main
export GITHUB_DEVELOP_BRANCH=develop
export GITHUB_PROTECTED_BRANCHES=main,develop
export GITHUB_BRANCH_PREFIXES=feat/,fix/,chore/,hotfix/,feature/
export GITHUB_CONFIG_FILE=~/.github-repo-magic-config
```

### Configuration File
Create `~/.github-repo-magic-config`:
```bash
# GitHub Integration Configuration for REPO-Magic
MAIN_BRANCH=main
DEVELOP_BRANCH=develop
PROTECTED_BRANCHES=main,develop
BRANCH_PREFIXES=feat/,fix/,chore/,hotfix/,feature/
```

## 🎯 Key Features

### Sourcery-Compliant Code Structure
- **DRY Principle**: Centralized utilities eliminate code duplication
- **Error Handling**: Comprehensive error handling with helpful guidance
- **Dependency Management**: Required and optional dependency checking
- **Configuration**: Multi-tier configuration system (env vars → config file → defaults)
- **Modularity**: Easy to extend with new functionality

### Professional GitHub Integration
- **Automated Setup**: Complete GitHub integration in one command
- **Security**: Secure secret generation and management
- **Environments**: Staging, production, and development environments
- **CI/CD**: Automated testing, security checks, and deployment
- **Monitoring**: Real-time project health and status tracking

### Advanced Error Handling
- **Graceful Degradation**: Scripts continue with limited functionality when optional tools are missing
- **Actionable Messages**: Clear error messages with specific resolution steps
- **Validation**: Comprehensive input and environment validation
- **Recovery**: Automatic retry and fallback mechanisms

## 📊 Example Output

### GitHub Setup
```bash
🚀 REPO-Magic GitHub Setup
═══════════════════════════

🔍 Dependency Check
✅ All required dependencies available

🔐 GitHub Authentication Check
✅ Authenticated with GitHub

📁 Repository Validation
✅ Repository validated: grimm00/REPO-Magic

🔧 Configuring GitHub Actions Permissions
✅ Workflow permissions updated via API

🔐 Setting up GitHub Secrets
✅ JWT_SECRET_KEY set
✅ API_KEY set
✅ WEBHOOK_SECRET set

🌍 Creating GitHub Environments
✅ Staging environment configured
✅ Production environment configured

🔄 Setting up CI/CD Configuration
✅ Created CI/CD workflow: .github/workflows/ci.yml
✅ Created release workflow: .github/workflows/release.yml

🛡️ Setting up Branch Protection Rules
✅ Main branch protection configured
✅ Develop branch protection configured

🎉 GitHub setup completed successfully!
```

### Project Status
```bash
📊 REPO-Magic Project Status Dashboard
═══════════════════════════════════════

📁 Repository Status
✅ Working on appropriate branch: feature/test-workflow
✅ Working directory is clean
✅ Branch is up to date with remote

🔗 GitHub Integration Status
✅ Authenticated with GitHub
✅ Repository validated: grimm00/REPO-Magic
✅ Webhooks are configured
✅ Secrets are configured
✅ Environments are configured

🔄 CI/CD Status
✅ CI/CD workflows are configured
✅ All scripts have valid syntax

🏥 Project Health
✅ Shell scripts found
✅ All scripts are executable
✅ Documentation is present
✅ All configuration files present

📋 Status Summary
Overall Status: 5/5 checks passed (100%)
✅ Project is in excellent condition!
```

## 🔗 Integration with Main Project

These scripts integrate seamlessly with the main REPO-Magic project:

- **Modular Design**: Scripts can be used independently or together
- **Shared Configuration**: Uses project-wide configuration and conventions
- **Documentation**: Integrates with existing project documentation
- **CI/CD**: Automatically sets up workflows for the main project
- **Monitoring**: Tracks health of the entire project ecosystem

## 🚀 Future Enhancements

### Planned Features
1. **Automated Testing**: Integration with project test suites
2. **Performance Monitoring**: Track script execution performance
3. **Notification Integration**: Slack/Teams notifications for status changes
4. **Custom Rules**: Project-specific validation rules
5. **Backup Management**: Automated backup and recovery procedures

### Extension Points
- **New Utilities**: Easy to add new utility functions to `github-utils.sh`
- **Custom Checks**: Add project-specific health checks to `project-status.sh`
- **Additional Setups**: Create new setup scripts for specific integrations
- **Monitoring Extensions**: Add new monitoring capabilities

---

**Note**: These scripts follow the same professional patterns established in the pokedex project, ensuring consistency, maintainability, and reliability across all GitHub integrations.

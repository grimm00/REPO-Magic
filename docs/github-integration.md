# GitHub Integration Setup Guide

## Overview

This guide will help you set up GitHub integration for the REPO-Magic project, including GitHub CLI, Sourcery integration, and automated workflows.

## Prerequisites

- SteamOS/Arch Linux system
- Git repository already initialized
- GitHub account

## Step 1: Install GitHub CLI

### Option 1: Install from AUR (Recommended)
```bash
# Install yay if not already installed
sudo pacman -S --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

# Install GitHub CLI
yay -S github-cli
```

### Option 2: Manual Installation
```bash
# Download latest release
wget https://github.com/cli/cli/releases/latest/download/gh_*_linux_amd64.tar.gz

# Extract and install
tar -xzf gh_*_linux_amd64.tar.gz
sudo cp gh_*/bin/gh /usr/local/bin/
sudo cp gh_*/share/man/man1/gh.1 /usr/local/share/man/man1/

# Clean up
rm -rf gh_*
```

### Option 3: Using pacman (if available)
```bash
sudo pacman -S github-cli
```

## Step 2: Authenticate with GitHub

```bash
# Authenticate with GitHub
gh auth login

# Follow the prompts:
# - Choose "GitHub.com"
# - Choose "HTTPS" protocol
# - Choose "Login with a web browser"
# - Copy the one-time code and paste it in the browser
```

## Step 3: Create GitHub Repository

```bash
# Navigate to project directory
cd /home/deck/Projects/REPO-Magic

# Create repository on GitHub
gh repo create REPO-Magic --public --description "Universal mod installer and rollback tool for Risk of Rain 2 on SteamOS"

# Add remote origin (if not already set)
git remote add origin https://github.com/YOUR_USERNAME/REPO-Magic.git

# Push to GitHub
git push -u origin main
```

## Step 4: Set Up Sourcery Integration

### Sourcery Configuration

✅ **Already Created**: The `.sourcery.yaml` configuration file has been created with comprehensive rules for both Python and Bash code quality.

**Key Features:**
- **Python Rules**: 30+ quality rules including magic numbers, complexity, documentation, and best practices
- **Bash Rules**: 20+ shell-specific rules for error handling, input validation, and code structure
- **Smart Exclusions**: Automatically excludes documentation, logs, and temporary files
- **Focused Analysis**: Targets `.sh`, `.py`, `.yaml`, and `.yml` files

**Benefits:**
- Automated code quality checks
- Consistent coding standards
- Reduced technical debt
- Better maintainability
- Enhanced readability

**Configuration Details:**
```bash
# The .sourcery.yaml file contains:
# Sourcery configuration for REPO-Magic
python:
  version: "3.9"
  rules:
    - name: "avoid-magic-numbers"
    - name: "avoid-redundant-if"
    - name: "avoid-single-character-names"
    - name: "avoid-unnecessary-else"
    - name: "avoid-unused-variables"
    - name: "consider-using-f-string"
    - name: "consider-using-join"
    - name: "consider-using-ternary"
    - name: "duplicate-code"
    - name: "empty-docstring"
    - name: "function-too-complex"
    - name: "line-too-long"
    - name: "missing-docstring"
    - name: "no-else-return"
    - name: "no-self-use"
    - name: "simplifiable-if-statement"
    - name: "too-few-public-methods"
    - name: "too-many-arguments"
    - name: "too-many-branches"
    - name: "too-many-locals"
    - name: "too-many-return-statements"
    - name: "unnecessary-comprehension"
    - name: "unnecessary-lambda"
    - name: "unused-import"
    - name: "unused-variable"
    - name: "use-dict-literal"
    - name: "use-list-literal"
    - name: "use-set-literal"
    - name: "use-sys-exit"

bash:
  rules:
    - name: "avoid-global-variables"
    - name: "avoid-hardcoded-paths"
    - name: "avoid-long-functions"
    - name: "avoid-magic-numbers"
    - name: "avoid-nested-loops"
    - name: "avoid-redundant-echo"
    - name: "avoid-unnecessary-else"
    - name: "consider-using-printf"
    - name: "duplicate-code"
    - name: "empty-function"
    - name: "function-too-complex"
    - name: "line-too-long"
    - name: "missing-error-handling"
    - name: "missing-input-validation"
    - name: "no-else-return"
    - name: "simplifiable-if-statement"
    - name: "too-many-arguments"
    - name: "too-many-branches"
    - name: "too-many-locals"
    - name: "unnecessary-echo"
    - name: "unused-variable"
    - name: "use-quotes-for-strings"
    - name: "use-strict-mode"

exclude:
  - "*.log"
  - "*.tmp"
  - "*.backup"
  - "docs/"
  - ".git/"

include:
  - "*.sh"
  - "*.py"
  - "*.yaml"
  - "*.yml"
EOF
```

### Set Up Sourcery Webhook
```bash
# Add Sourcery webhook to repository
gh api repos/YOUR_USERNAME/REPO-Magic/hooks \
  --method POST \
  --field name="sourcery" \
  --field config='{"url":"https://sourcery.ai/webhook","content_type":"json"}' \
  --field events='["push","pull_request"]'
```

## Step 5: Create GitHub Workflows

### Create .github/workflows directory
```bash
mkdir -p .github/workflows
```

### Create CI/CD Workflow
```bash
cat > .github/workflows/ci.yml << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        sudo apt-get update
        sudo apt-get install -y shellcheck jq
    
    - name: Run shellcheck
      run: |
        shellcheck modinstaller.sh
        shellcheck modrollback.sh
        shellcheck lib/*.sh
    
    - name: Test YAML validation
      run: |
        python3 -c "import yaml; yaml.safe_load(open('docs/modular-structure.md'))"
    
    - name: Check file permissions
      run: |
        test -x modinstaller.sh
        test -x modrollback.sh
        test -x clean_mods_yml.sh
    
    - name: Validate script syntax
      run: |
        bash -n modinstaller.sh
        bash -n modrollback.sh
        bash -n lib/*.sh
EOF
```

### Create Release Workflow
```bash
cat > .github/workflows/release.yml << 'EOF'
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Create Release
      uses: actions/create-release@v1
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        tag_name: ${{ github.ref }}
        release_name: Release ${{ github.ref }}
        body: |
          ## What's New
          - Universal Thunderstore mod installer
          - Complete rollback system
          - SteamOS compatibility
          - Modular architecture
          
          ## Installation
          ```bash
          git clone https://github.com/${{ github.repository }}.git
          cd REPO-Magic
          chmod +x *.sh
          ```
          
          ## Usage
          ```bash
          # Install any mod
          ./modinstaller.sh "https://thunderstore.io/package/download/AUTHOR/MOD/VERSION/"
          
          # Rollback mod
          ./modrollback.sh modname
          ```
        draft: false
        prerelease: false
EOF
```

## Step 6: Set Up Repository Settings

### Enable Issues and Discussions
```bash
# Enable issues
gh api repos/YOUR_USERNAME/REPO-Magic --method PATCH --field has_issues=true

# Enable discussions
gh api repos/YOUR_USERNAME/REPO-Magic --method PATCH --field has_discussions=true

# Enable wiki
gh api repos/YOUR_USERNAME/REPO-Magic --method PATCH --field has_wiki=true
```

### Set Up Branch Protection
```bash
# Create branch protection rule
gh api repos/YOUR_USERNAME/REPO-Magic/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":["test"]}' \
  --field enforce_admins=true \
  --field required_pull_request_reviews='{"required_approving_review_count":1}' \
  --field restrictions=null
```

## Step 7: Create Project Documentation

### Update README.md
```bash
cat > README.md << 'EOF'
# REPO-Magic

Universal mod installer and rollback tool for Risk of Rain 2 on SteamOS.

## Features

- 🚀 **Universal Installer**: Install any mod from Thunderstore
- 🔄 **Smart Rollback**: Rollback to any previous version
- 🛡️ **SteamOS Compatible**: Full SteamOS integration
- 📦 **Modular Design**: Clean, maintainable architecture
- 🔧 **Registry Management**: Automatic r2modmanPlus integration

## Quick Start

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/REPO-Magic.git
cd REPO-Magic

# Make scripts executable
chmod +x *.sh

# Install any mod
./modinstaller.sh "https://thunderstore.io/package/download/AUTHOR/MOD/VERSION/"

# Rollback a mod
./modrollback.sh modname
```

## Documentation

- [Project Status](docs/project-status.md)
- [Modular Structure](docs/modular-structure.md)
- [Troubleshooting](docs/troubleshooting/)

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details.
EOF
```

## Step 8: Initial Commit and Push

```bash
# Add all files
git add .

# Commit changes
git commit -m "Set up GitHub integration and documentation

- Added comprehensive project documentation
- Set up GitHub workflows for CI/CD
- Configured Sourcery integration
- Added release automation
- Updated README with usage examples

Ready for community contributions!"

# Push to GitHub
git push origin main
```

## Step 9: Create First Release

```bash
# Create a tag for the first release
git tag -a v1.0.0 -m "Initial release - Universal mod installer and rollback tool"

# Push the tag
git push origin v1.0.0

# This will trigger the release workflow
```

## Step 10: Set Up Sourcery

1. Go to [Sourcery.ai](https://sourcery.ai)
2. Sign up with your GitHub account
3. Connect your repository
4. Configure code quality rules
5. Enable automated pull requests

## Verification

### Test GitHub CLI
```bash
# Check authentication
gh auth status

# List repositories
gh repo list

# View repository
gh repo view YOUR_USERNAME/REPO-Magic
```

### Test Workflows
```bash
# Check workflow status
gh run list

# View workflow runs
gh run view
```

### Test Sourcery
```bash
# Check Sourcery status
gh api repos/YOUR_USERNAME/REPO-Magic/hooks
```

## Next Steps

1. **Community Building**: Share the repository with the Risk of Rain 2 community
2. **Issue Templates**: Create issue and pull request templates
3. **Code of Conduct**: Add community guidelines
4. **Contributing Guide**: Create detailed contribution guidelines
5. **Automated Testing**: Set up comprehensive test suite

## Troubleshooting

### GitHub CLI Issues
```bash
# Re-authenticate
gh auth logout
gh auth login

# Check configuration
gh config list
```

### Workflow Issues
```bash
# Check workflow logs
gh run view --log

# Re-run failed workflows
gh run rerun
```

### Sourcery Issues
```bash
# Check webhook status
gh api repos/YOUR_USERNAME/REPO-Magic/hooks

# Re-add webhook if needed
gh api repos/YOUR_USERNAME/REPO-Magic/hooks --method POST --field name="sourcery"
```

## Conclusion

Your GitHub integration is now set up with:
- ✅ GitHub CLI for repository management
- ✅ Automated CI/CD workflows
- ✅ Sourcery integration for code quality
- ✅ Release automation
- ✅ Community features (issues, discussions, wiki)

The repository is ready for community contributions and automated development workflows! 🚀

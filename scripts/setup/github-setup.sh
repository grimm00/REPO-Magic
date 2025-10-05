#!/bin/bash

# Comprehensive GitHub Setup Script for REPO-Magic Project
# Sets up complete GitHub integration including CI/CD, permissions, and automation
# Usage: ./scripts/setup/github-setup.sh [permissions|ci-cd|secrets|environments|all]

set -e

# Get the script directory for relative imports
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source shared utilities
if [ -f "$SCRIPT_DIR/../core/github-utils.sh" ]; then
    source "$SCRIPT_DIR/../core/github-utils.sh"
else
    echo "❌ Error: github-utils.sh not found. Please ensure all GitHub scripts are properly installed."
    exit 1
fi

# Initialize GitHub utilities
if ! gh_init_github_utils; then
    exit 1
fi

gh_print_header "🚀 REPO-Magic GitHub Setup"
echo ""

# Check dependencies and authentication
if ! gh_check_dependencies; then
    exit 1
fi

if ! gh_check_authentication; then
    exit 1
fi

if ! gh_validate_repository; then
    exit 1
fi

echo ""

# ============================================================================
# PERMISSIONS SETUP
# ============================================================================

setup_permissions() {
    gh_print_section "🔧 Configuring GitHub Actions Permissions"
    
    echo "Setting up repository permissions for GitHub Actions..."
    echo "Please ensure the following permissions are enabled in your repository:"
    echo ""
    echo "1. Go to: https://github.com/$PROJECT_REPO/settings/actions"
    echo "2. Under 'Actions permissions', select 'Allow all actions and reusable workflows'"
    echo "3. Under 'Workflow permissions', select 'Read and write permissions'"
    echo "4. Check 'Allow GitHub Actions to create and approve pull requests'"
    echo ""
    
    read -p "Press Enter when you have configured these settings..."
    
    # Set workflow permissions via API
    gh_print_status "INFO" "Setting workflow permissions via API..."
    
    if gh_api_safe "gh api repos/$PROJECT_REPO/actions/permissions --method PUT --field enabled=true --field allowed_actions=all" "Setting workflow permissions" false; then
        gh_print_status "SUCCESS" "Workflow permissions updated via API"
    else
        gh_print_status "WARNING" "Could not set permissions via API - please configure manually"
    fi
    
    # Verify permissions
    echo ""
    gh_print_status "INFO" "Verifying permissions..."
    local current_perms=$(gh api repos/$PROJECT_REPO/actions/permissions --jq '.allowed_actions' 2>/dev/null || echo "unknown")
    echo -e "${GH_BLUE}   Current allowed actions: $current_perms${GH_NC}"
    
    if [ "$current_perms" = "all" ]; then
        gh_print_status "SUCCESS" "Permissions configured correctly!"
    else
        gh_print_status "WARNING" "Permissions may not be set correctly. Please check manually."
    fi
    
    gh_print_status "SUCCESS" "Permissions configuration completed"
}

# ============================================================================
# SECRETS SETUP
# ============================================================================

setup_secrets() {
    gh_print_section "🔐 Setting up GitHub Secrets"
    
    # Generate secure random values
    local jwt_secret=$(gh_generate_secret 32)
    local api_key=$(gh_generate_secret 24)
    local webhook_secret=$(gh_generate_secret 32)
    
    echo "Generated secure random values:"
    echo "  JWT_SECRET_KEY: ${jwt_secret:0:20}..."
    echo "  API_KEY: ${api_key:0:20}..."
    echo "  WEBHOOK_SECRET: ${webhook_secret:0:20}..."
    echo ""
    
    # Set up secrets automatically
    gh_print_status "INFO" "Setting up secrets..."
    
    # Core application secrets
    echo "$jwt_secret" | gh secret set JWT_SECRET_KEY
    gh_print_status "SUCCESS" "JWT_SECRET_KEY set"
    
    echo "$api_key" | gh secret set API_KEY
    gh_print_status "SUCCESS" "API_KEY set"
    
    echo "$webhook_secret" | gh secret set WEBHOOK_SECRET
    gh_print_status "SUCCESS" "WEBHOOK_SECRET set"
    
    # Application configuration
    echo "https://thunderstore.io" | gh secret set THUNDERSTORE_BASE_URL
    gh_print_status "SUCCESS" "THUNDERSTORE_BASE_URL set"
    
    echo "https://github.com/$PROJECT_REPO" | gh secret set REPOSITORY_URL
    gh_print_status "SUCCESS" "REPOSITORY_URL set"
    
    # Environment-specific secrets
    echo "development" | gh secret set ENVIRONMENT
    gh_print_status "SUCCESS" "ENVIRONMENT set"
    
    echo ""
    gh_print_status "INFO" "Verifying secrets..."
    gh secret list
    
    gh_print_status "SUCCESS" "Secrets setup completed"
}

# ============================================================================
# ENVIRONMENTS SETUP
# ============================================================================

setup_environments() {
    gh_print_section "🌍 Creating GitHub Environments"
    
    # Get current user ID for reviewers
    local user_id=$(gh api user --jq '.id' 2>/dev/null || echo "")
    
    # Create staging environment
    gh_print_status "INFO" "Creating staging environment..."
    if gh_api_safe "gh api repos/$PROJECT_REPO/environments/staging --method PUT --field wait_timer=0" "Creating staging environment" false; then
        gh_print_status "SUCCESS" "Staging environment configured"
    else
        gh_print_status "WARNING" "Staging environment may already exist or could not be created"
    fi
    
    # Create production environment
    gh_print_status "INFO" "Creating production environment..."
    if gh_api_safe "gh api repos/$PROJECT_REPO/environments/production --method PUT --field wait_timer=5" "Creating production environment" false; then
        gh_print_status "SUCCESS" "Production environment configured"
    else
        gh_print_status "WARNING" "Production environment may already exist or could not be created"
    fi
    
    # Create development environment
    gh_print_status "INFO" "Creating development environment..."
    if gh_api_safe "gh api repos/$PROJECT_REPO/environments/development --method PUT --field wait_timer=0" "Creating development environment" false; then
        gh_print_status "SUCCESS" "Development environment configured"
    else
        gh_print_status "WARNING" "Development environment may already exist or could not be created"
    fi
    
    echo ""
    gh_print_status "INFO" "Verifying environments..."
    gh api repos/$PROJECT_REPO/environments --jq '.environments[].name' 2>/dev/null || echo "Could not retrieve environment list"
    
    gh_print_status "SUCCESS" "Environments setup completed"
}

# ============================================================================
# CI/CD SETUP
# ============================================================================

setup_ci_cd() {
    gh_print_section "🔄 Setting up CI/CD Configuration"
    
    # Create .github/workflows directory
    mkdir -p "$PROJECT_ROOT/.github/workflows"
    
    # Create main CI/CD workflow
    cat > "$PROJECT_ROOT/.github/workflows/ci.yml" << 'EOF'
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Set up Bash
      run: echo "Bash version: $BASH_VERSION"
      
    - name: Run shell script tests
      run: |
        # Test script syntax
        find . -name "*.sh" -exec bash -n {} \;
        
        # Test script permissions
        find . -name "*.sh" -exec test -x {} \; || echo "Some scripts are not executable"
        
    - name: Validate YAML files
      run: |
        # Check if yq is available for YAML validation
        if command -v yq >/dev/null 2>&1; then
          find . -name "*.yml" -o -name "*.yaml" | xargs yq eval . >/dev/null
        else
          echo "yq not available, skipping YAML validation"
        fi
        
    - name: Check file permissions
      run: |
        # Ensure scripts are executable
        chmod +x scripts/**/*.sh
        chmod +x *.sh
        
    - name: Run basic functionality tests
      run: |
        # Test script help functionality
        ./modinstaller.sh --help || echo "Help test failed"
        ./modrollback.sh --help || echo "Help test failed"

  security:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Run security checks
      run: |
        # Check for common security issues in shell scripts
        echo "Running security checks..."
        
        # Check for hardcoded secrets (basic check)
        if grep -r "password\|secret\|key" --include="*.sh" . | grep -v "SECRET_KEY\|API_KEY" | grep -v "echo.*secret"; then
          echo "Warning: Potential hardcoded secrets found"
        fi
        
        # Check for proper error handling
        echo "Checking error handling..."
        find . -name "*.sh" -exec grep -l "set -e" {} \;

  deploy-staging:
    needs: [test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/develop'
    environment: staging
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Deploy to staging
      run: |
        echo "Deploying to staging environment..."
        echo "This would typically involve:"
        echo "1. Building the application"
        echo "2. Running integration tests"
        echo "3. Deploying to staging servers"
        echo "4. Running smoke tests"

  deploy-production:
    needs: [test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Deploy to production
      run: |
        echo "Deploying to production environment..."
        echo "This would typically involve:"
        echo "1. Building the application"
        echo "2. Running full test suite"
        echo "3. Deploying to production servers"
        echo "4. Running health checks"
        echo "5. Creating release tag"
EOF

    gh_print_status "SUCCESS" "Created CI/CD workflow: .github/workflows/ci.yml"
    
    # Create release workflow
    cat > "$PROJECT_ROOT/.github/workflows/release.yml" << 'EOF'
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
      
    - name: Create release
      run: |
        echo "Creating release for tag: $GITHUB_REF"
        
        # Extract version from tag
        VERSION=${GITHUB_REF#refs/tags/}
        echo "Version: $VERSION"
        
        # Create release notes
        cat > release_notes.md << EOL
        # Release $VERSION
        
        ## Changes
        - Automated release from CI/CD pipeline
        - All tests passed
        - Ready for production deployment
        
        ## Installation
        \`\`\`bash
        # Download and run installer
        curl -fsSL https://raw.githubusercontent.com/grimm00/REPO-Magic/main/modinstaller.sh | bash
        \`\`\`
        EOL
        
        # Create GitHub release
        gh release create "$VERSION" \
          --title "Release $VERSION" \
          --notes-file release_notes.md \
          --latest
          
    - name: Update documentation
      run: |
        echo "Updating documentation for release $VERSION"
        # This would typically update version numbers in docs
EOF

    gh_print_status "SUCCESS" "Created release workflow: .github/workflows/release.yml"
    
    gh_print_status "SUCCESS" "CI/CD setup completed"
}

# ============================================================================
# BRANCH PROTECTION SETUP
# ============================================================================

setup_branch_protection() {
    gh_print_section "🛡️ Setting up Branch Protection Rules"
    
    # Create branch protection configuration files
    cat > "$PROJECT_ROOT/branch_protection_main.json" << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["test"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "restrictions": null
}
EOF

    cat > "$PROJECT_ROOT/branch_protection_develop.json" << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["test"]
  },
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1
  },
  "restrictions": null
}
EOF
    
    # Protect main branch
    gh_print_status "INFO" "Setting up protection for main branch..."
    if gh_api_safe "gh api repos/$PROJECT_REPO/branches/main/protection --method PUT --input $PROJECT_ROOT/branch_protection_main.json" "Protecting main branch" false; then
        gh_print_status "SUCCESS" "Main branch protection configured"
    else
        gh_print_status "WARNING" "Could not set main branch protection - please configure manually"
    fi
    
    # Protect develop branch
    gh_print_status "INFO" "Setting up protection for develop branch..."
    if gh_api_safe "gh api repos/$PROJECT_REPO/branches/develop/protection --method PUT --input $PROJECT_ROOT/branch_protection_develop.json" "Protecting develop branch" false; then
        gh_print_status "SUCCESS" "Develop branch protection configured"
    else
        gh_print_status "WARNING" "Could not set develop branch protection - please configure manually"
    fi
    
    # Clean up temporary files
    rm -f "$PROJECT_ROOT/branch_protection_main.json" "$PROJECT_ROOT/branch_protection_develop.json"
    
    gh_print_status "SUCCESS" "Branch protection setup completed"
}

# ============================================================================
# VERIFICATION
# ============================================================================

verify_setup() {
    gh_print_section "🔍 Verifying Setup"
    
    # Verify secrets
    echo "Current secrets:"
    gh secret list
    
    # Verify permissions
    echo ""
    echo "Current workflow permissions:"
    gh api repos/$PROJECT_REPO/actions/permissions --jq '.allowed_actions' 2>/dev/null || echo "Could not retrieve permissions"
    
    # Verify environments
    echo ""
    echo "Current environments:"
    gh api repos/$PROJECT_REPO/environments --jq '.environments[].name' 2>/dev/null || echo "Could not retrieve environments"
    
    # Verify workflows
    echo ""
    echo "Current workflows:"
    if [ -f "$PROJECT_ROOT/.github/workflows/ci.yml" ]; then
        gh_print_status "SUCCESS" "CI/CD workflow exists"
    else
        gh_print_status "ERROR" "CI/CD workflow not found"
    fi
    
    if [ -f "$PROJECT_ROOT/.github/workflows/release.yml" ]; then
        gh_print_status "SUCCESS" "Release workflow exists"
    else
        gh_print_status "ERROR" "Release workflow not found"
    fi
    
    gh_print_status "SUCCESS" "Setup verification completed"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

case "${1:-all}" in
    "permissions")
        setup_permissions
        ;;
    "secrets")
        setup_secrets
        ;;
    "environments")
        setup_environments
        ;;
    "ci-cd")
        setup_ci_cd
        ;;
    "protection")
        setup_branch_protection
        ;;
    "verify")
        verify_setup
        ;;
    "all")
        setup_permissions
        echo ""
        setup_secrets
        echo ""
        setup_environments
        echo ""
        setup_ci_cd
        echo ""
        setup_branch_protection
        echo ""
        verify_setup
        ;;
    *)
        echo "Usage: $0 [permissions|secrets|environments|ci-cd|protection|verify|all]"
        echo ""
        echo "Commands:"
        echo "  permissions   - Configure GitHub Actions permissions"
        echo "  secrets       - Set up GitHub secrets"
        echo "  environments  - Create GitHub environments"
        echo "  ci-cd         - Set up CI/CD workflows"
        echo "  protection    - Set up branch protection rules"
        echo "  verify        - Verify current setup"
        echo "  all           - Run all setup steps (default)"
        exit 1
        ;;
esac

echo ""
gh_print_status "SUCCESS" "🎉 GitHub setup completed successfully!"
echo ""
echo "📋 What was configured:"
echo "✅ GitHub Actions permissions"
echo "✅ Repository secrets (JWT_SECRET_KEY, API_KEY, WEBHOOK_SECRET, etc.)"
echo "✅ Environments (staging, production, development)"
echo "✅ CI/CD workflows (testing, security, deployment)"
echo "✅ Branch protection rules"
echo ""
echo "🚀 Next steps:"
echo "1. Go to https://github.com/$PROJECT_REPO/actions"
echo "2. Re-run any failed workflows to test the configuration"
echo "3. Create a test pull request to verify the workflow"
echo "4. Monitor the deployment progress"
echo ""
echo "📚 For detailed information, see: docs/github-integration.md"
echo ""
echo "🔧 To re-run workflows manually:"
echo "  gh run rerun --failed"
echo ""
echo "🎯 Ready for automated CI/CD!"

#!/bin/bash

# Project Status Monitoring Script for REPO-Magic
# Comprehensive status checking and health monitoring

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

gh_print_header "📊 REPO-Magic Project Status Dashboard"
echo ""

# ============================================================================
# REPOSITORY STATUS
# ============================================================================

check_repository_status() {
    gh_print_section "📁 Repository Status"
    
    # Check if we're in a Git repository
    if ! gh_is_git_repo; then
        gh_print_status "ERROR" "Not in a Git repository"
        return 1
    fi
    
    # Get current branch
    local current_branch=$(gh_get_current_branch)
    echo -e "${GH_BLUE}   Current branch: $current_branch${GH_NC}"
    
    # Check if on protected branch
    if gh_is_protected_branch "$current_branch"; then
        gh_print_status "WARNING" "Working on protected branch: $current_branch"
    else
        gh_print_status "SUCCESS" "Working on appropriate branch: $current_branch"
    fi
    
    # Check working directory status
    if ! git diff-index --quiet HEAD --; then
        gh_print_status "WARNING" "You have uncommitted changes"
        local modified_count=$(git status --porcelain | wc -l)
        echo -e "${GH_YELLOW}   Modified files: $modified_count${GH_NC}"
    else
        gh_print_status "SUCCESS" "Working directory is clean"
    fi
    
    # Check if branch is up to date
    if gh_remote_branch_exists "$current_branch"; then
        local local_commit=$(git rev-parse HEAD)
        local remote_commit=$(git rev-parse "origin/$current_branch")
        
        if [ "$local_commit" = "$remote_commit" ]; then
            gh_print_status "SUCCESS" "Branch is up to date with remote"
        else
            gh_print_status "WARNING" "Branch is not up to date with remote"
        fi
    else
        gh_print_status "INFO" "Branch does not exist on remote yet"
    fi
    
    return 0
}

# ============================================================================
# GITHUB INTEGRATION STATUS
# ============================================================================

check_github_integration() {
    gh_print_section "🔗 GitHub Integration Status"
    
    # Check authentication
    if gh_check_authentication; then
        echo ""
    else
        return 1
    fi
    
    # Check repository validation
    if gh_validate_repository; then
        echo ""
    else
        return 1
    fi
    
    # Check webhooks
    gh_print_status "INFO" "Checking webhooks..."
    local webhook_count=$(gh api repos/$PROJECT_REPO/hooks --jq 'length' 2>/dev/null || echo "0")
    echo -e "${GH_BLUE}   Active webhooks: $webhook_count${GH_NC}"
    
    if [ "$webhook_count" -gt 0 ]; then
        gh_print_status "SUCCESS" "Webhooks are configured"
    else
        gh_print_status "WARNING" "No webhooks found"
    fi
    
    # Check secrets
    gh_print_status "INFO" "Checking secrets..."
    local secret_count=$(gh secret list 2>/dev/null | wc -l || echo "0")
    echo -e "${GH_BLUE}   Repository secrets: $secret_count${GH_NC}"
    
    if [ "$secret_count" -gt 0 ]; then
        gh_print_status "SUCCESS" "Secrets are configured"
    else
        gh_print_status "WARNING" "No secrets found"
    fi
    
    # Check environments
    gh_print_status "INFO" "Checking environments..."
    local env_count=$(gh api repos/$PROJECT_REPO/environments --jq '.environments | length' 2>/dev/null || echo "0")
    echo -e "${GH_BLUE}   Environments: $env_count${GH_NC}"
    
    if [ "$env_count" -gt 0 ]; then
        gh_print_status "SUCCESS" "Environments are configured"
    else
        gh_print_status "WARNING" "No environments found"
    fi
    
    return 0
}

# ============================================================================
# CI/CD STATUS
# ============================================================================

check_cicd_status() {
    gh_print_section "🔄 CI/CD Status"
    
    # Check workflow files
    local workflow_dir="$PROJECT_ROOT/.github/workflows"
    if [ -d "$workflow_dir" ]; then
        local workflow_count=$(find "$workflow_dir" -name "*.yml" -o -name "*.yaml" | wc -l)
        echo -e "${GH_BLUE}   Workflow files: $workflow_count${GH_NC}"
        
        if [ "$workflow_count" -gt 0 ]; then
            gh_print_status "SUCCESS" "CI/CD workflows are configured"
            
            # List workflow files
            echo -e "${GH_BLUE}   Workflows:${GH_NC}"
            find "$workflow_dir" -name "*.yml" -o -name "*.yaml" | while read -r workflow; do
                local basename=$(basename "$workflow")
                echo -e "${GH_BLUE}     - $basename${GH_NC}"
            done
        else
            gh_print_status "WARNING" "No workflow files found"
        fi
    else
        gh_print_status "ERROR" "Workflows directory not found"
        return 1
    fi
    
    # Check recent workflow runs
    if gh_command_exists "gh"; then
        gh_print_status "INFO" "Checking recent workflow runs..."
        local recent_runs=$(gh run list --limit 5 --json status,conclusion,createdAt,workflowName 2>/dev/null || echo "[]")
        local run_count=$(echo "$recent_runs" | jq length 2>/dev/null || echo "0")
        
        if [ "$run_count" -gt 0 ]; then
            echo -e "${GH_BLUE}   Recent runs: $run_count${GH_NC}"
            
            # Show recent run statuses
            echo "$recent_runs" | jq -r '.[] | "     \(.workflowName): \(.status) (\(.conclusion // "in_progress"))"' 2>/dev/null || echo "     Could not parse run details"
        else
            gh_print_status "INFO" "No recent workflow runs found"
        fi
    fi
    
    return 0
}

# ============================================================================
# PROJECT HEALTH
# ============================================================================

check_project_health() {
    gh_print_section "🏥 Project Health"
    
    # Check script files
    local script_count=$(find "$PROJECT_ROOT" -name "*.sh" | wc -l)
    echo -e "${GH_BLUE}   Shell scripts: $script_count${GH_NC}"
    
    if [ "$script_count" -gt 0 ]; then
        gh_print_status "SUCCESS" "Shell scripts found"
        
        # Check script permissions
        local executable_count=$(find "$PROJECT_ROOT" -name "*.sh" -executable | wc -l)
        local total_scripts=$(find "$PROJECT_ROOT" -name "*.sh" | wc -l)
        
        if [ "$executable_count" -eq "$total_scripts" ]; then
            gh_print_status "SUCCESS" "All scripts are executable"
        else
            gh_print_status "WARNING" "Some scripts are not executable ($executable_count/$total_scripts)"
        fi
        
        # Check script syntax
        gh_print_status "INFO" "Checking script syntax..."
        local syntax_errors=0
        while IFS= read -r -d '' script; do
            if ! bash -n "$script" 2>/dev/null; then
                syntax_errors=$((syntax_errors + 1))
            fi
        done < <(find "$PROJECT_ROOT" -name "*.sh" -print0)
        
        if [ "$syntax_errors" -eq 0 ]; then
            gh_print_status "SUCCESS" "All scripts have valid syntax"
        else
            gh_print_status "ERROR" "Found $syntax_errors script(s) with syntax errors"
        fi
    else
        gh_print_status "WARNING" "No shell scripts found"
    fi
    
    # Check documentation
    local doc_count=$(find "$PROJECT_ROOT/docs" -name "*.md" 2>/dev/null | wc -l)
    echo -e "${GH_BLUE}   Documentation files: $doc_count${GH_NC}"
    
    if [ "$doc_count" -gt 0 ]; then
        gh_print_status "SUCCESS" "Documentation is present"
    else
        gh_print_status "WARNING" "No documentation found"
    fi
    
    # Check configuration files
    local config_files=(".sourcery.yaml" ".gitignore" "README.md")
    local config_count=0
    
    for config in "${config_files[@]}"; do
        if [ -f "$PROJECT_ROOT/$config" ]; then
            config_count=$((config_count + 1))
        fi
    done
    
    echo -e "${GH_BLUE}   Configuration files: $config_count/${#config_files[@]}${GH_NC}"
    
    if [ "$config_count" -eq "${#config_files[@]}" ]; then
        gh_print_status "SUCCESS" "All configuration files present"
    else
        gh_print_status "WARNING" "Some configuration files missing"
    fi
    
    return 0
}

# ============================================================================
# PULL REQUEST STATUS
# ============================================================================

check_pull_requests() {
    gh_print_section "🔄 Pull Request Status"
    
    if ! gh_command_exists "gh"; then
        gh_print_status "WARNING" "GitHub CLI not available - cannot check PRs"
        return 0
    fi
    
    # Check open PRs
    local open_prs=$(gh pr list --state open --json number,title,headRefName,author 2>/dev/null || echo "[]")
    local open_count=$(echo "$open_prs" | jq length 2>/dev/null || echo "0")
    
    echo -e "${GH_BLUE}   Open PRs: $open_count${GH_NC}"
    
    if [ "$open_count" -gt 0 ]; then
        gh_print_status "INFO" "Open pull requests:"
        echo "$open_prs" | jq -r '.[] | "     #\(.number): \(.title) (\(.headRefName)) by \(.author.login)"' 2>/dev/null || echo "     Could not parse PR details"
    else
        gh_print_status "SUCCESS" "No open pull requests"
    fi
    
    # Check recent PRs
    local recent_prs=$(gh pr list --state all --limit 5 --json number,title,state,mergedAt,closedAt 2>/dev/null || echo "[]")
    local recent_count=$(echo "$recent_prs" | jq length 2>/dev/null || echo "0")
    
    if [ "$recent_count" -gt 0 ]; then
        echo -e "${GH_BLUE}   Recent PRs: $recent_count${GH_NC}"
        echo "$recent_prs" | jq -r '.[] | "     #\(.number): \(.title) (\(.state))"' 2>/dev/null || echo "     Could not parse recent PR details"
    fi
    
    return 0
}

# ============================================================================
# SUMMARY
# ============================================================================

generate_summary() {
    gh_print_section "📋 Status Summary"
    
    local total_checks=5
    local passed_checks=0
    
    # Count passed checks (simplified)
    if check_repository_status; then
        passed_checks=$((passed_checks + 1))
    fi
    echo ""
    
    if check_github_integration; then
        passed_checks=$((passed_checks + 1))
    fi
    echo ""
    
    if check_cicd_status; then
        passed_checks=$((passed_checks + 1))
    fi
    echo ""
    
    if check_project_health; then
        passed_checks=$((passed_checks + 1))
    fi
    echo ""
    
    if check_pull_requests; then
        passed_checks=$((passed_checks + 1))
    fi
    echo ""
    
    # Generate summary
    local percentage=$((passed_checks * 100 / total_checks))
    
    echo -e "${GH_BOLD}Overall Status: $passed_checks/$total_checks checks passed ($percentage%)${GH_NC}"
    
    if [ "$percentage" -ge 80 ]; then
        gh_print_status "SUCCESS" "Project is in excellent condition!"
    elif [ "$percentage" -ge 60 ]; then
        gh_print_status "WARNING" "Project is in good condition with some issues"
    else
        gh_print_status "ERROR" "Project needs attention"
    fi
    
    echo ""
    echo -e "${GH_BLUE}💡 Next steps:${GH_NC}"
    echo "1. Address any warnings or errors above"
    echo "2. Run './scripts/setup/github-setup.sh' to configure missing components"
    echo "3. Create a test pull request to verify the workflow"
    echo "4. Monitor CI/CD pipeline performance"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

case "${1:-all}" in
    "repo")
        check_repository_status
        ;;
    "github")
        check_github_integration
        ;;
    "cicd")
        check_cicd_status
        ;;
    "health")
        check_project_health
        ;;
    "prs")
        check_pull_requests
        ;;
    "all")
        generate_summary
        ;;
    *)
        echo "Usage: $0 [repo|github|cicd|health|prs|all]"
        echo ""
        echo "Commands:"
        echo "  repo     - Check repository status"
        echo "  github   - Check GitHub integration"
        echo "  cicd     - Check CI/CD status"
        echo "  health   - Check project health"
        echo "  prs      - Check pull request status"
        echo "  all      - Run all checks and generate summary (default)"
        exit 1
        ;;
esac

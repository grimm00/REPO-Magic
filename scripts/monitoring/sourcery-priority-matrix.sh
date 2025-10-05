#!/bin/bash

# Sourcery Review Priority Matrix Analyzer for REPO-Magic
# Automatically parses Sourcery reviews and applies priority matrix analysis

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

gh_print_header "🎯 Sourcery Priority Matrix Analyzer"
echo ""

# ============================================================================
# PRIORITY MATRIX CONFIGURATION
# ============================================================================

# Priority levels and their weights
declare -A PRIORITY_WEIGHTS=(
    ["🔴 CRITICAL"]=10
    ["🟠 HIGH"]=7
    ["🟡 MEDIUM"]=4
    ["🟢 LOW"]=1
    ["🔵 ENHANCEMENT"]=0.5
)

# Impact levels and their weights
declare -A IMPACT_WEIGHTS=(
    ["🔴 CRITICAL"]=10
    ["🟠 HIGH"]=7
    ["🟡 MEDIUM"]=4
    ["🟢 LOW"]=1
)

# Effort levels and their weights (inverse - lower effort = higher score)
declare -A EFFORT_WEIGHTS=(
    ["🟢 LOW"]=10
    ["🟡 MEDIUM"]=6
    ["🟠 HIGH"]=3
    ["🔴 VERY_HIGH"]=1
)

# Initialize associative arrays for analysis storage
declare -A COMMENT_ANALYSES
declare -A PRIORITY_COUNTS

# ============================================================================
# SOURCERY REVIEW PARSING
# ============================================================================

parse_sourcery_review() {
    local pr_number="$1"
    
    gh_print_section "📋 Parsing Sourcery Review for PR #$pr_number"
    
    # Get the review data
    local review_data=$(gh pr view "$pr_number" --json reviews --jq '.reviews[] | select(.author.login == "sourcery-ai") | .body' 2>/dev/null)
    
    if [ -z "$review_data" ] || [ "$review_data" = "null" ]; then
        gh_print_status "WARNING" "No Sourcery review found for PR #$pr_number"
        return 1
    fi
    
    # Extract the markdown code block content
    local markdown_content=$(echo "$review_data" | sed -n '/~~~markdown/,/~~~/p' | sed '1d;$d')
    
    if [ -z "$markdown_content" ]; then
        gh_print_status "WARNING" "No markdown content found in Sourcery review"
        return 1
    fi
    
    # Extract individual comments using regex
    local comment_headers=($(echo "$markdown_content" | grep -o '### Comment [0-9]\+'))
    
    for comment_header in "${comment_headers[@]}"; do
        parse_individual_comment "$markdown_content" "$comment_header"
    done
}

parse_individual_comment() {
    local review_data="$1"
    local comment_header="$2"
    
    # Extract comment number
    local comment_num=$(echo "$comment_header" | grep -o '[0-9]\+')
    
    if [ -z "$comment_num" ]; then
        return 0
    fi
    
    # Extract the comment content between this header and the next
    local comment_content=$(echo "$review_data" | sed -n "/$comment_header/,/### Comment [0-9]\+/p" | head -n -1)
    
    if [ -z "$comment_content" ]; then
        return 0
    fi
    
    # Analyze the comment
    analyze_comment "$comment_num" "$comment_content"
}

analyze_comment() {
    local comment_num="$1"
    local content="$2"
    
    # Extract key information
    local location=$(echo "$content" | grep -o '<location>.*</location>' | sed 's/<[^>]*>//g')
    local issue_type=$(echo "$content" | grep -o '\*\*[^*]*\*\*' | head -1 | sed 's/\*\*//g')
    local issue_description=$(echo "$content" | grep -A 5 '<issue_to_address>' | grep -v '<issue_to_address>' | head -1)
    
    # Determine priority based on issue type
    local priority=$(determine_priority "$issue_type" "$content")
    local impact=$(determine_impact "$content")
    local effort=$(determine_effort "$content")
    
    # Calculate priority score
    local priority_score=$(calculate_priority_score "$priority" "$impact" "$effort")
    
    # Store the analysis
    store_comment_analysis "$comment_num" "$location" "$issue_type" "$priority" "$impact" "$effort" "$priority_score" "$issue_description"
}

determine_priority() {
    local issue_type="$1"
    local content="$2"
    
    # Check for security issues
    if echo "$content" | grep -qi "security\|vulnerability\|exploit"; then
        echo "🔴 CRITICAL"
        return
    fi
    
    # Check for bug risk
    if echo "$content" | grep -qi "bug_risk\|bug\|error\|fail"; then
        echo "🟠 HIGH"
        return
    fi
    
    # Check for performance issues
    if echo "$content" | grep -qi "performance\|slow\|timeout\|memory"; then
        echo "🟡 MEDIUM"
        return
    fi
    
    # Check for maintainability
    if echo "$content" | grep -qi "maintainability\|duplicate\|refactor"; then
        echo "🟡 MEDIUM"
        return
    fi
    
    # Default to suggestion
    echo "🟢 LOW"
}

determine_impact() {
    local content="$2"
    
    # Check for critical functionality
    if echo "$content" | grep -qi "critical\|essential\|core\|main"; then
        echo "🟠 HIGH"
        return
    fi
    
    # Check for user-facing changes
    if echo "$content" | grep -qi "user\|interface\|experience\|usability"; then
        echo "🟡 MEDIUM"
        return
    fi
    
    # Check for developer experience
    if echo "$content" | grep -qi "developer\|maintain\|debug\|test"; then
        echo "🟡 MEDIUM"
        return
    fi
    
    # Default to low impact
    echo "🟢 LOW"
}

determine_effort() {
    local content="$2"
    
    # Check for simple changes
    if echo "$content" | grep -qi "simple\|easy\|quick\|minor"; then
        echo "🟢 LOW"
        return
    fi
    
    # Check for complex changes
    if echo "$content" | grep -qi "complex\|major\|refactor\|rewrite"; then
        echo "🟠 HIGH"
        return
    fi
    
    # Check for medium complexity
    if echo "$content" | grep -qi "moderate\|medium\|some\|several"; then
        echo "🟡 MEDIUM"
        return
    fi
    
    # Default to medium effort
    echo "🟡 MEDIUM"
}

calculate_priority_score() {
    local priority="$1"
    local impact="$2"
    local effort="$3"
    
    local priority_weight=${PRIORITY_WEIGHTS[$priority]:-1}
    local impact_weight=${IMPACT_WEIGHTS[$impact]:-1}
    local effort_weight=${EFFORT_WEIGHTS[$effort]:-1}
    
    # Calculate weighted score (higher is better)
    local score=$(echo "scale=2; $priority_weight * $impact_weight * $effort_weight" | bc -l 2>/dev/null || echo "0")
    echo "$score"
}

# ============================================================================
# ANALYSIS STORAGE AND REPORTING
# ============================================================================

store_comment_analysis() {
    local comment_num="$1"
    local location="$2"
    local issue_type="$3"
    local priority="$4"
    local impact="$5"
    local effort="$6"
    local priority_score="$7"
    local description="$8"
    
    
    # Store the analysis
    COMMENT_ANALYSES["$comment_num"]="$location|$issue_type|$priority|$impact|$effort|$priority_score|$description"
    
    # Count priorities
    local count=${PRIORITY_COUNTS[$priority]:-0}
    PRIORITY_COUNTS[$priority]=$((count + 1))
}

generate_priority_matrix_report() {
    gh_print_section "📊 Priority Matrix Analysis Report"
    
    # Sort comments by priority score
    local sorted_comments=()
    for comment_num in "${!COMMENT_ANALYSES[@]}"; do
        local data="${COMMENT_ANALYSES[$comment_num]}"
        local score=$(echo "$data" | cut -d'|' -f6)
        sorted_comments+=("$score|$comment_num|$data")
    done
    
    # Sort by score (descending)
    IFS=$'\n' sorted_comments=($(sort -nr <<<"${sorted_comments[*]}"))
    unset IFS
    
    # Display summary
    echo ""
    echo -e "${GH_BOLD}📈 Priority Distribution:${GH_NC}"
    for priority in "${!PRIORITY_COUNTS[@]}"; do
        local count=${PRIORITY_COUNTS[$priority]}
        echo -e "   $priority: $count comment(s)"
    done
    
    echo ""
    echo -e "${GH_BOLD}🎯 Recommended Action Plan:${GH_NC}"
    echo ""
    
    # Display high-priority items first
    local high_priority_count=0
    local medium_priority_count=0
    local low_priority_count=0
    
    for comment_data in "${sorted_comments[@]}"; do
        local score=$(echo "$comment_data" | cut -d'|' -f1)
        local comment_num=$(echo "$comment_data" | cut -d'|' -f2)
        local location=$(echo "$comment_data" | cut -d'|' -f3)
        local issue_type=$(echo "$comment_data" | cut -d'|' -f4)
        local priority=$(echo "$comment_data" | cut -d'|' -f5)
        local impact=$(echo "$comment_data" | cut -d'|' -f6)
        local effort=$(echo "$comment_data" | cut -d'|' -f7)
        local description=$(echo "$comment_data" | cut -d'|' -f9)
        
        # Categorize by priority
        case "$priority" in
            "🔴 CRITICAL"|"🟠 HIGH")
                if [ $high_priority_count -lt 3 ]; then
                    display_comment_analysis "$comment_num" "$location" "$issue_type" "$priority" "$impact" "$effort" "$score" "$description"
                    high_priority_count=$((high_priority_count + 1))
                fi
                ;;
            "🟡 MEDIUM")
                if [ $medium_priority_count -lt 2 ]; then
                    display_comment_analysis "$comment_num" "$location" "$issue_type" "$priority" "$impact" "$effort" "$score" "$description"
                    medium_priority_count=$((medium_priority_count + 1))
                fi
                ;;
            "🟢 LOW")
                if [ $low_priority_count -lt 1 ]; then
                    display_comment_analysis "$comment_num" "$location" "$issue_type" "$priority" "$impact" "$effort" "$score" "$description"
                    low_priority_count=$((low_priority_count + 1))
                fi
                ;;
        esac
    done
    
    echo ""
    echo -e "${GH_BOLD}💡 Implementation Recommendations:${GH_NC}"
    echo ""
    
    # Generate recommendations based on analysis
    generate_implementation_recommendations
}

display_comment_analysis() {
    local comment_num="$1"
    local location="$2"
    local issue_type="$3"
    local priority="$4"
    local impact="$5"
    local effort="$6"
    local score="$7"
    local description="$8"
    
    echo -e "${GH_BOLD}Comment #$comment_num${GH_NC} (Score: $score)"
    echo -e "   ${GH_CYAN}Location:${GH_NC} $location"
    echo -e "   ${GH_CYAN}Type:${GH_NC} $issue_type"
    echo -e "   ${GH_CYAN}Priority:${GH_NC} $priority"
    echo -e "   ${GH_CYAN}Impact:${GH_NC} $impact"
    echo -e "   ${GH_CYAN}Effort:${GH_NC} $effort"
    echo -e "   ${GH_CYAN}Description:${GH_NC} $description"
    echo ""
}

generate_implementation_recommendations() {
    local critical_count=${PRIORITY_COUNTS["🔴 CRITICAL"]:-0}
    local high_count=${PRIORITY_COUNTS["🟠 HIGH"]:-0}
    local medium_count=${PRIORITY_COUNTS["🟡 MEDIUM"]:-0}
    local low_count=${PRIORITY_COUNTS["🟢 LOW"]:-0}
    
    echo -e "${GH_BOLD}🚀 Immediate Actions (This Sprint):${GH_NC}"
    
    if [ $critical_count -gt 0 ]; then
        echo "   🔴 Address $critical_count CRITICAL issue(s) immediately"
        echo "   🔴 These may affect security, stability, or core functionality"
    fi
    
    if [ $high_count -gt 0 ]; then
        echo "   🟠 Address $high_count HIGH priority issue(s) this sprint"
        echo "   🟠 These may cause bugs or significant maintainability issues"
    fi
    
    echo ""
    echo -e "${GH_BOLD}📋 Next Sprint Planning:${GH_NC}"
    
    if [ $medium_count -gt 0 ]; then
        echo "   🟡 Plan $medium_count MEDIUM priority issue(s) for next sprint"
        echo "   🟡 These improve code quality and maintainability"
    fi
    
    echo ""
    echo -e "${GH_BOLD}🔮 Future Backlog:${GH_NC}"
    
    if [ $low_count -gt 0 ]; then
        echo "   🟢 Add $low_count LOW priority issue(s) to future backlog"
        echo "   🟢 These are nice-to-have improvements"
    fi
    
    echo ""
    echo -e "${GH_BOLD}📊 Priority Matrix Summary:${GH_NC}"
    echo "   Total Comments: $(($critical_count + $high_count + $medium_count + $low_count))"
    echo "   Critical: $critical_count"
    echo "   High: $high_count"
    echo "   Medium: $medium_count"
    echo "   Low: $low_count"
}

# ============================================================================
# EXPORT FUNCTIONALITY
# ============================================================================

export_analysis_to_file() {
    local output_file="$1"
    
    gh_print_section "💾 Exporting Analysis to $output_file"
    
    cat > "$output_file" << EOF
# Sourcery Priority Matrix Analysis
**Generated**: $(date)
**PR**: #$PR_NUMBER
**Repository**: $PROJECT_REPO

## Summary
EOF
    
    # Add summary
    for priority in "${!PRIORITY_COUNTS[@]}"; do
        local count=${PRIORITY_COUNTS[$priority]}
        echo "- $priority: $count comment(s)" >> "$output_file"
    done
    
    echo "" >> "$output_file"
    echo "## Detailed Analysis" >> "$output_file"
    echo "" >> "$output_file"
    
    # Add detailed analysis
    for comment_num in "${!COMMENT_ANALYSES[@]}"; do
        local data="${COMMENT_ANALYSES[$comment_num]}"
        local location=$(echo "$data" | cut -d'|' -f1)
        local issue_type=$(echo "$data" | cut -d'|' -f2)
        local priority=$(echo "$data" | cut -d'|' -f3)
        local impact=$(echo "$data" | cut -d'|' -f4)
        local effort=$(echo "$data" | cut -d'|' -f5)
        local score=$(echo "$data" | cut -d'|' -f6)
        local description=$(echo "$data" | cut -d'|' -f7)
        
        cat >> "$output_file" << EOF
### Comment #$comment_num
- **Location**: $location
- **Type**: $issue_type
- **Priority**: $priority
- **Impact**: $impact
- **Effort**: $effort
- **Score**: $score
- **Description**: $description

EOF
    done
    
    gh_print_status "SUCCESS" "Analysis exported to $output_file"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

PR_NUMBER=""

case "${1:-}" in
    "")
        # Get the current PR number
        PR_NUMBER=$(gh pr list --author "@me" --state open --json number --jq '.[0].number' 2>/dev/null)
        if [ -z "$PR_NUMBER" ] || [ "$PR_NUMBER" = "null" ]; then
            gh_print_status "ERROR" "No open PR found for current user"
            echo "Usage: $0 [PR_NUMBER] [--export FILE]"
            exit 1
        fi
        ;;
    "--help"|"-h")
        echo "Usage: $0 [PR_NUMBER] [--export FILE]"
        echo ""
        echo "Commands:"
        echo "  PR_NUMBER    - Analyze specific PR (default: current user's open PR)"
        echo "  --export     - Export analysis to markdown file"
        echo "  --help       - Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0                    # Analyze current user's open PR"
        echo "  $0 123               # Analyze PR #123"
        echo "  $0 123 --export analysis.md  # Export analysis to file"
        exit 0
        ;;
    *)
        PR_NUMBER="$1"
        ;;
esac

# Check if export is requested
EXPORT_FILE=""
if [ "$2" = "--export" ] && [ -n "$3" ]; then
    EXPORT_FILE="$3"
fi

# Validate PR number
if ! [[ "$PR_NUMBER" =~ ^[0-9]+$ ]]; then
    gh_print_status "ERROR" "Invalid PR number: $PR_NUMBER"
    exit 1
fi

# Check if PR exists
if ! gh pr view "$PR_NUMBER" >/dev/null 2>&1; then
    gh_print_status "ERROR" "PR #$PR_NUMBER not found"
    exit 1
fi

# Parse the Sourcery review
if parse_sourcery_review "$PR_NUMBER"; then
    # Generate the priority matrix report
    generate_priority_matrix_report
    
    # Export if requested
    if [ -n "$EXPORT_FILE" ]; then
        export_analysis_to_file "$EXPORT_FILE"
    fi
    
    gh_print_status "SUCCESS" "Priority matrix analysis completed!"
else
    gh_print_status "ERROR" "Failed to parse Sourcery review"
    exit 1
fi

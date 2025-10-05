#!/bin/bash

# Sourcery Review Parser - Final Fixed Version
# Extracts and formats Sourcery reviews for manual priority matrix assessment

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

gh_print_header "📋 Sourcery Review Parser (Fixed)"
echo ""

# ============================================================================
# CONFIGURATION
# ============================================================================

OUTPUT_FILE=""
THINK_MODE=false

# ============================================================================
# FIXED PARSING FUNCTIONS
# ============================================================================

extract_sourcery_review() {
    local pr_number="$1"
    
    gh_print_section "📋 Extracting Sourcery Review for PR #$pr_number"
    
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
    
    # Create clean output
    create_clean_output "$markdown_content" "$pr_number"
}

create_clean_output() {
    local content="$1"
    local pr_number="$2"
    
    local output=""
    
    # Header
    output+="# Sourcery Review Analysis\n"
    output+="**PR**: #$pr_number\n"
    output+="**Repository**: $PROJECT_REPO\n"
    output+="**Generated**: $(date)\n\n"
    output+="---\n\n"
    
    # Extract comment count
    local comment_count=$(echo "$content" | grep -c "^### Comment [0-9]")
    output+="## Summary\n\n"
    output+="Total Comments: $comment_count\n\n"

    if [ "$THINK_MODE" = true ]; then
        output+="### Parsing Notes (Think Mode)\n"
        output+="- We search for comments using the header pattern '### Comment N'\n"
        output+="- Location is taken from the first '<location>...</location>' tag, then HTML tags and backticks are stripped, and whitespace is trimmed\n"
        output+="- Type is the first bold '**...**' phrase; trailing colons are removed to normalize values like 'suggestion:' -> 'suggestion'\n"
        output+="- Description is the first non-empty, non-bold line between '<issue_to_address>' and the next code fence, with markdown tokens removed\n\n"
    fi
    
    # Comments section
    output+="## Individual Comments\n\n"
    
    # Split content by comment headers and process each
    local current_comment=""
    local comment_num=""
    local in_comment=false
    
    while IFS= read -r line; do
        if [[ "$line" =~ ^###\ Comment\ ([0-9]+) ]]; then
            # Process previous comment if exists
            if [ -n "$current_comment" ] && [ -n "$comment_num" ]; then
                output+=$(format_single_comment_fixed "$comment_num" "$current_comment")
            fi
            
            # Start new comment
            comment_num="${BASH_REMATCH[1]}"
            current_comment="$line"
            in_comment=true
        elif [ "$in_comment" = true ]; then
            current_comment="$current_comment"$'\n'"$line"
        fi
    done <<< "$content"
    
    # Process the last comment
    if [ -n "$current_comment" ] && [ -n "$comment_num" ]; then
        output+=$(format_single_comment_fixed "$comment_num" "$current_comment")
    fi
    
    # Priority Matrix Template
    output+="## Priority Matrix Assessment\n\n"
    output+="Use this template to assess each comment:\n\n"
    output+="| Comment | Priority | Impact | Effort | Notes |\n"
    output+="|---------|----------|--------|--------|-------|\n"
    
    # Add clean rows for each comment
    for i in $(seq 1 $comment_count); do
        output+="| #$i | | | | |\n"
    done
    
    output+="\n### Priority Levels\n"
    output+="- 🔴 **CRITICAL**: Security, stability, or core functionality issues\n"
    output+="- 🟠 **HIGH**: Bug risks or significant maintainability issues\n"
    output+="- 🟡 **MEDIUM**: Code quality and maintainability improvements\n"
    output+="- 🟢 **LOW**: Nice-to-have improvements\n\n"
    
    output+="### Impact Levels\n"
    output+="- 🔴 **CRITICAL**: Affects core functionality\n"
    output+="- 🟠 **HIGH**: User-facing or significant changes\n"
    output+="- 🟡 **MEDIUM**: Developer experience improvements\n"
    output+="- 🟢 **LOW**: Minor improvements\n\n"
    
    output+="### Effort Levels\n"
    output+="- 🟢 **LOW**: Simple, quick changes\n"
    output+="- 🟡 **MEDIUM**: Moderate complexity\n"
    output+="- 🟠 **HIGH**: Complex refactoring\n"
    output+="- 🔴 **VERY_HIGH**: Major rewrites\n\n"
    
    # Output the result
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "$output" > "$OUTPUT_FILE"
        gh_print_status "SUCCESS" "Review analysis saved to $OUTPUT_FILE"
    else
        echo -e "$output"
    fi
}

format_single_comment_fixed() {
    local comment_num="$1"
    local content="$2"
    
    local output=""
    
    output+="### Comment #$comment_num\n\n"
    
    # Extract location (FIXED - remove all backticks and extra spaces)
    local location=$(echo "$content" | grep -o '<location>.*</location>' | sed 's/<[^>]*>//g' | sed 's/`//g' | sed 's/^ *//;s/ *$//' | head -1)
    if [ -n "$location" ]; then
        output+="**Location**: \`$location\`\n\n"
    fi
    
    # Extract issue type (FIXED - remove trailing colons)
    local issue_type=$(echo "$content" | grep -o '\*\*[^*]*\*\*' | head -1 | sed 's/\*\*//g' | sed 's/:$//')
    if [ -n "$issue_type" ]; then
        output+="**Type**: $issue_type\n\n"
    fi
    
    # Extract description (FIXED - get clean description without markdown)
    local description=$(echo "$content" | sed -n '/<issue_to_address>/,/```/p' | grep -v '<issue_to_address>' | grep -v '^$' | grep -v '^\*\*' | head -1 | sed 's/^ *//;s/ *$//')
    if [ -n "$description" ]; then
        output+="**Description**: $description\n\n"
    fi

    if [ "$THINK_MODE" = true ]; then
        output+="<details>\n<summary>Reasoning (why these values)</summary>\n\n"
        output+="- Location extracted from first <location> tag; tags/backticks stripped; trimmed.\n"
        output+="- Type derived from first bold token; trailing colon removed for normalization.\n"
        output+="- Description chosen as first substantive line within <issue_to_address> block, excluding markdown and empty lines.\n\n"
        output+="</details>\n\n"
    fi
    
    # Add collapsible full content
    output+="<details>\n<summary>Full Comment Content</summary>\n\n"
    output+="\`\`\`\n"
    output+="$content"
    output+="\n\`\`\`\n\n"
    output+="</details>\n\n"
    output+="---\n\n"
    
    echo "$output"
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

PR_NUMBER=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --think|--explain|--verbose)
            THINK_MODE=true
            shift 1
            ;;
        --help|-h)
            echo "Usage: $0 [PR_NUMBER] [OPTIONS]"
            echo ""
            echo "Commands:"
            echo "  PR_NUMBER    - Analyze specific PR (default: current user's open PR)"
            echo ""
            echo "Options:"
            echo "  --output FILE      - Save output to file"
            echo "  --think            - Include reasoning about how fields were extracted"
            echo "  --help             - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Parse current user's open PR"
            echo "  $0 123               # Parse PR #123"
            echo "  $0 123 --output review.md         # Save to file"
            echo "  $0 123 --think                    # Show extraction reasoning"
            exit 0
            ;;
        *)
            if [[ "$1" =~ ^[0-9]+$ ]]; then
                PR_NUMBER="$1"
            else
                echo "❌ Error: Invalid argument '$1'"
                echo "Use --help for usage information"
                exit 1
            fi
            shift
            ;;
    esac
done

# Get PR number if not provided
if [ -z "$PR_NUMBER" ]; then
    PR_NUMBER=$(gh pr list --author "@me" --state open --json number --jq '.[0].number' 2>/dev/null)
    if [ -z "$PR_NUMBER" ] || [ "$PR_NUMBER" = "null" ]; then
        gh_print_status "ERROR" "No open PR found for current user"
        echo "Usage: $0 [PR_NUMBER] [OPTIONS]"
        echo "Use --help for more information"
        exit 1
    fi
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

# Extract and format the Sourcery review
if extract_sourcery_review "$PR_NUMBER"; then
    gh_print_status "SUCCESS" "Sourcery review parsing completed!"
else
    gh_print_status "ERROR" "Failed to parse Sourcery review"
    exit 1
fi

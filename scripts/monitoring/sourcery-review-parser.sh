#!/bin/bash

# Sourcery Review Parser for REPO-Magic
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

gh_print_header "📋 Sourcery Review Parser"
echo ""

# ============================================================================
# CONFIGURATION
# ============================================================================

# Output formats
OUTPUT_FORMAT="markdown"  # markdown, json, text
OUTPUT_FILE=""
VERBOSE=false

# ============================================================================
# SOURCERY REVIEW EXTRACTION
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
    
    # Parse and format the content
    parse_and_format_review "$markdown_content" "$pr_number"
}

parse_and_format_review() {
    local content="$1"
    local pr_number="$2"
    
    # Extract individual comments
    local comments=()
    local current_comment=""
    local in_comment=false
    local comment_num=""
    
    while IFS= read -r line; do
        # Check for comment header
        if [[ "$line" =~ ^###\ Comment\ ([0-9]+) ]]; then
            # Save previous comment if exists
            if [ -n "$current_comment" ] && [ -n "$comment_num" ]; then
                comments+=("$comment_num|$current_comment")
            fi
            
            # Start new comment
            comment_num="${BASH_REMATCH[1]}"
            current_comment="$line"
            in_comment=true
        elif [ "$in_comment" = true ]; then
            # Continue building current comment
            current_comment="$current_comment"$'\n'"$line"
        fi
    done <<< "$content"
    
    # Add the last comment
    if [ -n "$current_comment" ] && [ -n "$comment_num" ]; then
        comments+=("$comment_num|$current_comment")
    fi
    
    # Format and output the comments
    format_comments_output "${comments[@]}" "$pr_number"
}

format_comments_output() {
    local comments=("${@:1:$#-1}")
    local pr_number="${@: -1}"
    
    case "$OUTPUT_FORMAT" in
        "markdown")
            format_markdown_output "${comments[@]}" "$pr_number"
            ;;
        "json")
            format_json_output "${comments[@]}" "$pr_number"
            ;;
        "text")
            format_text_output "${comments[@]}" "$pr_number"
            ;;
        *)
            format_markdown_output "${comments[@]}" "$pr_number"
            ;;
    esac
}

format_markdown_output() {
    local comments=("${@:1:$#-1}")
    local pr_number="${@: -1}"
    
    local output=""
    
    # Header
    output+="# Sourcery Review Analysis\n"
    output+="**PR**: #$pr_number\n"
    output+="**Repository**: $PROJECT_REPO\n"
    output+="**Generated**: $(date)\n\n"
    output+="---\n\n"
    
    # Summary
    output+="## Summary\n\n"
    output+="Total Comments: ${#comments[@]}\n\n"
    
    # Comments
    output+="## Individual Comments\n\n"
    
    for comment_data in "${comments[@]}"; do
        local comment_num=$(echo "$comment_data" | cut -d'|' -f1)
        local comment_content=$(echo "$comment_data" | cut -d'|' -f2-)
        
        output+="### Comment #$comment_num\n\n"
        
        # Extract key information
        local location=$(echo "$comment_content" | grep -o '<location>.*</location>' | sed 's/<[^>]*>//g' | head -1)
        local issue_type=$(echo "$comment_content" | grep -o '\*\*[^*]*\*\*' | head -1 | sed 's/\*\*//g')
        local issue_description=$(echo "$comment_content" | grep -A 10 '<issue_to_address>' | grep -v '<issue_to_address>' | head -1)
        
        # Format the comment
        if [ -n "$location" ]; then
            output+="**Location**: \`$location\`\n\n"
        fi
        
        if [ -n "$issue_type" ]; then
            output+="**Type**: $issue_type\n\n"
        fi
        
        if [ -n "$issue_description" ]; then
            output+="**Description**: $issue_description\n\n"
        fi
        
        # Add the full comment content in a collapsible section
        output+="<details>\n<summary>Full Comment Content</summary>\n\n"
        output+="\`\`\`\n"
        output+="$comment_content"
        output+="\n\`\`\`\n\n"
        output+="</details>\n\n"
        output+="---\n\n"
    done
    
    # Priority Matrix Template
    output+="## Priority Matrix Assessment\n\n"
    output+="Use this template to assess each comment:\n\n"
    output+="| Comment | Priority | Impact | Effort | Notes |\n"
    output+="|---------|----------|--------|--------|-------|\n"
    
    for comment_data in "${comments[@]}"; do
        local comment_num=$(echo "$comment_data" | cut -d'|' -f1)
        output+="| #$comment_num | | | | |\n"
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

format_json_output() {
    local comments=("${@:1:$#-1}")
    local pr_number="${@: -1}"
    
    local output=""
    
    # Start JSON
    output+="{\n"
    output+="  \"pr_number\": $pr_number,\n"
    output+="  \"repository\": \"$PROJECT_REPO\",\n"
    output+="  \"generated\": \"$(date -Iseconds)\",\n"
    output+="  \"total_comments\": ${#comments[@]},\n"
    output+="  \"comments\": [\n"
    
    # Add each comment
    for i in "${!comments[@]}"; do
        local comment_data="${comments[$i]}"
        local comment_num=$(echo "$comment_data" | cut -d'|' -f1)
        local comment_content=$(echo "$comment_data" | cut -d'|' -f2-)
        
        # Extract key information
        local location=$(echo "$comment_content" | grep -o '<location>.*</location>' | sed 's/<[^>]*>//g' | head -1)
        local issue_type=$(echo "$comment_content" | grep -o '\*\*[^*]*\*\*' | head -1 | sed 's/\*\*//g')
        local issue_description=$(echo "$comment_content" | grep -A 10 '<issue_to_address>' | grep -v '<issue_to_address>' | head -1)
        
        output+="    {\n"
        output+="      \"comment_number\": $comment_num,\n"
        output+="      \"location\": \"$location\",\n"
        output+="      \"issue_type\": \"$issue_type\",\n"
        output+="      \"description\": \"$issue_description\",\n"
        output+="      \"full_content\": $(echo "$comment_content" | jq -Rs .)\n"
        output+="    }"
        
        # Add comma if not last item
        if [ $i -lt $((${#comments[@]} - 1)) ]; then
            output+=","
        fi
        output+="\n"
    done
    
    output+="  ]\n"
    output+="}\n"
    
    # Output the result
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "$output" > "$OUTPUT_FILE"
        gh_print_status "SUCCESS" "Review analysis saved to $OUTPUT_FILE"
    else
        echo -e "$output"
    fi
}

format_text_output() {
    local comments=("${@:1:$#-1}")
    local pr_number="${@: -1}"
    
    local output=""
    
    # Header
    output+="SOURCERY REVIEW ANALYSIS\n"
    output+="PR: #$pr_number\n"
    output+="Repository: $PROJECT_REPO\n"
    output+="Generated: $(date)\n"
    output+="Total Comments: ${#comments[@]}\n\n"
    output+="========================================\n\n"
    
    # Comments
    for comment_data in "${comments[@]}"; do
        local comment_num=$(echo "$comment_data" | cut -d'|' -f1)
        local comment_content=$(echo "$comment_data" | cut -d'|' -f2-)
        
        output+="COMMENT #$comment_num\n"
        output+="----------------------------------------\n"
        
        # Extract key information
        local location=$(echo "$comment_content" | grep -o '<location>.*</location>' | sed 's/<[^>]*>//g' | head -1)
        local issue_type=$(echo "$comment_content" | grep -o '\*\*[^*]*\*\*' | head -1 | sed 's/\*\*//g')
        local issue_description=$(echo "$comment_content" | grep -A 10 '<issue_to_address>' | grep -v '<issue_to_address>' | head -1)
        
        if [ -n "$location" ]; then
            output+="Location: $location\n"
        fi
        
        if [ -n "$issue_type" ]; then
            output+="Type: $issue_type\n"
        fi
        
        if [ -n "$issue_description" ]; then
            output+="Description: $issue_description\n"
        fi
        
        output+="\nFull Content:\n"
        output+="$comment_content\n"
        output+="\n========================================\n\n"
    done
    
    # Output the result
    if [ -n "$OUTPUT_FILE" ]; then
        echo -e "$output" > "$OUTPUT_FILE"
        gh_print_status "SUCCESS" "Review analysis saved to $OUTPUT_FILE"
    else
        echo -e "$output"
    fi
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

PR_NUMBER=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [PR_NUMBER] [OPTIONS]"
            echo ""
            echo "Commands:"
            echo "  PR_NUMBER    - Analyze specific PR (default: current user's open PR)"
            echo ""
            echo "Options:"
            echo "  --format FORMAT    - Output format: markdown, json, text (default: markdown)"
            echo "  --output FILE      - Save output to file"
            echo "  --verbose          - Enable verbose output"
            echo "  --help             - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                    # Parse current user's open PR"
            echo "  $0 123               # Parse PR #123"
            echo "  $0 123 --format json # Output as JSON"
            echo "  $0 123 --output review.md # Save to file"
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

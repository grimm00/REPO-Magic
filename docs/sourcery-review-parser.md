# Sourcery Review Parser

**Location**: `scripts/monitoring/sourcery-review-parser.sh`  
**Purpose**: Extract and format Sourcery reviews for manual priority matrix assessment  
**Status**: ✅ **PRODUCTION READY**

---

## 📋 Overview

The Sourcery Review Parser is a focused tool that extracts Sourcery code review comments from GitHub PRs and formats them in a clean, structured way for manual assessment. This tool provides the raw review data without automated priority assignment, allowing you to apply your own priority matrix methodology.

### 🎯 Key Features

- **Clean Extraction**: Parses Sourcery reviews from GitHub PRs
- **Multiple Formats**: Output in Markdown, JSON, or plain text
- **Structured Data**: Extracts location, issue type, and descriptions
- **Manual Assessment**: Provides template for your own priority matrix
- **Export Ready**: Save formatted reviews for documentation and sharing
- **Flexible Output**: Console display or file export

---

## 🚀 Usage

### Basic Usage

```bash
# Parse current user's open PR (markdown format)
./scripts/monitoring/sourcery-review-parser.sh

# Parse specific PR
./scripts/monitoring/sourcery-review-parser.sh 123

# Output to file
./scripts/monitoring/sourcery-review-parser.sh 123 --output review.md

# JSON format
./scripts/monitoring/sourcery-review-parser.sh 123 --format json

# Plain text format
./scripts/monitoring/sourcery-review-parser.sh 123 --format text
```

### Command Options

| Option | Description | Example |
|--------|-------------|---------|
| `PR_NUMBER` | Specific PR to analyze | `./parser.sh 123` |
| `--format FORMAT` | Output format: `markdown`, `json`, `text` | `--format json` |
| `--output FILE` | Save output to file | `--output review.md` |
| `--verbose` | Enable verbose output | `--verbose` |
| `--help` | Show help message | `--help` |

### Examples

```bash
# Quick review of current PR
./scripts/monitoring/sourcery-review-parser.sh

# Detailed analysis with file export
./scripts/monitoring/sourcery-review-parser.sh 1 --output sourcery-review.md

# JSON for programmatic processing
./scripts/monitoring/sourcery-review-parser.sh 1 --format json --output review.json

# Plain text for simple review
./scripts/monitoring/sourcery-review-parser.sh 1 --format text
```

---

## 📊 Output Formats

### Markdown Format (Default)

```markdown
# Sourcery Review Analysis
**PR**: #1
**Repository**: grimm00/REPO-Magic
**Generated**: 2025-10-04T22:29:42-05:00

## Summary
Total Comments: 9

## Individual Comments

### Comment #1
**Location**: `scripts/setup/github-setup.sh:51-63`
**Type**: suggestion
**Description**: Manual confirmation step may block automation.

<details>
<summary>Full Comment Content</summary>
[Complete comment content...]
</details>

## Priority Matrix Assessment
| Comment | Priority | Impact | Effort | Notes |
|---------|----------|--------|--------|-------|
| #1 | | | | |
| #2 | | | | |
```

### JSON Format

```json
{
  "pr_number": 1,
  "repository": "grimm00/REPO-Magic",
  "generated": "2025-10-04T22:29:49-05:00",
  "total_comments": 9,
  "comments": [
    {
      "comment_number": 1,
      "location": "scripts/setup/github-setup.sh:51-63",
      "issue_type": "suggestion",
      "description": "Manual confirmation step may block automation.",
      "full_content": "### Comment 1\n<location>..."
    }
  ]
}
```

### Text Format

```
SOURCERY REVIEW ANALYSIS
PR: #1
Repository: grimm00/REPO-Magic
Generated: Sat Oct  4 10:29:42 PM CDT 2025
Total Comments: 9

========================================

COMMENT #1
----------------------------------------
Location: scripts/setup/github-setup.sh:51-63
Type: suggestion
Description: Manual confirmation step may block automation.

Full Content:
[Complete comment content...]

========================================
```

---

## 🎯 Manual Priority Matrix Assessment

The tool provides a template for your own priority matrix assessment:

### Priority Levels
- 🔴 **CRITICAL**: Security, stability, or core functionality issues
- 🟠 **HIGH**: Bug risks or significant maintainability issues  
- 🟡 **MEDIUM**: Code quality and maintainability improvements
- 🟢 **LOW**: Nice-to-have improvements

### Impact Levels
- 🔴 **CRITICAL**: Affects core functionality
- 🟠 **HIGH**: User-facing or significant changes
- 🟡 **MEDIUM**: Developer experience improvements
- 🟢 **LOW**: Minor improvements

### Effort Levels
- 🟢 **LOW**: Simple, quick changes
- 🟡 **MEDIUM**: Moderate complexity
- 🟠 **HIGH**: Complex refactoring
- 🔴 **VERY_HIGH**: Major rewrites

### Assessment Template

Use the provided table to assess each comment:

| Comment | Priority | Impact | Effort | Notes |
|---------|----------|--------|--------|-------|
| #1 | 🟡 MEDIUM | 🟡 MEDIUM | 🟢 LOW | Automation improvement |
| #2 | 🔴 CRITICAL | 🟠 HIGH | 🟡 MEDIUM | Security concern |

---

## 🔧 Technical Implementation

### Dependencies

- **GitHub CLI** (`gh`) - For PR data access
- **Bash 4.0+** - For array handling
- **Standard Unix tools** - `grep`, `sed`, `awk`
- **jq** (optional) - For JSON formatting

### Architecture

```
sourcery-review-parser.sh
├── Review Extraction
│   ├── extract_sourcery_review()
│   └── parse_and_format_review()
├── Output Formatting
│   ├── format_markdown_output()
│   ├── format_json_output()
│   └── format_text_output()
└── Command Line Interface
    ├── Argument parsing
    └── Help system
```

### Key Functions

#### `extract_sourcery_review(pr_number)`
- Fetches Sourcery review from GitHub PR
- Extracts markdown content from review body
- Handles missing or malformed reviews

#### `parse_and_format_review(content, pr_number)`
- Parses individual comments from markdown
- Extracts key information (location, type, description)
- Formats output according to selected format

#### `format_markdown_output(comments, pr_number)`
- Creates structured markdown report
- Includes priority matrix template
- Provides collapsible sections for full content

---

## 📋 Integration with Development Workflow

### Code Review Process

1. **Create PR**: Submit code for review
2. **Wait for Sourcery**: Let Sourcery analyze the code
3. **Parse Review**: `./sourcery-review-parser.sh [PR_NUMBER]`
4. **Manual Assessment**: Apply your priority matrix
5. **Plan Implementation**: Focus on high-priority items
6. **Track Progress**: Re-parse after addressing issues

### Handling incomplete/partial reviews

- Sometimes the GitHub UI or API returns truncated Sourcery comments (missing code blocks or sections).
- When fields are incomplete, the parser may omit rows or leave blanks by design (to avoid mixing partial data).
- Recommended workflow:
  - Re-run the parser against the latest PR state.
  - If the missing context is still not present, manually copy the relevant text from the PR UI and paste it below the corresponding comment in the output file (clearly mark as “Manual context”).
  - Optionally, maintain a separate appendix with manual additions for auditability.

### Sprint Planning

1. **Extract Reviews**: Parse all relevant PRs
2. **Assess Priorities**: Apply your priority matrix
3. **Estimate Effort**: Use effort levels for time planning
4. **Create Tasks**: Convert high-priority items to tasks
5. **Allocate Resources**: Plan based on impact and effort

### Documentation

1. **Export Reviews**: Save parsed reviews to files
2. **Share Analysis**: Include in PR discussions
3. **Track Decisions**: Document priority assessments
4. **Archive Results**: Keep historical analysis

---

## 🎯 Best Practices

### For Individual Developers

- **Parse Early**: Extract reviews immediately after Sourcery analysis
- **Focus on Critical**: Address security and stability issues first
- **Batch Similar**: Group related improvements together
- **Document Decisions**: Explain priority assessments

### For Teams

- **Standardize Process**: Use consistent priority matrix
- **Share Analysis**: Export and share parsed reviews
- **Regular Reviews**: Parse reviews in team meetings
- **Track Trends**: Monitor common issue patterns

### For Project Management

- **Resource Planning**: Use effort estimates for scheduling
- **Risk Assessment**: Monitor critical issue trends
- **Quality Metrics**: Track improvement implementation
- **Process Improvement**: Identify review bottlenecks

---

## 🔮 Advanced Usage

### Batch Processing

```bash
# Parse multiple PRs
for pr in 1 2 3 4 5; do
    ./scripts/monitoring/sourcery-review-parser.sh $pr --output "review-$pr.md"
done
```

### Integration with Other Tools

```bash
# Parse and open in editor
./scripts/monitoring/sourcery-review-parser.sh 1 --output review.md && code review.md

# Parse and send to team
./scripts/monitoring/sourcery-review-parser.sh 1 --output review.md && slack-cli send review.md
```

### Custom Processing

```bash
# Extract just the JSON for custom processing
./scripts/monitoring/sourcery-review-parser.sh 1 --format json | jq '.comments[] | select(.issue_type | contains("security"))'
```

---

## 🐛 Troubleshooting

### Common Issues

#### "No Sourcery review found"
- **Cause**: PR doesn't have a Sourcery review yet
- **Solution**: Wait for Sourcery to complete analysis

#### "No markdown content found"
- **Cause**: Sourcery review format changed
- **Solution**: Check Sourcery review format and update parsing logic

#### "Invalid PR number"
- **Cause**: PR doesn't exist or no access
- **Solution**: Verify PR number and GitHub authentication

#### "jq: command not found" (JSON format)
- **Cause**: jq not installed
- **Solution**: Install jq or use markdown/text format

### Debug Mode

Enable verbose output for troubleshooting:

```bash
./scripts/monitoring/sourcery-review-parser.sh 1 --verbose
```

---

## 📚 Related Documentation

- [Sourcery Priority Matrix](sourcery-priority-matrix.md) - Automated analysis tool
- [GitHub Integration Guide](github-integration.md)
- [Project Status Monitoring](project-status.md)
- [Git Workflow](git-workflow.md)

---

## 🤝 Contributing

### Adding New Output Formats

1. Create new `format_*_output()` function
2. Add format to argument parsing
3. Update help documentation
4. Test with sample reviews

### Improving Parsing Logic

1. Analyze Sourcery review format changes
2. Update regex patterns in parsing functions
3. Test with various review formats
4. Add error handling for edge cases

---

**Last Updated**: October 4, 2025  
**Version**: 1.0.0  
**Maintainer**: Development Team

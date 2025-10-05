# Sourcery Priority Matrix Analyzer

**Location**: `scripts/monitoring/sourcery-priority-matrix.sh`  
**Purpose**: Automatically parse Sourcery code reviews and apply priority matrix analysis  
**Status**: ✅ **PRODUCTION READY**

---

## 📋 Overview

The Sourcery Priority Matrix Analyzer is an automated tool that extracts Sourcery code review comments from GitHub PRs and applies a sophisticated priority matrix to help developers focus on the most impactful improvements first.

### 🎯 Key Features

- **Automated Parsing**: Extracts Sourcery reviews from GitHub PRs
- **Priority Matrix**: Categorizes issues by Priority, Impact, and Effort
- **Smart Scoring**: Calculates weighted priority scores for optimal ordering
- **Action Planning**: Provides sprint planning recommendations
- **Export Functionality**: Generates markdown reports for documentation
- **Integration Ready**: Works with existing GitHub CLI setup

---

## 🚀 Usage

### Basic Usage

```bash
# Analyze current user's open PR
./scripts/monitoring/sourcery-priority-matrix.sh

# Analyze specific PR
./scripts/monitoring/sourcery-priority-matrix.sh 123

# Export analysis to file
./scripts/monitoring/sourcery-priority-matrix.sh 123 --export analysis.md
```

### Examples

```bash
# Analyze PR #1 and export results
./scripts/monitoring/sourcery-priority-matrix.sh 1 --export sourcery-analysis.md

# Quick analysis of current PR
./scripts/monitoring/sourcery-priority-matrix.sh
```

---

## 📊 Priority Matrix System

### Priority Levels

| Priority | Weight | Description |
|----------|--------|-------------|
| 🔴 **CRITICAL** | 10 | Security, stability, or core functionality issues |
| 🟠 **HIGH** | 7 | Bug risks or significant maintainability issues |
| 🟡 **MEDIUM** | 4 | Code quality and maintainability improvements |
| 🟢 **LOW** | 1 | Nice-to-have improvements |
| 🔵 **ENHANCEMENT** | 0.5 | Future feature considerations |

### Impact Levels

| Impact | Weight | Description |
|--------|--------|-------------|
| 🔴 **CRITICAL** | 10 | Affects core functionality |
| 🟠 **HIGH** | 7 | User-facing or significant changes |
| 🟡 **MEDIUM** | 4 | Developer experience improvements |
| 🟢 **LOW** | 1 | Minor improvements |

### Effort Levels

| Effort | Weight | Description |
|--------|--------|-------------|
| 🟢 **LOW** | 10 | Simple, quick changes |
| 🟡 **MEDIUM** | 6 | Moderate complexity |
| 🟠 **HIGH** | 3 | Complex refactoring |
| 🔴 **VERY_HIGH** | 1 | Major rewrites |

### Priority Score Calculation

```
Priority Score = Priority Weight × Impact Weight × Effort Weight
```

**Higher scores = Higher priority for implementation**

---

## 📈 Sample Output

```
🎯 Sourcery Priority Matrix Analyzer
═══════════════════════════════════

📋 Parsing Sourcery Review for PR #1
📊 Priority Matrix Analysis Report

📈 Priority Distribution:
   🟠 HIGH: 4 comment(s)
   🔴 CRITICAL: 5 comment(s)

🎯 Recommended Action Plan:

Comment #2 (Score: 0)
   Location: scripts/core/github-utils.sh:340
   Type: 🚨 suggestion (security):
   Priority: 🔴 CRITICAL
   Impact: 🟢 LOW
   Effort: 🟡 MEDIUM
   Description: Fallback for secret generation may not be cryptographically secure.

💡 Implementation Recommendations:

🚀 Immediate Actions (This Sprint):
   🔴 Address 5 CRITICAL issue(s) immediately
   🔴 These may affect security, stability, or core functionality
   🟠 Address 4 HIGH priority issue(s) this sprint
   🟠 These may cause bugs or significant maintainability issues

📊 Priority Matrix Summary:
   Total Comments: 9
   Critical: 5
   High: 4
   Medium: 0
   Low: 0
```

---

## 🔧 Technical Implementation

### Dependencies

- **GitHub CLI** (`gh`) - For PR data access
- **Bash 4.0+** - For associative arrays
- **bc** - For mathematical calculations
- **Standard Unix tools** - `grep`, `sed`, `awk`

### Architecture

```
sourcery-priority-matrix.sh
├── Priority Matrix Configuration
│   ├── PRIORITY_WEIGHTS
│   ├── IMPACT_WEIGHTS
│   └── EFFORT_WEIGHTS
├── Sourcery Review Parsing
│   ├── parse_sourcery_review()
│   ├── parse_individual_comment()
│   └── analyze_comment()
├── Analysis Storage
│   ├── COMMENT_ANALYSES
│   └── PRIORITY_COUNTS
└── Reporting
    ├── generate_priority_matrix_report()
    └── export_analysis_to_file()
```

### Key Functions

#### `parse_sourcery_review(pr_number)`
- Extracts Sourcery review from GitHub PR
- Parses markdown code blocks
- Identifies individual comments

#### `analyze_comment(comment_num, content)`
- Determines priority based on issue type
- Assesses impact and effort levels
- Calculates weighted priority score

#### `generate_priority_matrix_report()`
- Sorts comments by priority score
- Provides sprint planning recommendations
- Displays actionable insights

---

## 📋 Integration with Development Workflow

### Sprint Planning

1. **Run Analysis**: `./scripts/monitoring/sourcery-priority-matrix.sh [PR_NUMBER]`
2. **Review Priorities**: Focus on CRITICAL and HIGH priority items
3. **Plan Sprint**: Allocate time based on effort estimates
4. **Track Progress**: Re-run analysis after addressing issues

### Code Review Process

1. **Create PR**: Submit code for review
2. **Wait for Sourcery**: Let Sourcery analyze the code
3. **Run Priority Matrix**: Analyze Sourcery feedback
4. **Address Issues**: Focus on high-priority items first
5. **Iterate**: Re-run analysis as needed

### Documentation

1. **Export Analysis**: `--export analysis.md`
2. **Share Results**: Include in PR discussions
3. **Track Decisions**: Document why certain issues were deferred
4. **Archive**: Keep historical analysis for reference

---

## 🎯 Best Practices

### For Developers

- **Run Early**: Analyze Sourcery feedback immediately after review
- **Focus on Critical**: Address security and stability issues first
- **Batch Similar Issues**: Group related improvements together
- **Document Decisions**: Explain why certain issues are deferred

### For Teams

- **Standardize Process**: Use priority matrix for all Sourcery reviews
- **Sprint Integration**: Include priority analysis in sprint planning
- **Knowledge Sharing**: Export and share analysis with team
- **Continuous Improvement**: Refine priority weights based on experience

### For Project Management

- **Resource Allocation**: Use effort estimates for time planning
- **Risk Assessment**: Monitor critical issue trends
- **Quality Metrics**: Track improvement implementation rates
- **Process Optimization**: Identify bottlenecks in review process

---

## 🔮 Future Enhancements

### Planned Features

- **Historical Analysis**: Track priority trends over time
- **Team Metrics**: Aggregate analysis across multiple PRs
- **Custom Weights**: Allow project-specific priority configurations
- **Integration**: Direct integration with project management tools

### Potential Integrations

- **GitHub Actions**: Automated analysis on PR creation
- **Slack/Teams**: Notifications for critical issues
- **Jira/Linear**: Create tickets from high-priority issues
- **CI/CD**: Block merges for critical security issues

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

### Debug Mode

Add debug output by modifying the script:

```bash
# Add debug output in parse_individual_comment()
echo "DEBUG: Processing $comment_header -> comment_num: '$comment_num'"
```

---

## 📚 Related Documentation

- [GitHub Integration Guide](github-integration.md)
- [Project Status Monitoring](project-status.md)
- [Git Workflow](git-workflow.md)
- [Sourcery Configuration](.sourcery.yaml)

---

## 🤝 Contributing

### Adding New Priority Categories

1. Update `PRIORITY_WEIGHTS` array
2. Modify `determine_priority()` function
3. Update documentation
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

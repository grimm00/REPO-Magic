#!/usr/bin/env bash

set -euo pipefail

# Save rich-detail Sourcery PR review output into docs/feedback
# Usage: pr-feedback.sh <PR_NUMBER> [output-name]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PARSER="$REPO_ROOT/scripts/monitoring/sourcery-review-parser.sh"
FEEDBACK_DIR="$REPO_ROOT/docs/feedback"

PR_NUMBER="${1:-}"
OUT_NAME="${2:-}"

if [ -z "$PR_NUMBER" ]; then
  echo "Usage: $0 <PR_NUMBER> [output-name]"
  exit 1
fi

mkdir -p "$FEEDBACK_DIR"

if [ -z "$OUT_NAME" ]; then
  OUT_NAME="sourcery-review-pr${PR_NUMBER}-rich.md"
fi

if [ ! -x "$PARSER" ]; then
  echo "Error: parser not found at $PARSER"
  exit 1
fi

"$PARSER" "$PR_NUMBER" --rich-details --output "$FEEDBACK_DIR/$OUT_NAME"

echo "Saved rich feedback to: $FEEDBACK_DIR/$OUT_NAME"



#!/bin/bash
# review-conflicts/branch-context.sh
# Establish branch context: current branch, base, recent active sibling branches, open PRs.
# Read-only. Run from project repo root.
#
# Usage: bash branch-context.sh <base-branch>
# Output: ===SECTION=== delimited blocks to stdout.

set +e

BASE="${1:-staging}"

echo "===CURRENT_BRANCH==="
git branch --show-current 2>/dev/null

echo "===BASE==="
echo "origin/$BASE"

echo "===FETCH==="
git fetch origin --quiet 2>&1 || echo "[fetch failed — using local refs only]"

echo "===AHEAD_COUNT==="
git rev-list --count "origin/$BASE..HEAD" 2>/dev/null

echo "===ACTIVE_BRANCHES==="
# Recent sibling branches (last 30 days). One per line: <ref> <relative-date>.
git for-each-ref --sort=-committerdate \
  --format='%(refname:short) %(committerdate:relative)' \
  refs/remotes/origin/ 2>/dev/null | head -20

echo "===OPEN_PRS==="
# Skip silently if gh unavailable or unauthenticated.
if command -v gh >/dev/null 2>&1; then
  gh pr list --state open --json number,title,headRefName --limit 50 2>/dev/null \
    || echo "[]"
else
  echo "[gh CLI not available]"
fi

echo "===END==="

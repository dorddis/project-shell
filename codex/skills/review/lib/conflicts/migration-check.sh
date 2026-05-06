#!/bin/bash
# review-conflicts/migration-check.sh
# C3 migration / schema collision detection across active sibling branches.
# Read-only. Run from project repo root.
#
# Usage: bash migration-check.sh <base> <migration-dir> [active-branches]
# Default migration-dir: database/migrations
# Output: ===SECTION=== delimited blocks: this branch's migrations + each sibling's migrations.
#
# Notes:
#   - Caller is responsible for spotting number collisions in the output (compare numeric prefixes).
#   - Only runs `git ls-tree`; does not invoke psql or apply anything.

set +e

BASE="${1:-staging}"
MIG_DIR="${2:-database/migrations}"
shift 2
ACTIVE="$*"

if [ -z "$ACTIVE" ] && [ ! -t 0 ]; then
  ACTIVE=$(cat | tr '\n' ' ')
fi

echo "===THIS_BRANCH_MIGRATIONS_IN_DIFF==="
# Migration files added or modified in the current diff.
git diff --name-only "origin/$BASE...HEAD" -- "$MIG_DIR/" 2>/dev/null

echo "===THIS_BRANCH_ALL_MIGRATIONS==="
# All migration files visible on the current branch (for sequence reference).
git ls-tree -r --name-only HEAD -- "$MIG_DIR/" 2>/dev/null | sort

echo "===SIBLING_BRANCH_MIGRATIONS==="
CURRENT=$(git branch --show-current 2>/dev/null)
if [ -z "$ACTIVE" ]; then
  echo "[no active sibling branches]"
else
  for branch in $ACTIVE; do
    [ "$branch" = "origin/$BASE" ] && continue
    [ "$branch" = "origin/$CURRENT" ] && continue
    [ "$branch" = "$CURRENT" ] && continue
    files=$(git ls-tree -r --name-only "$branch" -- "$MIG_DIR/" 2>/dev/null | sort)
    if [ -n "$files" ]; then
      echo "BRANCH: $branch"
      echo "$files"
      echo "---"
    fi
  done
fi

echo "===END==="

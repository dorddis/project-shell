#!/bin/bash
# review-conflicts/conflict-checks.sh
# C1 textual merge check + C2 file-overlap detection against active sibling branches.
# Read-only. Run from project repo root.
#
# Usage: bash conflict-checks.sh <base> [active-branches-newline-or-space-separated]
# Output: ===SECTION=== delimited blocks. Pass active branches via stdin OR positional args.
#
# Examples:
#   bash conflict-checks.sh staging "origin/feature/x origin/feature/y"
#   bash branch-context.sh staging | grep -A20 ACTIVE_BRANCHES | tail -n+2 | awk '{print $1}' | xargs bash conflict-checks.sh staging

set +e

BASE="${1:-staging}"
shift
ACTIVE="$*"

# Read from stdin if no active-branches arg supplied.
if [ -z "$ACTIVE" ] && [ ! -t 0 ]; then
  ACTIVE=$(cat | tr '\n' ' ')
fi

echo "===CHANGED_FILES==="
git diff --name-only "origin/$BASE...HEAD" 2>/dev/null

echo "===TEXTUAL_MERGE==="
# git merge-tree on the merge-base + both heads. Conflict markers appear as `+<<<<<<<`.
MERGE_BASE=$(git merge-base "origin/$BASE" HEAD 2>/dev/null)
if [ -n "$MERGE_BASE" ]; then
  git merge-tree "$MERGE_BASE" "origin/$BASE" HEAD 2>&1 | head -200
else
  echo "[no merge-base — branches do not share history]"
fi

echo "===FILE_OVERLAPS==="
# For each changed file, list active branches that also touch it.
# Skips the base branch and the current branch itself.
CURRENT=$(git branch --show-current 2>/dev/null)
CHANGED_FILES=$(git diff --name-only "origin/$BASE...HEAD" 2>/dev/null)

if [ -z "$CHANGED_FILES" ] || [ -z "$ACTIVE" ]; then
  echo "[no changed files OR no active sibling branches — skipping]"
else
  for changed in $CHANGED_FILES; do
    for branch in $ACTIVE; do
      [ "$branch" = "origin/$BASE" ] && continue
      [ "$branch" = "origin/$CURRENT" ] && continue
      [ "$branch" = "$CURRENT" ] && continue
      sibling_files=$(git diff --name-only "$branch...origin/$BASE" 2>/dev/null)
      if echo "$sibling_files" | grep -qF "$changed"; then
        echo "FILE: $changed BRANCH: $branch"
      fi
    done
  done
fi

echo "===END==="

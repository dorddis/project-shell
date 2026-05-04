#!/bin/bash
# wrap/lib/commit.sh — wrap commit + amend with self-referencing hash patch.
# Run from project repo root.
#
# Usage:
#   bash .claude/skills/wrap/lib/commit.sh <session-name> ["<message-body>"]
#
# Workflow:
#   1. git add -A; if anything staged, commit with "wrap: <name> - <message>"
#      Otherwise (all changes gitignored, e.g. .build/ projects), skip commit
#      and patch the session log with a "no parent-repo commit" marker.
#   2. Patch session log's "**Commit:** ..." line with the new short SHA (or
#      no-commit marker).
#   3. If a commit happened AND the session file is in a tracked path, amend
#      to fold in the patched session log. If the session file is gitignored
#      (.build/cache/sessions/), the patch still happens but the amend is
#      skipped (git add would silently no-op anyway).
#   4. Print final SHA (or no-commit notice).
#
# Note: when amend happens, the hash inside the session log references the
# PRE-amend commit (which no longer exists). The hash inside the log is
# informational, not a referencable git object.

set -e

NAME="$1"
MSG="$2"

if [ -z "$NAME" ]; then
  echo "Usage: commit.sh <session-name> [message-body]" >&2
  exit 2
fi

# Resolve session file path. Session files follow the YYYY-MM-DD_<name>.md
# convention (set by the wrap skill SKILL.md), but commit.sh is invoked with
# just <name>. So we search candidate dirs in priority order, trying the
# dated glob first then a plain <name>.md fallback in each. .build/cache/
# sessions/ is the current convention; sessions/ at repo root is legacy.
# Both may coexist during a migration — search across both, don't lock to
# one based on dir existence (an empty .build/cache/sessions/ shouldn't
# block a fallback to a tracked sessions/ that holds the actual file).
SESSION_FILE=""
for dir in ".build/cache/sessions" "sessions"; do
  [ -d "$dir" ] || continue
  # Dated form first: YYYY-MM-DD_<name>.md (or any *_<name>.md prefix)
  candidate=$(ls -t "$dir"/*_"$NAME".md 2>/dev/null | head -n 1)
  if [ -n "$candidate" ]; then
    SESSION_FILE="$candidate"
    break
  fi
  # Plain <name>.md fallback
  if [ -f "$dir/$NAME.md" ]; then
    SESSION_FILE="$dir/$NAME.md"
    break
  fi
done

# Stage everything not gitignored
git add -A

# Build commit message
COMMIT_MSG="wrap: $NAME"
if [ -n "$MSG" ]; then
  COMMIT_MSG="$COMMIT_MSG - $MSG"
fi

# Detect whether anything actually got staged. If working tree was clean
# (e.g. all wrap output lives under gitignored .build/), there's nothing
# to commit — patch the session log with a marker and bail gracefully.
if git diff --cached --quiet; then
  echo "No tracked changes to commit (likely all wrap output is gitignored)."
  if [ -f "$SESSION_FILE" ]; then
    sed -i "s|\*\*Commit:\*\* .*|\*\*Commit:\*\* none in parent repo (all session artifacts gitignored under .build/)|" "$SESSION_FILE"
    echo "Session log marked 'none in parent repo': $SESSION_FILE"
  fi
  echo "Done (no-commit path)."
  exit 0
fi

# Real commit
git commit -m "$COMMIT_MSG"
PRE_AMEND_HASH=$(git rev-parse --short HEAD)

# Patch session log + amend (or just patch if session log is gitignored)
if [ -f "$SESSION_FILE" ]; then
  # Use | as sed delimiter so paths/hashes with / don't break the expression.
  sed -i "s|\*\*Commit:\*\* .*|\*\*Commit:\*\* $PRE_AMEND_HASH|" "$SESSION_FILE"

  # Try to fold the patched session log into the commit via amend.
  # If the file is gitignored (e.g. lives under .build/), git add silently
  # no-ops and the amend is effectively the same commit. Either way, the
  # in-file hash gets patched — that's what matters for the session log
  # being self-documenting.
  git add "$SESSION_FILE" 2>/dev/null || true
  if ! git diff --cached --quiet; then
    git commit --amend --no-edit
  fi
fi

FINAL_HASH=$(git rev-parse --short HEAD)
echo "Committed: $FINAL_HASH (session log references hash $PRE_AMEND_HASH)"

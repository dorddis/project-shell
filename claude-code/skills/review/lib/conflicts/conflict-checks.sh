#!/bin/bash
# review/lib/conflicts/conflict-checks.sh
# Textual merge check and file-overlap detection against active sibling branches.
#
# Usage:
#   conflict-checks.sh [--base staging] [--repo-dir PATH] [active-branches...]
# Backward-compatible shorthand:
#   conflict-checks.sh [base] [active-branches...]

set +e

BASE="staging"
REPO_DIR=""
ACTIVE_ARGS=()

normalize_path() {
  local p="$1"
  [ -z "$p" ] && return
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$p" 2>/dev/null && return
  fi
  echo "$p"
}

if [ $# -gt 0 ] && [[ "$1" != --* ]]; then
  BASE="$1"; shift
fi
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    --*) echo "Unknown arg: $1" >&2; exit 2 ;;
    *) ACTIVE_ARGS+=("$1"); shift ;;
  esac
done

REPO_DIR="$(normalize_path "$REPO_DIR")"
[ -z "$REPO_DIR" ] && REPO_DIR="$(normalize_path "$(git rev-parse --show-toplevel 2>/dev/null)")"

ACTIVE=""
if [ ${#ACTIVE_ARGS[@]} -gt 0 ]; then
  ACTIVE="${ACTIVE_ARGS[*]}"
elif [ ! -t 0 ]; then
  ACTIVE=$(cat | tr '\n' ' ')
fi

echo "===CONTEXT==="
echo "repo_dir: $REPO_DIR"
echo "base: $BASE"

echo "===CHANGED_FILES==="
git -C "$REPO_DIR" diff --name-only "origin/$BASE...HEAD" 2>/dev/null

echo "===TEXTUAL_MERGE==="
MERGE_BASE=$(git -C "$REPO_DIR" merge-base "origin/$BASE" HEAD 2>/dev/null)
if [ -n "$MERGE_BASE" ]; then
  git -C "$REPO_DIR" merge-tree "$MERGE_BASE" "origin/$BASE" HEAD 2>&1 | head -200
else
  echo "[no merge-base; branches do not share history]"
fi

echo "===FILE_OVERLAPS==="
CURRENT=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null)
CHANGED_FILES=$(git -C "$REPO_DIR" diff --name-only "origin/$BASE...HEAD" 2>/dev/null)

if [ -z "$CHANGED_FILES" ] || [ -z "$ACTIVE" ]; then
  echo "[no changed files OR no active sibling branches; skipping]"
else
  while IFS= read -r changed; do
    [ -z "$changed" ] && continue
    for branch in $ACTIVE; do
      [ "$branch" = "origin/$BASE" ] && continue
      [ "$branch" = "origin/$CURRENT" ] && continue
      [ "$branch" = "$CURRENT" ] && continue
      sibling_files=$(git -C "$REPO_DIR" diff --name-only "origin/$BASE...$branch" 2>/dev/null)
      if echo "$sibling_files" | grep -qF "$changed"; then
        echo "FILE: $changed BRANCH: $branch"
      fi
    done
  done <<< "$CHANGED_FILES"
fi

echo "===END==="

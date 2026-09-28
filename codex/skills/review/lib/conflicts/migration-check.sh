#!/bin/bash
# review/lib/conflicts/migration-check.sh
# Migration/schema collision detection across active sibling branches.
#
# Usage:
#   migration-check.sh [--base staging] [--migration-dir database/migrations] [--repo-dir PATH] [active-branches...]
# Backward-compatible shorthand:
#   migration-check.sh [base] [migration-dir] [active-branches...]

set +e

BASE="staging"
MIG_DIR="database/migrations"
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
if [ $# -gt 0 ] && [[ "$1" != --* ]]; then
  MIG_DIR="$1"; shift
fi
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --migration-dir) MIG_DIR="$2"; shift 2 ;;
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
echo "migration_dir: $MIG_DIR"

echo "===THIS_BRANCH_MIGRATIONS_IN_DIFF==="
git -C "$REPO_DIR" diff --name-only "origin/$BASE...HEAD" -- "$MIG_DIR/" 2>/dev/null

echo "===THIS_BRANCH_ALL_MIGRATIONS==="
git -C "$REPO_DIR" ls-tree -r --name-only HEAD -- "$MIG_DIR/" 2>/dev/null | sort

echo "===SIBLING_BRANCH_MIGRATIONS==="
CURRENT=$(git -C "$REPO_DIR" branch --show-current 2>/dev/null)
if [ -z "$ACTIVE" ]; then
  echo "[no active sibling branches]"
else
  for branch in $ACTIVE; do
    [ "$branch" = "origin/$BASE" ] && continue
    [ "$branch" = "origin/$CURRENT" ] && continue
    [ "$branch" = "$CURRENT" ] && continue
    files=$(git -C "$REPO_DIR" ls-tree -r --name-only "$branch" -- "$MIG_DIR/" 2>/dev/null | sort)
    if [ -n "$files" ]; then
      echo "BRANCH: $branch"
      echo "$files"
      echo "---"
    fi
  done
fi

echo "===END==="

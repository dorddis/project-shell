#!/bin/bash
# review/lib/conflicts/branch-context.sh
# Establish branch context: current branch, base, active sibling branches, open PRs.
#
# Usage:
#   branch-context.sh [--base staging] [--repo owner/name] [--repo-dir PATH]
# Backward-compatible shorthand:
#   branch-context.sh [base-branch]

set +e

BASE="staging"
GH_REPO=""
REPO_DIR=""

normalize_path() {
  local p="$1"
  [ -z "$p" ] && return
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$p" 2>/dev/null && return
  fi
  echo "$p"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2 ;;
    --repo|-R) GH_REPO="$2"; shift 2 ;;
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    --*) echo "Unknown arg: $1" >&2; exit 2 ;;
    *) BASE="$1"; shift ;;
  esac
done

REPO_DIR="$(normalize_path "$REPO_DIR")"
[ -z "$REPO_DIR" ] && REPO_DIR="$(normalize_path "$(git rev-parse --show-toplevel 2>/dev/null)")"
[ -z "$GH_REPO" ] && [ -n "$REPO_DIR" ] && GH_REPO=$(cd "$REPO_DIR" 2>/dev/null && gh repo view --json owner,name --jq '"\(.owner.login)/\(.name)"' 2>/dev/null)
GH_ARGS=()
[ -n "$GH_REPO" ] && GH_ARGS=(--repo "$GH_REPO")

echo "===CONTEXT==="
echo "repo: $GH_REPO"
echo "repo_dir: $REPO_DIR"

echo "===CURRENT_BRANCH==="
git -C "$REPO_DIR" branch --show-current 2>/dev/null

echo "===BASE==="
echo "origin/$BASE"

echo "===FETCH==="
git -C "$REPO_DIR" fetch origin --quiet 2>&1 || echo "[fetch failed; using local refs only]"

echo "===AHEAD_COUNT==="
git -C "$REPO_DIR" rev-list --count "origin/$BASE..HEAD" 2>/dev/null

echo "===ACTIVE_BRANCHES==="
git -C "$REPO_DIR" for-each-ref --sort=-committerdate \
  --format='%(refname:short) %(committerdate:relative)' \
  refs/remotes/origin/ 2>/dev/null | head -20

echo "===OPEN_PRS==="
if command -v gh >/dev/null 2>&1; then
  gh pr list "${GH_ARGS[@]}" --state open --json number,title,headRefName --limit 50 2>/dev/null \
    || echo "[]"
else
  echo "[gh CLI not available]"
fi

echo "===END==="

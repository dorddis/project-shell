#!/bin/bash
# review/lib/conflicts/surface-check.sh
# Extract env/secret references from the diff and list deployment-surface files.
#
# Usage:
#   surface-check.sh [--base staging] [--repo-dir PATH]
# Backward-compatible shorthand:
#   surface-check.sh [base-branch]

set +e

BASE="staging"
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
    --repo-dir) REPO_DIR="$2"; shift 2 ;;
    -h|--help) sed -n '2,12p' "$0"; exit 0 ;;
    --*) echo "Unknown arg: $1" >&2; exit 2 ;;
    *) BASE="$1"; shift ;;
  esac
done

REPO_DIR="$(normalize_path "$REPO_DIR")"
[ -z "$REPO_DIR" ] && REPO_DIR="$(normalize_path "$(git rev-parse --show-toplevel 2>/dev/null)")"

echo "===CONTEXT==="
echo "repo_dir: $REPO_DIR"
echo "base: $BASE"

echo "===NEW_KEYS_IN_DIFF==="
git -C "$REPO_DIR" diff "origin/$BASE...HEAD" 2>/dev/null | \
  grep -oE '(process\.env\.[A-Z_][A-Z0-9_]*|os\.environ\.get\(["\x27][A-Z_][A-Z0-9_]*["\x27]|os\.environ\[["\x27][A-Z_][A-Z0-9_]*["\x27]|os\.getenv\(["\x27][A-Z_][A-Z0-9_]*["\x27]|getEnv\(["\x27][A-Z_][A-Z0-9_]*["\x27]|FeatureFlag\.[A-Z_][A-Z0-9_]*|getSecret\(["\x27][A-Z_][A-Z0-9_]*["\x27])' | \
  sort -u

echo "===SURFACE_FILES==="
cd "$REPO_DIR" 2>/dev/null || true
for pattern in \
  '.env.example' \
  '.env.template' \
  '.env.sample' \
  'docker-compose.yml' \
  'docker-compose.*.yml' \
  'Dockerfile' \
  'Dockerfile.*' \
  '*.tf' \
  '*.tfvars' \
  'cdk.json' \
  '.github/workflows/*.yml' \
  '.github/workflows/*.yaml' \
  'k8s/*.yaml' \
  'k8s/*.yml' \
  'kubernetes/*.yaml' \
  '.gitlab-ci.yml' \
  'fly.toml' \
  'render.yaml' \
  'vercel.json'; do
  for f in $pattern; do
    [ -f "$f" ] && echo "$f"
  done
done | sort -u

echo "===END==="

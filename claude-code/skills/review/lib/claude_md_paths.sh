#!/usr/bin/env bash
# Phase 1 CLAUDE.md path collection for /review. Deterministic; replaces the Haiku helper.
# Output: deduped absolute paths of CLAUDE.md / CLAUDE.local.md relevant to the diff, one per line.
# Walks up from each changed file's dir to the repo root, plus the root file. Does not read contents.
set -euo pipefail

BASE="" REPO_DIR="" HEAD_REF="HEAD"
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2;;
    --repo-dir) REPO_DIR="$2"; shift 2;;
    --head) HEAD_REF="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
[ -n "$BASE" ] && [ -n "$REPO_DIR" ] || { echo "usage: claude_md_paths.sh --base <branch> --repo-dir <dir> [--head <ref>]" >&2; exit 2; }
cd "$REPO_DIR"
ROOT=$(git rev-parse --show-toplevel)

declare -A seen
emit() { local p="$1"; if [ -f "$p" ] && [ -z "${seen[$p]:-}" ]; then seen[$p]=1; echo "$p"; fi; }

emit "$ROOT/CLAUDE.md"
emit "$ROOT/CLAUDE.local.md"

while IFS= read -r f; do
  [ -n "$f" ] || continue
  d=$(dirname "$f")
  if [ "$d" = "." ]; then dir="$ROOT"; else dir="$ROOT/$d"; fi
  while :; do
    emit "$dir/CLAUDE.md"
    emit "$dir/CLAUDE.local.md"
    [ "$dir" = "$ROOT" ] && break
    parent=$(dirname "$dir")
    [ "$parent" = "$dir" ] && break
    dir="$parent"
  done
done < <(git diff --name-only "origin/$BASE...$HEAD_REF")

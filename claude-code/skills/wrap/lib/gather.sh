#!/bin/bash
# wrap/lib/gather.sh — fetch all wrap context. Read-only. Parallel-safe.
# No lock needed; multiple concurrent wraps can run this in parallel.
# Output: structured ===SECTION=== delimited blocks to stdout.
# Run from project repo root.

set +e   # tolerate sub-failures; always emit sections

echo "===META==="
echo "date: $(date -Iseconds)"
echo "branch: $(git branch --show-current 2>/dev/null)"
echo "head: $(git rev-parse --short HEAD 2>/dev/null)"
echo "cwd: $PWD"

echo "===GIT_STATUS==="
git status --short 2>/dev/null

echo "===PROJECT==="
# Project name from cwd (project root folder name). Skills can use this to
# gate project-specific behavior; default is "generic".
echo "${PWD##*/}"

echo "===STATUS_HEAD==="
# Universal: STATUS lives in .build/. Fall back to root for legacy/unmigrated repos.
if [ -f ".build/STATUS.md" ]; then
  head -60 .build/STATUS.md 2>/dev/null
else
  head -60 STATUS.md 2>/dev/null
fi

echo "===STATUS_SECTIONS==="
if [ -f ".build/STATUS.md" ]; then
  grep -n '^##\|^# ' .build/STATUS.md 2>/dev/null | head -30
else
  grep -n '^##\|^# ' STATUS.md 2>/dev/null | head -30
fi

echo "===PRS==="
# Auto-discover subrepos under code/. Falls back to current repo if no code/ dir.
if [ -d "code" ]; then
  for repo in code/*/; do
    repo="${repo%/}"
    if [ -d "$repo/.git" ] || [ -f "$repo/.git" ]; then
      echo "---$(basename "$repo")---"
      (cd "$repo" && gh pr list --state open --author @me --json number,title,headRefName 2>/dev/null) || echo "[]"
    fi
  done
else
  # Single-repo project — list PRs from current dir.
  echo "---$(basename "$PWD")---"
  gh pr list --state open --author @me --json number,title,headRefName 2>/dev/null || echo "[]"
fi

echo "===RECENT_SESSIONS==="
# Universal: sessions live in .build/cache/sessions/. Fall back to root sessions/ for legacy/unmigrated repos.
ls -t .build/cache/sessions/2*.md 2>/dev/null | head -3
ls -t sessions/2*.md 2>/dev/null | head -3

echo "===STANDUP_LATEST==="
LATEST_STANDUP=$(ls -t docs/standups/*.txt 2>/dev/null | head -1)
if [ -n "$LATEST_STANDUP" ]; then
  echo "file: $LATEST_STANDUP"
  cat "$LATEST_STANDUP"
fi

echo "===WRAP_COMMITS_24H==="
git log --since='24 hours ago' --grep='^wrap:' --oneline 2>/dev/null

echo "===SESSION_INDEX_HEAD==="
# Universal: index lives at .build/cache/sessions/SESSION_INDEX.md. Fall back to root variants for legacy.
head -8 .build/cache/sessions/SESSION_INDEX.md 2>/dev/null \
  || head -8 sessions/SESSION_INDEX.md 2>/dev/null \
  || head -8 SESSION_INDEX.md 2>/dev/null

echo "===END==="

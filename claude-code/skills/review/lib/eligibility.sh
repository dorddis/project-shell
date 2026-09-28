#!/usr/bin/env bash
# Phase 0 eligibility for /review. Deterministic; replaces the prior Haiku helper.
# Output: line 1 = verdict, line 2 = one-line reason. Verdicts:
#   PROCEED | SUGGEST_DOCS | SUGGEST_DEPS | SKIP_EMPTY | SKIP_TRIVIAL | SKIP_REVIEWED
# Note: detects whitespace-only as SKIP_TRIVIAL (ignore-all-space diff empty).
#   Comment-only diffs are NOT auto-classified (language-specific) -> conservative PROCEED.
set -euo pipefail

BASE="" REPO_DIR="" HEAD_REF="HEAD" REVIEWS_DIR="" SLUG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --base) BASE="$2"; shift 2;;
    --repo-dir) REPO_DIR="$2"; shift 2;;
    --head) HEAD_REF="$2"; shift 2;;
    --reviews-dir) REVIEWS_DIR="$2"; shift 2;;
    --slug) SLUG="$2"; shift 2;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done
[ -n "$BASE" ] && [ -n "$REPO_DIR" ] || { echo "usage: eligibility.sh --base <branch> --repo-dir <dir> [--head <ref>] [--reviews-dir <dir> --slug <slug>]" >&2; exit 2; }
cd "$REPO_DIR"
RANGE="origin/$BASE...$HEAD_REF"

# SKIP_REVIEWED: a master report for this slug that is BOTH fresh (<24h -- a freshness ceiling in case the
# base branch moved) AND pinned to the current HEAD. Age alone is NOT enough: a <24h report written against
# an OLDER head (the author pushed fix commits since) must NOT short-circuit review of the new code -- that
# false-skip silently passed unreviewed changes (BE#328/329, 2026-06-17). Require the report's head_sha
# frontmatter to prefix-match the live HEAD too. If head_sha is absent/unreadable, do NOT skip (conservative:
# re-review rather than risk a false skip). git short-sha minimum is 7 chars -> guard the prefix length.
if [ -n "$REVIEWS_DIR" ] && [ -n "$SLUG" ]; then
  latest=$(ls -d "$REVIEWS_DIR/$SLUG"/r*/ 2>/dev/null | sort -V | tail -1 || true)
  if [ -n "$latest" ] && [ -f "${latest}master-review.md" ]; then
    age=$(( $(date +%s) - $(date -r "${latest}master-review.md" +%s) ))
    if [ "$age" -lt 86400 ]; then
      cur=$(git rev-parse "$HEAD_REF" 2>/dev/null || true)
      rep=$(sed -nE 's/^[Hh]ead_sha:[[:space:]]*([^[:space:]]+).*/\1/p' "${latest}master-review.md" 2>/dev/null | head -1 | tr -d '\r' || true)
      n=${#rep}
      if [ -n "$cur" ] && [ "$n" -ge 7 ] && [ "${cur:0:$n}" = "$rep" ]; then
        echo "SKIP_REVIEWED"
        echo "master report ${latest}master-review.md is $((age/3600))h old and pinned to current HEAD ${rep}; re-synthesize or force re-run."
        exit 0
      fi
    fi
  fi
fi

mapfile -t FILES < <(git diff --name-only "$RANGE")
if [ "${#FILES[@]}" -eq 0 ]; then
  echo "SKIP_EMPTY"; echo "no files changed against origin/$BASE."; exit 0
fi

if [ -z "$(git diff --ignore-all-space "$RANGE" -- . ':(exclude)*.lock' ':(exclude)package-lock.json')" ]; then
  echo "SKIP_TRIVIAL"; echo "changes are whitespace-only (ignore-all-space diff is empty)."; exit 0
fi

docs=1 deps=1
for f in "${FILES[@]}"; do
  case "$f" in
    *.md|*.rst|*README*|*CHANGELOG*) ;;
    *) docs=0;;
  esac
  case "$f" in
    package.json|*/package.json|package-lock.json|*/package-lock.json|yarn.lock|*/yarn.lock|pnpm-lock.yaml|*/pnpm-lock.yaml|requirements.txt|*/requirements.txt|Cargo.toml|*/Cargo.toml|go.mod|*/go.mod|go.sum|*/go.sum|pyproject.toml|*/pyproject.toml) ;;
    *) deps=0;;
  esac
done
if [ "$docs" -eq 1 ]; then
  echo "SUGGEST_DOCS"; echo "only documentation files changed; suggest subset: build, quality."; exit 0
fi
if [ "$deps" -eq 1 ]; then
  echo "SUGGEST_DEPS"; echo "only dependency manifests changed; suggest subset: build, security, conflicts."; exit 0
fi
echo "PROCEED"; echo "${#FILES[@]} file(s) changed; review-worthy."

#!/bin/bash
# review-conflicts/surface-check.sh
# C4 deployment-surface drift: extract new env-var / secret references from the diff,
# then list which deployment-surface files exist in the repo.
# Caller cross-references each new key against each surface file.
# Read-only. Run from project repo root.
#
# Usage: bash surface-check.sh <base>
# Output: ===NEW_KEYS=== block + ===SURFACE_FILES=== block.

set +e

BASE="${1:-staging}"

echo "===NEW_KEYS_IN_DIFF==="
# Extract env-var / secret / feature-flag references introduced or changed in the diff.
# Captures common Node, Python, Go shapes. The caller compares against each surface file.
git diff "origin/$BASE...HEAD" 2>/dev/null | \
  grep -oE '(process\.env\.[A-Z_][A-Z0-9_]*|os\.environ\.get\(["\x27][A-Z_][A-Z0-9_]*["\x27]|os\.environ\[["\x27][A-Z_][A-Z0-9_]*["\x27]|os\.getenv\(["\x27][A-Z_][A-Z0-9_]*["\x27]|getEnv\(["\x27][A-Z_][A-Z0-9_]*["\x27]|FeatureFlag\.[A-Z_][A-Z0-9_]*|getSecret\(["\x27][A-Z_][A-Z0-9_]*["\x27])' | \
  sort -u

echo "===SURFACE_FILES==="
# List the deployment-surface files that exist. The caller checks each new key
# against each existing surface file.
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

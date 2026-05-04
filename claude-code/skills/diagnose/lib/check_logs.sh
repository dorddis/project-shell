#!/bin/bash
# diagnose/lib/check_logs.sh — generic local log scan for the diagnose skill.
# Read-only. Output: ===SECTION=== delimited blocks to stdout.
#
# Usage:
#   bash check_logs.sh [--since 1h] [--grep PATTERN] [--lines 200]
#
# This is the friend-tier generic scanner. It walks the cwd looking for *.log
# files and tails the last N lines from each. If your project has remote logs
# (CloudWatch, GCP Logging, Loki, etc.), extend this script with the relevant
# fetch logic per environment.

set +e

SINCE="1h"
LINES="200"
GREP_PATTERN=""

while [ $# -gt 0 ]; do
  case "$1" in
    --since) SINCE="$2"; shift 2 ;;
    --grep)  GREP_PATTERN="$2"; shift 2 ;;
    --lines) LINES="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0"; exit 0 ;;
    *)
      echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

echo "===META==="
echo "date: $(date -Iseconds)"
echo "since: $SINCE"
echo "lines: $LINES"
echo "grep: ${GREP_PATTERN:-<none>}"
echo "pwd: $PWD"

maybe_grep() {
  if [ -n "$GREP_PATTERN" ]; then
    grep -iE "$GREP_PATTERN"
  else
    cat
  fi
}

echo "===LOCAL:repo_logs==="
# Walk cwd up to depth 4 for *.log / *.err files, skipping common build dirs.
found=0
while IFS= read -r f; do
  [ -z "$f" ] && continue
  found=1
  echo "--- $f ---"
  tail -n "$LINES" "$f" 2>/dev/null | maybe_grep
done < <(find . -maxdepth 4 -type f \
          \( -name "*.log" -o -name "*.err" \) \
          -not -path "./node_modules/*" \
          -not -path "./.git/*" \
          -not -path "./.next/*" \
          -not -path "./dist/*" \
          -not -path "./build/*" \
          -not -path "./.venv/*" \
          -not -path "./venv/*" \
          2>/dev/null | head -10)
[ "$found" = "0" ] && echo "no .log files found under $PWD (depth 4)"

echo "===LOCAL:running_processes==="
(netstat -ano 2>/dev/null | grep -E "LISTEN.*:(8000|3000|8080)\b") || \
  (ss -ltnp 2>/dev/null | grep -E ":(8000|3000|8080)\b") || \
  echo "no port-listing tool available"

echo "===FRONTEND_NOTE==="
cat <<'EOF'
Frontend / browser-console errors cannot be fetched server-side. If the bug is
visible in the UI, capture: open devtools → Console → right-click → "Save as..."
→ paste the file path back into the diagnose symptom block.
EOF

echo "===END==="

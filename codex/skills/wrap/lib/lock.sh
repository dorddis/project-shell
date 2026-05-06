#!/bin/bash
# wrap/lib/lock.sh — write-phase semaphore for /wrap.
# Run from project repo root.
#
# Usage:
#   bash .claude/skills/wrap/lib/lock.sh acquire "<label>"
#   bash .claude/skills/wrap/lib/lock.sh refresh
#   bash .claude/skills/wrap/lib/lock.sh release
#
# Behavior:
#   - Atomic acquire via POSIX noclobber.
#   - Wait up to 300s in 10s polls before error (queueing). Matches stale window
#     so a slow-but-real sibling wrap is never aborted prematurely.
#   - Stale-detection at 5 min (mtime older than that → steal).
#   - 'refresh' touches lock mtime — call between long phases to extend the TTL.
#   - 'release' removes the lock file.

LOCKFILE=".wrap.lock"
ACTION="$1"
LABEL="${2:-wrap}"
STALE_SEC=${WRAP_STALE_SEC:-300}      # 5 min — orphaned-lock recovery window
WAIT_SEC=${WRAP_WAIT_SEC:-300}        # 5 min — queue timeout, must be >= STALE_SEC
POLL_SEC=10

mtime_of() {
  stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0
}

case "$ACTION" in
  acquire)
    # Idempotent gitignore
    touch .gitignore
    grep -qxF '.wrap.lock' .gitignore 2>/dev/null || echo '.wrap.lock' >> .gitignore

    WAITED=0
    while ! ( set -C; printf '%s | %s | pid=%d\n' "$(date -Iseconds)" "$LABEL" $$ > "$LOCKFILE" ) 2>/dev/null; do
      AGE=$(( $(date +%s) - $(mtime_of "$LOCKFILE") ))
      if [ "$AGE" -gt "$STALE_SEC" ]; then
        echo "Stale lock (${AGE}s old > ${STALE_SEC}s threshold) — stealing." >&2
        rm -f "$LOCKFILE"
        continue
      fi
      if [ "$WAITED" -ge "$WAIT_SEC" ]; then
        echo "Lock held >${WAIT_SEC}s without going stale. Try again in a moment." >&2
        echo "Holder: $(cat "$LOCKFILE" 2>/dev/null)" >&2
        exit 1
      fi
      echo "Held by: $(cat "$LOCKFILE" 2>/dev/null) (${AGE}s old). Waiting ${POLL_SEC}s (${WAITED}/${WAIT_SEC}s)..." >&2
      sleep "$POLL_SEC"
      WAITED=$((WAITED + POLL_SEC))
    done
    echo "Lock acquired: $LABEL"
    ;;

  refresh)
    if [ -f "$LOCKFILE" ]; then
      touch "$LOCKFILE"
      echo "Lock refreshed."
    else
      echo "Lock missing — cannot refresh." >&2
      exit 1
    fi
    ;;

  release)
    rm -f "$LOCKFILE" && echo "Lock released."
    ;;

  *)
    echo "Usage: lock.sh {acquire <label> | refresh | release}" >&2
    exit 2
    ;;
esac

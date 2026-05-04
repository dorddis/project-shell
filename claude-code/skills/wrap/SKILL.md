---
name: wrap
description: Wrap session - save context, update STATUS.md, create session log, capture open loops, commit changes
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
argument-hint: [session-name]
---

# Session Wrap-Up

Save all important context from this session. Session name: `$ARGUMENTS` (if empty, auto-detect 2-4 word kebab-case name from conversation).

This skill orchestrates 3 small shell scripts (in `~/.claude-personal/skills/wrap/lib/` — or the project-local override at `.claude/skills/wrap/lib/` if one exists) instead of inlining ~15 bash blocks. Lock guards only the WRITE phase — context fetching is read-only and parallel-safe, so concurrent wraps don't block each other on the gather step.

**Script path resolution:** prefer the project-local copy if present; otherwise fall back to the user-level copy:

```bash
# Resolve once at the top of each phase, reuse below.
WRAP_LIB=".claude/skills/wrap/lib"
[ -d "$WRAP_LIB" ] || WRAP_LIB="$HOME/.claude-personal/skills/wrap/lib"
```

## Phase 1 — Gather context (read-only, no lock)

Run **once**:

```bash
bash "$WRAP_LIB/gather.sh"
```

Output is `===SECTION===` delimited blocks: `META`, `GIT_STATUS`, `PROJECT`, `STATUS_HEAD`, `STATUS_SECTIONS`, `PRS`, `RECENT_SESSIONS`, `STANDUP_LATEST`, `WRAP_COMMITS_24H`, `SESSION_INDEX_HEAD`. Parse and analyze.

The `PROJECT` block is `<project>` if the <project> wrapper repo is detected, else `generic`. Use this to gate <project>-specific phases below.

This step is **safe to run before lock** — multiple concurrent wraps can all gather context in parallel without conflicting.

## Phase 2 — Analyze + plan (no bash)

From the gather output, decide:

- **Session name** if not provided — derive 2-4 word kebab-case from conversation.
- **Tags** for the session log (3-6 keywords from a consistent taxonomy already used in your project's session logs. Common axes: people, features/areas, topics like `security`/`performance`/`migration`/`architecture`, and actions like `bugfix`/`feature`/`refactor`/`research`/`review`. Pick stable values, reuse them, don't invent new ones per session).
- **STATUS.md updates needed.** Cross-reference STATUS.md sections (from `STATUS_SECTIONS` block) against `PRS` (truth) and `RECENT_SESSIONS`. Identify: stale rows to mark done, PR statuses that drifted, items missing from STATUS. (Skip if the project doesn't keep a STATUS.md — gather will return empty STATUS sections.)
- **Other context-file updates.** If you learned how something works → KNOWLEDGE.md. If commands/workflow/team info changed → CLAUDE.md. If repo gotchas → that repo's `CLAUDE.local.md`.
- **Open loops worth tracker tasks.** Filter to actionable items only (not vague notes, not already-tracked, not internal-only).
- **Session log Open Items** — every open loop, even those not tracker-tracked.

## Phase 3 — Acquire write-lock

```bash
bash "$WRAP_LIB/lock.sh" acquire "$SESSION_NAME"
```

- Waits up to 300s in 10s polls if another wrap holds the lock (matches the stale window so a slow-but-real sibling wrap is never aborted prematurely).
- Auto-steals if lock is >5 min old (stale).
- Exits 1 only if a real wrap holds it past the full 5-min queue timeout — STOP, try again later. Do NOT proceed to Phase 4.

## Phase 4 — Write all changes (no bash)

In this order, using `Read` / `Edit` / `Write`:

### 4.1 — Update STATUS.md (MANDATORY if STATUS.md exists)

The most important wrap step. STATUS.md is read first next session — stale = blind start.

**Path resolution (universal):**

| Doc | Universal path |
|---------|-------------|
| STATUS.md | `.build/STATUS.md` |
| KNOWLEDGE.md | `.build/KNOWLEDGE.md` |

ALL projects route STATUS.md and KNOWLEDGE.md to `.build/` regardless of collaborator status — personalization scrubbing default. The project CLAUDE.md (which stays at root) references these via relative path `.build/STATUS.md` etc. so future sessions can find them.

**Legacy fallback:** if `.build/STATUS.md` does not exist but `STATUS.md` exists at root, the project hasn't been migrated yet — read root `STATUS.md` and write back to root for that wrap. Don't spontaneously migrate; that's a deliberate one-time operation.

Apply the gap analysis from Phase 2:
- Mark completed tasks, add PR numbers, mark merges.
- Verify Open PRs against the `PRS` block from gather (GitHub is source of truth).
- Fix stale Known Issues / Carried Forward / Blockers.
- Never delete active rows — only mark truly done items.
- For tooling-only sessions (no dev), append a short "## <date> EOD — <topic>" section at the end of recent activity. Don't try to refresh end-to-end if scope is narrow.

If the project has no STATUS.md (in any location), skip 4.1. If it uses a different living doc (e.g. `LIFE_CONTEXT.md`, `INBOX.md`), update that instead and note the substitution in your final report.

### 4.2 — Update other context files

Only if relevant:
- KNOWLEDGE.md — new architecture/infra/product knowledge
- CLAUDE.md — workflow rule changes
- `code/<repo>/CLAUDE.local.md` — repo-specific gotchas (<project> wrapper-repo layout)

Add alongside existing items, don't replace sections.

### 4.3 — Create session log

**Path resolution by project (mirrors `/meeting` skill convention):**

| Project | Session log path |
|---------|------------------|
| _(all projects, universal)_ | `.build/cache/sessions/[DATE]_[session-name].md` |

**Universal `.build/cache/sessions/` rule (matches `/meeting` skill):** ALL projects route session logs to `.build/cache/sessions/` regardless of collaborator status. This is the personalization scrubbing default — session logs are personal Sid-state (decisions, what-I-did journals, off-the-cuff thinking) that shouldn't pollute a tracked repo even when solo. SESSION_INDEX.md lives alongside in `.build/cache/sessions/SESSION_INDEX.md`.

**Exception:** `vyapari` (nested inside `ai-sales-agent`) never gets its own `.build/`. Vyapari-related session logs land in the parent `ai-sales-agent`'s `.build/cache/sessions/`.

Frontmatter:

```yaml
---
wrap_id: [DATE]_[session-name]
date: [DATE]
tags: [3-6 keywords]
summary: One-line summary (max 100 chars)
status: closed
---
```

Body: `# Session: [name]` heading + `**Wrap ID:**` + `**Commit:** [fill after git commit]` + sections: `## Summary` (2-3 sentences), `## Key Decisions`, `## Changes Made`, `## Open Items`.

If the project has no `sessions/` directory yet, create it.

### 4.4 — Update SESSION_INDEX.md (if it exists)

Add a new row at the **top** of the Quick Lookup table:

```
| YYYY-MM-DD | [`YYYY-MM-DD_session-name`](YYYY-MM-DD_session-name.md) | <summary> | closed | <tags> |
```

Increment `**Total sessions:**` count and update `**Last updated:**` date. Skip if the project doesn't maintain an index.

## Phase 5 — Commit + release lock

```bash
bash "$WRAP_LIB/commit.sh" "$SESSION_NAME" "<short summary>"
bash "$WRAP_LIB/lock.sh" release
```

`commit.sh` does: `git add -A`, commit, patch the session log's `**Commit:**` line with the new SHA, amend. Released even if commit fails (run lock.sh release unconditionally — failed commits should not orphan the lock).

## Phase 6 — Confirm

**Gate (only when STATUS.md exists):** STATUS.md must be in the diff:

```bash
if [ -f STATUS.md ]; then
  git diff-tree --no-commit-id --name-only -r HEAD | grep -q '^STATUS\.md$' && echo "STATUS gate PASS" || echo "STATUS gate FAIL — go back to Phase 4.1"
fi
```

Then report to user:
- STATUS.md changes (what was updated — lead with this; or note "no STATUS.md in this project")
- Other files updated
- Session log path
- Final commit hash
- Open items for next session

## Rules

1. Read before editing — never overwrite blindly.
2. Preserve existing file structure — work within headings.
3. Be concise — bullets over prose.
4. Session logs are append-only — never modify past sessions.
5. Cross-reference, don't duplicate.
6. No AI co-author lines (attribution disabled in settings).
7. **Do NOT inline bash scripts that already exist in `lib/`.** Call the script.
8. **Lock guards Phase 4-5 only.** Phase 1 (gather) and Phase 2 (analyze) are safe to run without the lock.

## Library scripts (`lib/`)

- `gather.sh` — context fetch (PRs, STATUS, sessions, standups, recent wraps). Read-only. Project-aware (sets `PROJECT=<project>|generic`).
- `lock.sh acquire <label>` / `refresh` / `release` — write-phase semaphore. 300s queue, 5-min stale recovery, PID written for honest detection.
- `commit.sh <session-name> [message]` — git add -A + commit + hash-patch session log + amend.

If a script fails or behaves unexpectedly, debug it directly: `bash "$WRAP_LIB/<script>.sh" ...`. Don't reimplement inline in this skill body.

# Session Wrap-Up

Save all important context from this session. Works with any AI coding tool.

**Claude Code setup:** Copy to `~/.claude/commands/wrap.md` (global) or `.claude/commands/wrap.md` (project-specific). Invoke: `/wrap [session-name]`.

**Cursor setup:** Save as `.github/prompts/wrap.prompt.md`. Invoke: `/wrap` in chat.

**Other tools:** Paste everything below "# Instructions" as a prompt at end of session.

---

# Instructions

Save all important context from this session. Session name: `$ARGUMENTS` (if empty, auto-detect 2-4 word kebab-case name from conversation). Date: $DATE

## Phase 1: Analyze (DO NOT WRITE YET)

### 1. Session Setup & Scan

**Session name:** Use provided name or derive from conversation (kebab-case). Path: `sessions/[DATE]_[session-name].md`. Check if file exists -- append `-2` if collision.

**Repo ownership:** Run `git remote -v`.
- Remote is your own repo -> sessions commit+push normally
- Remote is a client/org repo -> add `sessions/` to `.gitignore`, sessions stay local-only
- No remote -> safe to commit locally

**Scan conversation for:** decisions made, tasks completed, new blockers, open items (TODOs, "need to" statements, unfinished work, deferred items, unanswered questions, next steps not yet tracked).

**Gap analysis (truth-sourced):** In parallel: read STATUS.md (full doc), run `gh pr list --state open --json number,title` on relevant repos, read the latest standup file and last 2 session logs. Cross-reference STATUS.md against these sources -- PRs listed as open that GitHub says are merged, bugs listed as open that sessions say are fixed, naming that changed, decisions from conversations not tracked. Fix all stale items during Step 3.

## Phase 2: Execute

### 3. Update STATUS.md (MANDATORY - DO NOT SKIP)

**Most important wrap step.** STATUS.md is the first thing read next session -- stale = blind start.

Using the gap analysis results from Step 1, update the entire doc:
- `Last Updated` date with parenthetical summary
- Mark completed tasks, add PR numbers, mark merges
- Verify Open PRs table matches `gh pr list` output
- Fix stale items in Known Issues / Carried Forward / Blockers that were resolved but never updated
- Add new blockers, status changes, decisions from this session
- Never delete active rows -- only mark truly done items

### 4. Update Other Context Files

Never delete active rows. Add alongside existing items, don't replace sections.

Answer each question -- if yes, read the file and make the edit:
- **Did you learn how something works (architecture, infra, product)?** -> Update KNOWLEDGE.md
- **Did commands, workflow rules, or team info change?** -> Update CLAUDE.md / AGENTS.md
- **Did you discover key files, gotchas, or patterns in a repo?** -> Update that repo's context file (CLAUDE.local.md or equivalent)
- **Did a parent context file reference this project?** -> Propagate status changes upward (milestones, phase changes, blockers -- NOT implementation details)

### 5. Update Standup File

Ensure `docs/standups/[NEXT_BUSINESS_DAY].txt` is up to date with everything done this session:
- PRs merged or created
- Migrations run
- Blockers resolved or found
- Decisions made
- Milestones reached

Working Monday -> file for Tuesday. Working Friday -> file for Monday.

### 6. Create Session Log

Path: `sessions/[DATE]_[session-name].md`

```markdown
---
wrap_id: [DATE]_[session-name]
date: [DATE]
project: [project-folder-name]
tags: [3-6 searchable keywords]
summary: One-line summary (max 100 chars)
status: closed
related: []
---

# Session: [session-name]
**Wrap ID:** `[DATE]_[session-name]`
**Commit:** [fill after git commit]

## Summary
[2-3 sentences of what was accomplished]

## Key Decisions
- [decisions made this session]

## Changes Made
- [file/area]: [what changed and why]

## Open Items
- [unresolved items, next steps, things to follow up on]
```

**Tags (use consistently):**
- People: `[teammate-names]`
- Features: `[feature-names]`
- Topics: `security`, `performance`, `migration`, `architecture`, `infrastructure`, `design`
- Actions: `bugfix`, `feature`, `refactor`, `research`, `review`, `planning`, `decision`

### 7. Update SESSION_INDEX.md

Add new row at TOP of the Quick Lookup table. Increment total session count, update date. Add to relevant By Tag sections.

### 8. Capture Open Loops

From the open items identified in Phase 1:
1. Filter to **actionable items only** -- skip vague notes, completed items, things already tracked
2. Ensure they're captured in STATUS.md under the right section (blockers, upcoming, open items)
3. If using a task manager (Todoist, Linear, Jira, ClickUp), create tasks there too
4. If no open loops exist, note "No open loops" and move on

### 9. Git Commits (Code first, then Wrap)

**Code commit (if code files changed):**
Stage code files explicitly (NOT `git add -A`). Use Conventional Commits: `type(scope): description`

```bash
git add [code files]
git commit -m "<type>(<scope>): <description>

- [file1] - [what and why]
- [file2] - [what and why]"
```

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `build`

Multiple logical changes -> split into multiple commits. No code changes -> skip this step.

**Wrap commit (session log + context files):**
```bash
git add -A && git commit -m "wrap: [DATE]_[session-name] - [summary]" && HASH=$(git rev-parse --short HEAD) && sed -i "s/\*\*Commit:\*\* .*/\*\*Commit:\*\* $HASH/" sessions/[DATE]_[session-name].md && git add sessions/ && git commit --amend --no-edit
```

### 10. Confirm

**Gate:** Run `git diff --name-only` -- if STATUS.md is NOT in the diff, go back and update it now.

Report:
- **STATUS.md changes** (what was updated -- goes first, most important)
- Other files updated
- Session log path
- Git commit hash(es)
- Open items for next session

## Rules

1. Read before editing -- never overwrite blindly
2. Preserve existing file structure -- work within headings
3. Be concise -- bullets over prose
4. Session logs are append-only -- never modify past sessions
5. Cross-reference, don't duplicate
6. STATUS.md MUST be updated every wrap -- no exceptions

---
name: 'wrap'
description: 'End-of-session wrap-up: update STATUS.md, create session log, commit context'
---

Save all important context from this session.

## Step 1: Analyze

Auto-detect a 2-4 word kebab-case session name from the conversation (e.g., "auth-refactor", "api-cleanup").

Scan the conversation for: decisions made, tasks completed, new blockers, open items, deferred work, next steps.

**Gap analysis:** Read STATUS.md fully. Run `gh pr list --state open` on relevant repos. Cross-reference -- find stale items (PRs listed as open but merged, bugs listed as open but fixed). Fix during Step 2.

## Step 2: Update STATUS.md (MANDATORY)

Most important step. STATUS.md is the first thing read next session.

- Update `Last Updated` date with parenthetical summary
- Mark completed tasks, add PR numbers
- Verify Open PRs table matches `gh pr list` output
- Fix stale items found in gap analysis
- Add new blockers, decisions, status changes
- NEVER delete active rows -- only mark truly done items

Answer each and update if yes:
- **Did you learn how something works?** -> Update KNOWLEDGE.md
- **Did workflow rules or team info change?** -> Update AGENTS.md

## Step 3: Create Session Log

Create `sessions/[DATE]_[session-name].md`:

```markdown
---
wrap_id: [DATE]_[session-name]
date: [DATE]
project: [project-name]
tags: [3-6 searchable keywords]
summary: One-line summary (max 100 chars)
status: closed
related: []
---

# Session: [session-name]
**Commit:** [fill after git commit]

## Summary
[2-3 sentences]

## Key Decisions
- [decisions]

## Changes Made
- [file/area]: [what and why]

## Open Items
- [unresolved items, next steps]
```

## Step 4: Update SESSION_INDEX.md

Add new row at TOP of Quick Lookup table. Increment count.

## Step 5: Update Standup File

Append standup-worthy items to `docs/standups/[NEXT_BUSINESS_DAY].txt`.

## Step 6: Git Commit

Code commit first (if code changed), then wrap commit:
```bash
git add -A
git commit -m "wrap: [DATE]_[session-name] - [summary]"
```

Backfill commit hash into session log, amend.

**Gate:** If STATUS.md is NOT in the diff, go back and update it.

Report: STATUS.md changes (first), session log path, commit hash, open items.

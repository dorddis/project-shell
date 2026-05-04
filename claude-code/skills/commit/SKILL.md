---
name: commit
description: >
  Stage and commit changes with a clean message. Runs project lint/typecheck if available, never auto-runs review agents.
  TRIGGER when: user says "/commit", "commit this", "commit changes", "commit properly".
  DO NOT TRIGGER automatically - only on explicit user request.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob
argument-hint: [message]
---

# Commit Workflow

Pure commit helper. Detects project conventions, runs lint/typecheck if configured, stages safely, commits with a clean message. **Does NOT run review agents** — that's `/review`'s job. If you want review-grade scrutiny on this diff, run `/review` first, fix what it flags, then run `/commit`.

## Phase 1: Detect Context

Read `CLAUDE.md` and `CLAUDE.local.md` in the repo (if present) to learn:
- Project stack (language, framework)
- Lint command (e.g., `npm run lint`, `ruff check`, `eslint .`)
- Typecheck command (e.g., `tsc --noEmit`, `mypy .`)
- Test command (do NOT run tests in /commit — too slow; mention if user should run them separately)
- Any project-specific commit conventions

If no CLAUDE.md exists, infer from `package.json` scripts / `pyproject.toml` / `Makefile`.

## Phase 2: Gather Diff

```bash
git status
git diff HEAD --stat
git diff HEAD
git branch --show-current
git log --oneline -10
```

If no changes detected, tell the user and stop.

If unstaged + staged changes are mixed, show both and ask which to commit. Don't assume.

## Phase 3: Lint + Typecheck (if commands exist)

Only if Phase 1 surfaced lint and/or typecheck commands:

```bash
<lint command>
<typecheck command>
```

Run them sequentially in the affected repo (use the right CWD if the project has multiple repos under it).

**If either fails:**
- Report the failure with the exact error output.
- Stop. Do not commit a broken-lint state.
- The user fixes, then re-runs `/commit`.

**If both pass (or no commands configured):**
- Note "lint: pass | typecheck: pass" or "lint/typecheck: not configured" in the commit prep summary.
- Continue.

## Phase 4: Stage Files (safety filters)

**Identify files to stage from the diff. Exclude:**
- `.env*` files (except `.env.example`)
- `CLAUDE.local.md` (explicitly says "DO NOT commit")
- `.claude/` directory
- `node_modules/`, `__pycache__/`, `.venv/`, `dist/`, `.next/`, `build/`
- Any file whose name contains `secret`, `key`, `token`, `credential`, `private` (warn user before excluding — could be a false positive)
- Any file >5MB without explicit user confirmation (binary blobs)

**Stage specific files** (NEVER `git add -A` or `git add .`):

```bash
git add <file1> <file2> ...
```

If the diff includes excluded files, list them in the prep summary so the user knows they were skipped.

## Phase 5: Generate Commit Message

**If `$ARGUMENTS` is provided** (and isn't a flag), use it verbatim as the message.

**Otherwise, generate a clean message.** Format:

```
type: imperative description
```

- **Type:** `feat`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`, `perf`, `build`, `ci`
- **Description:** under 72 chars, imperative mood ("add X" not "added X")
- **Body** (optional, only if non-trivial change): 2-3 lines explaining *why*, not *what*. Wrap at 72 chars.

**Hard rules:**
- NO `Co-authored-by: Claude` lines
- NO emoji
- NO "Generated with Claude Code" footer
- NO marketing language ("comprehensively", "robustly", "elegantly")

Show the proposed message to the user and ask for approval (unless `$ARGUMENTS` was provided — then commit directly).

## Phase 6: Pre-commit Summary

Before committing, print a one-block summary:

```
Branch: <branch>
Files staged: <N>
  + <file1>
  + <file2>
  ...
Files skipped (excluded): <list, if any>
Lint: pass | fail | not configured
Typecheck: pass | fail | not configured
Message: <proposed message>

Note: /commit does NOT run review agents. If this diff needs review-grade scrutiny, abort and run /review first.
```

Wait for user confirmation: **proceed / amend message / cancel**.

## Phase 7: Commit + Verify

Use HEREDOC for the message to handle special characters cleanly:

```bash
git commit -m "$(cat <<'EOF'
type: description

optional body line 1
optional body line 2
EOF
)"
```

Then verify:

```bash
git log --oneline -3
git status
```

Report the commit SHA + branch state to the user.

## Edge Cases

- **Pre-commit hook fails:** Do NOT use `--no-verify`. Report the hook error and stop. User fixes the underlying issue and re-runs.
- **gh CLI not available:** No effect — `/commit` does not use gh.
- **Detached HEAD:** Warn the user. Commit anyway if they confirm, but flag that the commit may be lost on next checkout.
- **Committing to `main` / `staging` / `production` directly:** Warn explicitly. Ask "Are you sure? Most workflows commit to a feature branch and PR into main." Proceed only on explicit confirmation.
- **Large diff (>2000 lines):** Suggest splitting into smaller commits. Proceed if user insists.

## What This Skill Must Refuse

- **Auto-running review agents** — that's `/review`'s job. `/commit` only runs lint + typecheck, which are deterministic project tooling, not LLM review.
- **Skipping hooks via `--no-verify`** — never. The hooks exist for a reason.
- **Bypassing the staging filter** — never `git add -A` or `git add .`. Explicit file list only.
- **Committing without user approval of the message** (unless `$ARGUMENTS` was provided as the message).
- **Pushing or opening a PR** — `/commit` ends at the local commit. Push is a separate explicit user action.

## Relationship to /review

- `/commit` = commit helper. Lint, stage, commit. Fast. No agent dispatches.
- `/review` = pre-PR audit. 6 specialist agents in parallel. Slow. Read-only — does not commit.

**Sequence:** `/review` first → fix flagged items → `/commit` → push.

If you find yourself wishing `/commit` did review for you, stop and run `/review`. Don't try to make `/commit` do both jobs — that's the architecture this rewrite explicitly removed.

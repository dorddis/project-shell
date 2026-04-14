---
name: 'commit'
description: 'Stage, build-verify, and commit changes with a clean conventional commit message'
---

## 1. Pre-commit Review

Run `git diff --staged` (or `git diff` if nothing staged yet).

Check for:
- Hardcoded secrets, API keys, tokens, .env references
- Debug statements (`print()`, `console.log()`, `debugger`)
- TODO/FIXME comments in new code
- Unintended files (binaries, IDE configs, .env)

## 2. Build Verification (MANDATORY)

Run the project's build/lint/type-check:

**TypeScript/Next.js:** `npm run build`
**Python:** `python -m pytest -v` (if tests exist)
**Other:** Find and run the build command from package.json, Makefile, or CI config.

If build FAILS: stop, list every error with file:line and suggested fix. Do NOT proceed.

## 3. Stage and Commit

Stage only relevant files -- never `git add .` or `git add -A`.

Write a Conventional Commit message:

```
<type>(<scope>): <description>

- file1 path - what was done and why
- file2 path - what was done and why
```

**Types:** feat, fix, refactor, perf, test, docs, chore, build
**Scope:** component/module name (e.g., auth, api, dashboard)

Rules:
- Imperative mood, lowercase, no period
- Under 72 chars for subject line
- Multiple logical changes -> split into multiple commits

## 4. Verify

Run `git log --oneline -3` to confirm.

Remind: push with `git push origin <branch>` when ready.

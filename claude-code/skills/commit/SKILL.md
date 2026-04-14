---
name: commit
description: Stage, review, and commit changes with a clean message. Runs build verification before committing. TRIGGER when: user says "/commit", "commit this", "commit changes". DO NOT TRIGGER automatically - only on explicit user request.
---

## Commit Workflow

### 1. Detect Context
Determine which repo/area you're working in by checking the changed files and project structure.

### 2. Pre-commit Review
- Run `git diff --staged` to see what's being committed
- Check for:
  - Hardcoded secrets, .env references, API keys, tokens
  - Debug statements (`print()`, `console.log()`, `debugger`)
  - TODO/FIXME comments in new code
  - Unnecessary `any` types (TypeScript)
  - Unintended files (binary files, IDE configs, .env files)
- Verify changes match the intended scope (no unrelated files)

### 3. Code Quality Check
- Read any CLAUDE.md, CLAUDE.local.md, or AGENTS.md in the repo for project conventions
- Check new code against existing patterns in the same directory
- Verify imports, naming, and structure follow project style

### 4. Build Verification (MANDATORY -- do NOT skip)

This is the #1 gate. If the build fails, nothing else matters.

Run the appropriate build/lint/type-check commands for the project stack:

**TypeScript/Next.js:**
```bash
npm run build          # Full production build (ESLint + TypeScript + bundling)
```
If build fails, isolate the cause:
```bash
npx next lint          # ESLint only
npx tsc --noEmit       # TypeScript type-check only
```

**Python:**
```bash
python -m py_compile main.py    # Syntax check
python -m pytest -v             # Run tests if they exist
```

**Other stacks:** Identify and run the project's build commands from package.json, Makefile, or CI config.

**Report results to the user.** If build fails, STOP. Fix the errors first. Do NOT proceed to commit.

### 5. Stage and Commit
- Stage only relevant files (never `git add .` or `git add -A`)
- Write a concise commit message using Conventional Commits:

```
<type>(<scope>): <description>

- file1 path - what was done and why
- file2 path - what was done and why
```

**Types:** `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `build`
**Scope:** Component or module name (e.g., `auth`, `api`, `dashboard`)

Rules:
- Imperative mood, lowercase, no period
- Under 72 chars for the subject line
- Body: per-file descriptions with WHAT and WHY
- Multiple logical changes -> split into multiple commits

### 6. Post-commit
- Run `git log --oneline -3` to verify
- Remind: push with `git push origin <branch-name>` when ready
- Remind: run `/review` before creating a PR

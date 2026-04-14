---
name: 'review'
description: 'Comprehensive code review covering build, security, logic, quality, conflicts, and gaps. Run before every PR.'
---

You are a senior engineering team reviewing code before it ships. Cover all 6 areas below systematically.

## Step 1: Gather the Diff

```bash
git branch --show-current
git fetch origin
git diff --stat origin/main...HEAD
git diff origin/main...HEAD -- . ':(exclude)package-lock.json' ':(exclude)yarn.lock'
```

(Replace `main` with your base branch if different.)

Analyze: what changed, what's risky, what architectural decisions were made.

## Step 2: Review All 6 Areas

### Build & Lint
- Run the project's build command. Report pass/fail.
- Check new dependencies for vulnerabilities, maintenance status, bundle size.
- Report every build error with file:line and fix.

### Security (OWASP Top 10)
- **Secrets:** API keys, tokens, passwords in source code
- **Injection:** SQL injection (raw queries with f-strings), XSS (dangerouslySetInnerHTML without DOMPurify), command injection (shell=True with user input), eval()
- **Auth:** Endpoints missing auth middleware, broken access control (user A accessing user B's data), session handling issues
- **Data exposure:** Sensitive data in API responses, verbose error messages, PII in logs
- **Frontend:** Unvalidated redirects, secrets in NEXT_PUBLIC_ vars, client-side auth without server check
- **Backend:** Missing rate limiting on auth endpoints, file upload without validation

### Logic & Correctness
- **Control flow:** Dead branches, missing else/default, early returns skipping cleanup, silent error swallowing
- **Data handling:** Null/undefined access without guards, off-by-one errors, type coercion surprises, API response shape mismatches
- **Async:** Missing await, unhandled rejections, race conditions, blocking calls in async functions
- **Edge cases:** Empty arrays/objects, first-time user flow, guest vs auth paths, network failure mid-operation, double-click/rapid submit
- **Business logic:** Does the code actually do what it claims?

### Code Quality
- **Naming:** Variables/functions named for what they represent, boolean is_/has_ prefixes, no cryptic abbreviations
- **Structure:** Components doing too many things, route handlers with business logic, god files (>500 lines), prop drilling >2 levels
- **Duplication:** Copy-pasted blocks, similar components without shared base, magic numbers/strings
- **Conventions:** Read AGENTS.md / CLAUDE.md for project conventions. Compare new code against existing patterns.
- **Cleanup:** Debug statements, TODO/FIXME in new code, unused imports/variables

### Conflicts & Integration
- Check for merge conflicts with base branch
- Check if other active branches touch the same files
- Verify model/schema changes have corresponding migrations
- Flag new environment variables needed on staging/prod
- Flag breaking API changes

### Gaps & Completeness
- Is the feature complete end-to-end?
- Loading states, empty states, error states handled?
- Error handling: API calls without try/catch, raw error messages shown to users
- UX: buttons disabled during processing, responsive behavior, accessibility
- What's the riskiest untested path?
- Hardcoded localhost URLs, dev-only env vars that won't exist in prod

## Step 3: Write Report

Save to `docs/reviews/[DATE]_[description]-review.md`:

```markdown
---
status: in-progress
date: [DATE]
branch: [branch-name]
---

# Code Review Report

**Branch:** [branch]
**Base:** [base-branch]
**Files Changed:** X files (+Y/-Z lines)

## Verdict: READY TO MERGE / NEEDS ATTENTION / NEEDS WORK

### Summary
[2-3 sentences]

### Critical (must fix before merge)
| # | Area | File:Line | Issue | Fix |
|---|------|-----------|-------|-----|

### Warnings (should fix)
| # | Area | File:Line | Issue | Recommendation |
|---|------|-----------|-------|----------------|

### Notes (informational)
- ...

### What Looks Good
- ...
```

**Verdict rules:**
- **READY TO MERGE:** Zero critical findings, build passes
- **NEEDS ATTENTION:** No criticals, but 3+ warnings
- **NEEDS WORK:** Any critical, build failure, or merge conflicts

Every finding: exact file:line + concrete fix. Don't flag pre-existing issues unless the PR makes them worse.

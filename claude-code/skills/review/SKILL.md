---
name: review
description: Comprehensive multi-agent code review. Launches 6 parallel review agents (build, security, logic, quality, conflicts, gaps) like a senior dev team. Use before every PR push.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent
---

## Multi-Agent Code Review

You are the review orchestrator. You analyze the diff, plan a targeted review, then dispatch 6 specialist agents in parallel.

**CRITICAL TOOL CONSTRAINT: You MUST use the `Agent` tool to launch review agents. NEVER use TaskCreate, TaskGet, TaskOutput, or any Task-prefixed tools.**

### Step 1: Gather and Analyze

Determine the base branch (usually `main` or `staging`), then run:
```bash
git branch --show-current
BASE=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||' || echo "main")
git fetch origin $BASE --quiet
git diff --stat origin/$BASE...HEAD
git diff origin/$BASE...HEAD -- . ':(exclude)package-lock.json' ':(exclude)yarn.lock'
```

Then **analyze the diff yourself** before launching agents. Identify:
- **What repos changed** (frontend, backend, or both)
- **Categories of change**: new files, deleted files, refactors, dependency additions, security-relevant changes (auth, cookies, tokens, dangerouslySetInnerHTML, env vars), API changes, DB/migration changes
- **Risk areas**: which files are most complex or most likely to have bugs
- **Key decisions the author made**: architectural choices visible in the diff

Write a short **diff briefing** (5-10 bullets) summarizing what this PR does and what's risky. You will tailor each agent's scope from this briefing.

### Step 1.5: Determine Output Location

Generate an output file path for each agent based on context:

**Naming convention:** `docs/reviews/YYYY-MM-DD_<slug>-<agent>.md`

**Slug logic (pick first match):**
1. If reviewing a PR: `pr<NUMBER>-<short-description>` (e.g., `pr144-unsubscribe`)
2. If on a feature branch: branch name slugified (e.g., `feature/siddharth-rate-limiting` -> `rate-limiting`)
3. Fallback: first 3-4 words from your diff briefing summary (e.g., `auth-cookie-cleanup`)

**Agent suffixes:** `-build`, `-security`, `-logic`, `-quality`, `-conflicts`, `-gaps`

**Example:** For PR #144 on 2026-03-24:
```
docs/reviews/2026-03-24_pr144-unsubscribe-build.md
docs/reviews/2026-03-24_pr144-unsubscribe-security.md
docs/reviews/2026-03-24_pr144-unsubscribe-logic.md
docs/reviews/2026-03-24_pr144-unsubscribe-quality.md
docs/reviews/2026-03-24_pr144-unsubscribe-conflicts.md
docs/reviews/2026-03-24_pr144-unsubscribe-gaps.md
```

Also generate a **master report path:** `docs/reviews/YYYY-MM-DD_<slug>-master-review.md`

Tell the user the output paths before launching agents.

### Step 2: Launch All 6 Agents in Parallel

**MANDATORY: All 6 `Agent` tool calls in a SINGLE message.**

Each agent is launched using its dedicated `subagent_type` (custom agent definitions in the user's global `agents/` directory override the built-in ones, giving them Write access and tailored instructions).

Each agent gets:
1. Your **tailored briefing** for that agent's specialty (the agent already has its review instructions from its definition file)
2. The scope context (branch, files, working directory)
3. An `OUTPUT_FILE` path where it must write its report

**Agent prompt template:**

```
## Output File
**CRITICAL: You MUST write your full report to this file using the Write tool:**
OUTPUT_FILE: <absolute-path-to-output-file>

Write the report EVEN IF you find no issues (write a clean PASS report).

## Scope
- **Branch:** <branch>
- **Base:** origin/$BASE
- **Working directory:** <absolute path to the project root>
- **Repo with changes:** <absolute path to the changed repo>
- **Changed files:** <file list>

## Orchestrator Briefing
<Your analysis tailored to THIS agent's specialty>

## How to get the diff
Run: git diff origin/$BASE...HEAD -- . ':(exclude)package-lock.json' ':(exclude)yarn.lock'
From directory: <repo path>

## Project Context
Read any CLAUDE.md or CLAUDE.local.md files in the repo for project-specific conventions, stack details, and known issues.

This is a RESEARCH + REPORT task. Do NOT modify any source code. Only write to the OUTPUT_FILE.
```

**The briefing is the key.** Don't give every agent the same generic context. Tell the build agent about deps and build-relevant changes. Tell the security agent about auth/XSS/injection-relevant changes. Tell the logic agent about the tricky type changes and edge cases YOU spotted. Each agent should feel like they got a handoff from a tech lead who already read the code.

**Agent configuration:**

| Agent | subagent_type | description | model |
|-------|---------------|-------------|-------|
| Build | review-build | Build review | opus |
| Security | review-security | Security review | opus |
| Logic | review-logic | Logic review | opus |
| Quality | review-quality | Quality review | opus |
| Conflicts | review-conflicts | Conflicts review | opus |
| Gaps | review-gaps | Gaps review | opus |

### Step 3: Synthesize Results

After all 6 agents complete, **read all 6 output files** from `docs/reviews/` to collect their reports.

Create a unified master report and **write it to the master report path:**

```
---
status: in-progress
agents: [build, security, logic, quality, conflicts, gaps]
branch: <branch-name>
date: YYYY-MM-DD
---

# Code Review Report

**Branch:** <branch-name>
**Base:** staging
**Files Changed:** X files (+Y/-Z lines)
**Date:** YYYY-MM-DD

## Verdict: READY TO MERGE / NEEDS ATTENTION / NEEDS WORK

### Summary
<2-3 sentence overview>

### Critical (must fix before merge)
| # | Agent | File:Line | Issue | Fix |
|---|-------|-----------|-------|-----|

### Warnings (should fix)
| # | Agent | File:Line | Issue | Recommendation |
|---|-------|-----------|-------|----------------|

### Notes (informational)
- ...

### Agent Results
| Agent | Verdict | Critical | Warnings | Notes | Report |
|-------|---------|----------|----------|-------|--------|
| Build | PASS/FAIL | 0 | 0 | 0 | [link](filename) |
| Security | PASS/FAIL | 0 | 0 | 0 | [link](filename) |
| Logic | PASS/FAIL | 0 | 0 | 0 | [link](filename) |
| Quality | PASS/FAIL | 0 | 0 | 0 | [link](filename) |
| Conflicts | PASS/FAIL | 0 | 0 | 0 | [link](filename) |
| Gaps | PASS/FAIL | 0 | 0 | 0 | [link](filename) |

### What Looks Good
- (Highlight things done well)
```

### Verdict Rules

- **READY TO MERGE**: Zero critical findings. Build passes.
- **NEEDS ATTENTION**: No criticals, but 3+ warnings.
- **NEEDS WORK**: Any critical, build failure, or merge conflicts.

### Deduplication & Polish

- If two agents flag the same issue, keep the more detailed one
- Collapse clean results ("Security: PASS -- no issues found")
- Every finding: exact file:line + concrete fix
- Do NOT flag pre-existing issues unless the PR makes them worse
- Acknowledge good work -- this is a review, not just a bug hunt

---
name: respond
description: Address PR review comments. Aggregates context (PR, sessions, meetings, code, best practices) via 4 specialist sub-agents in parallel, deeply verifies each comment, produces an action-grouped master report. Read-only — never modifies code. Main-agent context applies fixes. Use when a reviewer leaves comments on your PR.
allowed-tools: Bash, Read, Write, Grep, Glob, WebSearch, WebFetch, Agent
---

## Multi-Agent Review Response

You are the review-response orchestrator. You aggregate everything needed to address a PR review intelligently — without modifying code. The output is a master report the main-agent context (the parent conversation) reads and acts on.

**CRITICAL TOOL CONSTRAINT: You MUST use the `Agent` tool to launch sub-agents. NEVER use TaskCreate or any Task-prefixed tools.**

Ownership:
- **Orchestrator** (you): PR fetching, sub-agent dispatch, synthesis, master report.
- **Sub-agents**: each specializes — intent, code, best-practices, per-comment verification.
- **Main agent** (parent conversation): reads master report, applies code changes, drafts replies, posts to GitHub/Slack. Code changes do NOT happen in this skill.

The skill is **read-only**. No `Edit` granted. Code modification structurally cannot happen here.

---

### Step 0 — Discover the PR + author mode

Identify which PR is being reviewed:
- If the user named a PR number → use it.
- Else `git branch --show-current` + `gh pr list --head <branch>` to find the open PR for the current branch.
- If multiple matches, ask.

Detect author mode:
```bash
git log --pretty=%an origin/staging..HEAD 2>/dev/null | sort | uniq -c | sort -rn
# fallback to origin/main if origin/staging absent
```
- Sid dominant (>50% of commits) → AUTHORED.
- Otherwise → NON-AUTHORED.
- User can override ("this is OX's PR I picked up" / "this is my PR").

---

### Step 1 — Fetch PR + comments

**First, resolve the repo.** Run from inside the worktree/repo containing the PR's branch (if you're in a wrapper repo like `<project>/`, `cd` into the relevant `code/<repo>/` or `worktrees/<x>/` first):

```bash
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

**Then fetch:**

```bash
gh -R "$REPO" pr view <PR> --json title,body,author,headRefName,baseRefName,files,comments,reviews
gh api "repos/$REPO/pulls/<PR>/comments" --paginate    # inline review comments with file:line
gh -R "$REPO" pr diff <PR>
```

Git Bash gotchas — these have bitten on first use:
- `gh api` paths must NOT start with `/` — Git Bash rewrites leading slashes to filesystem paths.
- `gh api` does not accept `-R`; substitute `$REPO` into the path.
- `--json comments` already returns top-level (issue-level) PR discussion. No separate `issues/<PR>/comments` call needed.

Capture: PR meta, top-level discussion, inline review comments (with file:line refs and author), the diff. Skip resolved comments unless the user asks otherwise. If no unresolved comments, return early.

**Comment clustering:** for each top-level review comment, gather its full reply thread (original + all replies). The verifier processes one thread at a time — the **current state** of the discussion gets the verdict. Don't cluster across separate threads; each thread gets its own verifier.

---

### Step 2 — Round 1 fan-out (build context)

**MANDATORY: All round-1 sub-agents in a SINGLE message with parallel `Agent` calls.**

Spawn three agents (plus N best-practice researchers):

| Agent | Purpose |
|---|---|
| `respond-intent-archaeologist` | Find the PR's TRUE intent in session logs, meeting notes, wrap commits |
| `respond-code-explainer` | Plain-English summary of what each changed file does, refined author mode via `git blame` |
| `respond-best-practices-researcher` × N | Per significant comment topic — web research with cited sources |

Identify "significant comment topics" from the comments — group similar comments into shared topics so you don't spawn 8 researchers for 8 nit-pick comments. Cap at 6 topics per round; batch if more.

#### Briefing template

```
## Output File
OUTPUT_FILE: <abs path>

## PR
- Number: <N>
- Title: <title>
- Author: <author>
- Branch: <branch>
- Base: <base>
- Files changed: <list>

## Mode
<AUTHORED | NON-AUTHORED>

## Comments (verbatim, for context)
<full comment text + file:line per comment>

## Your job
<agent-specific — see each agent's definition>

## Project context locations
<project CLAUDE.md / KNOWLEDGE.md paths if relevant>

This is a RESEARCH task. You do NOT modify code, tests, or any tracked files.
```

Tailor the briefing — different agents need different emphasis.

---

### Step 3 — Round 2 fan-out (per-comment verification)

After round 1 completes, read all output files. Then spawn `respond-comment-verifier` once per review thread (top comment + all replies).

**MANDATORY: All round-2 verifiers in a SINGLE message with parallel `Agent` calls.** Cap at 8 in parallel; batch if more comments.

Each verifier briefing includes:
- The comment cluster (verbatim text, file:line, author)
- The PR's intent narrative (from archaeologist's report — **paste the relevant quotes**)
- The code summary (from explainer's report — **paste the relevant per-file summary**)
- Best practices for the comment's topic (from researcher's report — **paste the practices + URLs**)

Don't just reference the report files; paste the relevant excerpts. The verifier runs in its own context window and won't have time to read all three reports.

The verifier outputs a per-comment verdict file. Path: `docs/reviews/YYYY-MM-DD_pr<N>-respond-verifier-<comment-id>.md`.

---

### Step 4 — Synthesize master report

Read all sub-agent outputs. Synthesize:
- Cross-comment awareness — contradictions, duplicates, dependencies between comments
- Order of operations — which fixes should land first
- Top-level verdict — is there a DESTRUCTIVE comment requiring human halt?

Write master report to `docs/reviews/YYYY-MM-DD_pr<N>-respond.md`:

```yaml
---
date: YYYY-MM-DD
pr: <N>
author_mode: AUTHORED | NON_AUTHORED
core_intent: <one-line>
comments_total: <N>
verdicts:
  valid_critical: <N>
  valid_nit: <N>
  destructive: <N>
  wrong: <N>
  already_handled: <N>
  out_of_scope: <N>
  needs_diagnose: <N>
  needs_tests: <N>
  needs_more_info: <N>
confidence:
  high: <N>
  medium: <N>
  low: <N>
status: done
---
```

Body:

```markdown
## Core intent (the watering-down anchor)
<one paragraph from intent-archaeologist: what does this PR deliver, sourced from session logs first, PR description second>

## Comment verdicts (overview)
| # | Author | File:Line | Verdict | Confidence | Action summary |

## Per-comment details
<for each comment, sourced from its verifier output:
 - verdict + confidence + rationale
 - recommended action
 - rebuttal text drafts if WRONG/DESTRUCTIVE/ALREADY_HANDLED>

## Cross-comment notes
- Contradictions: ...
- Duplicates: ...
- Dependencies between comments: ...
- Suggested order: ...

## Action plan for main agent

### → Code changes to apply (in order)
1. <File:Line — what to change — preserves intent because X>
2. ...

### → Replies to post
- GitHub PR comment on #<comment-id>: <draft, ready to copy-paste>
- Slack thread message in #open-prs: <draft>

### → Handoffs
- /diagnose: <comment refs requiring deeper bug investigation>
- /test-writing: <comment refs requiring test additions>

### → Human judgment required
- <DESTRUCTIVE comments with options + cost analysis>

## Sources cited (from best-practices researcher)
- <URL> — <one-line>
```

---

## Print plan and proceed

Print a brief status block when you start, then proceed without asking for confirmation:

```
PR: #<N> — <title>
Mode: <AUTHORED | NON-AUTHORED>
Comments: <N> (<resolved> resolved, skipped)
Round 1 agents: intent + code + <N> best-practice researchers
Round 2 agents: <N> comment verifiers
Output: docs/reviews/YYYY-MM-DD_pr<N>-respond.md
```

Only pause for confirmation if the user explicitly asked ("show me the plan first" / "validate scope before fan-out").

---

## What this skill must refuse

- **Modifying any code** — no `Edit`. Master report only.
- **Auto-posting replies to GitHub or Slack** — drafts go in the report; main-agent posts after Sid reviews.
- **Skipping round 1** — verification without context is shallow.
- **Spawning verifiers serially** — must be a single parallel message.
- **Trusting reviewer claims without verification** — every claim is checked against the code by the verifier.
- **Asking for confirmation before fan-out** — print the plan as a status line, then proceed.
- **Defaulting verdict to agreement with reviewer** — the verifier's confidence rating is real; trust it both ways.

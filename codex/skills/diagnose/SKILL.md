---
name: diagnose
description: Deep bug investigation before any fix. Pulls relevant logs (CloudWatch, EC2 app.log, docker logs, local log files) via lib/check_logs.sh, then identifies root cause, verifies the issue is real, scans for the same pattern elsewhere, designs a fix with tradeoffs. Read-only — never modifies code. TRIGGER when user says "/diagnose", or describes a suspected bug in natural language ("X is broken", "Y isn't working", "Z is failing", "investigate this", "why is X happening", "something's wrong with Y", "this returns the wrong thing", "users are seeing X error", "I'm getting Y error", "this 500s", "this is hanging", an error message + a file path, a stack trace pasted in). DO NOT TRIGGER when: user is asking how the code works (read it directly), reviewing a PR (use /review or /respond), writing a new feature, or already knows the fix and just wants it applied.
allowed-tools: Bash, Read, Write, Grep, Glob, WebSearch, WebFetch, Agent
---

## Bug Diagnosis

You are a senior engineer investigating a suspected bug. You do not modify code. You move through four phases — root cause, verify-real-or-not, pattern scan, fix design — and produce an action-grouped report the main-agent context uses to decide what to do.

**Treat every input symptom as unverified.** Many "bugs" are misunderstandings, expected behavior, or already-fixed in another branch. Phase 2 exists to catch those before effort goes into a non-issue.

You modify NO tracked files. If you need to test a hypothesis, do it read-only or in `/tmp`.

---

### Step 1 — Investigate (capture + deep look)

**Capture the symptom from the user:**
- Expected behavior
- Observed behavior (error message, log line, screenshot description)
- Where (file:line if known; URL; specific user/account)
- Trigger (repro steps, request payload, action sequence)
- Source of report (user observation, error log, ticket, monitoring alert)

If any of this is unclear, ask. Don't guess. A hazy symptom turns into a phantom diagnosis.

Read project context: `CLAUDE.md` at repo root, `KNOWLEDGE.md`, `STATUS.md` if present. Lift relevant gotchas, recent related changes, ongoing work that might have caused this.

**Reproduce — this is a gate.** Get a deterministic trigger before investigating. Run the user's repro, or construct one. If you can't reproduce, the verdict is CANT_REPRODUCE; note what's needed (account, env, instrumentation) and stop. Investigation without a repro is hypothesis-only.

**Sweep the logs (MANDATORY — do this before code reading):**

Logs are usually the cheapest signal — they tell you the actual error path, not your guess at it. Run the project's log-sweep script before opening any code file:

```bash
bash ~/.claude-personal/skills/diagnose/lib/check_logs.sh --env <local|qa|staging|prod> --since 1h --grep "<symptom-keyword>"
```

- Pick the env where the bug was reported. Default `prod` if unclear.
- `--grep` is optional but cuts noise hard — use the unique error string, request path, user id, or trace id.
- Output is `===SECTION===` delimited blocks: CloudWatch streams, SSH `docker logs`, SSH `/app/app.log` (the source of truth on prod when CW is silent), nginx error log, plus a frontend note. For non-<project> projects it falls back to a generic local `.log` sweep.
- Capture the relevant lines into your hypothesis. If logs contradict the user's description, surface that — don't proceed on a misread symptom.
- If logs are silent: note it (it's a contributing factor for Step 3) and continue with code-only investigation.

If the bug is frontend-only (renders wrong, click does nothing) the script can't fetch the browser console. Ask for a paste.

**Investigate the code:**

1. **Error path.** What function/method, what line, what input causes the failure. Read the suspected code top-to-bottom.
2. **Forward trace.** What does this code call? Downstream effects on success vs failure.
3. **Backward trace.** Every caller. Use `Grep` exhaustively. Each caller is a scenario where this bug surfaces.
4. **Scenarios.** Auth vs guest, mobile vs desktop, region/locale, feature-flagged paths, retry paths, error paths.
5. **Dependencies.** External services, DB tables, env vars, feature flags, third-party SDKs. Each is a co-conspirator that could be the actual cause.
6. **Recent activity.** `git log --since="30 days ago" -- <file>` to see what changed lately. The bug may be a regression from a specific commit.

Output: a written hypothesis. *"The bug appears to be X in `<file>:<line>`, triggered when `<condition>`, affecting `<scenarios>`, depending on `<dependencies>`. Suspected cause: `<commit / component>`."*

---

### Step 2 — Verify the issue

Answer: **is this actually a bug?** Possible verdicts:

- **REAL_BUG** — reproducible with a clear failure mode.
- **NOT_A_BUG** — behavior matches the spec; user expectation was wrong, OR an upstream issue whose downstream symptom got mistaken.
- **ALREADY_FIXED** — fix exists in another branch, in a pending PR, or in a recent commit not yet deployed.
- **CANT_REPRODUCE** — symptom is real but you can't reliably trigger it; needs more data.
- **ENVIRONMENTAL** — bug is in config, infra, or external service — not in this codebase.

**For REAL_BUG: separate proximate from root cause.** Ask "why?" recursively until you hit something that isn't itself a bug. The first answer is the proximate cause; the last is the root. Example: `.strip()` failed → because input was None → because upstream started returning null → because the schema change wasn't reviewed against consumers. Fixing only the proximate leaves the root to bite again in a different shape.

Verification methods (use whichever apply):
- Run a read-only repro (don't mutate state in shared environments).
- `git log --all --grep="<keyword>"` for related fix commits.
- `gh pr list --search="<keyword>"` for related PRs.
- Compare suspected code against spec / docstring / OpenAPI / Pydantic schema / type definition.
- Check whether the user's expected behavior is documented anywhere.

**If verdict is NOT_A_BUG, ALREADY_FIXED, or ENVIRONMENTAL — stop here.** Skip Steps 3–4. Write the report and return. Don't pattern-scan or design fixes for non-issues.

---

### Step 3 — Pattern scan + contributing factors

The bug exists in one place. Does the same pattern exist elsewhere?

Search the codebase for:
- The buggy **primitive** (e.g., `.split('_', 1)` if the bug was a phone-format split).
- The buggy **assumption** (e.g., country code defaulted to "1" — every site that sets/parses country code).
- The buggy **interaction** (e.g., `await db.fetchval` without try-catch — every such call site).

For each occurrence, record:

| File:Line | Severity | Same fix applies? | Notes |

**Severity scale:**
- **SAME_RISK** — identical pattern, will fail identically.
- **ADJACENT** — similar pattern, might fail under different conditions.
- **RELATED** — shares root concept, separate bug worth tracking.

Skipping this step is how regressions ship. If the codebase is large, spawn parallel `Agent` searches by pattern category in a single message.

**Why didn't we catch this earlier?** Each "no" below is a process gap to surface in Step 4's fix design:
- No test for this scenario? Weak test? Test disabled?
- No type-check? `any` types or suppressed warnings hiding it?
- No review caught it? Reviewer missed? Rubber-stamped?
- No monitor / alert? Logged silently?

The fix isn't only code. It's also the test that should have existed, the type that should have been tighter, the monitor that should have alerted.

---

### Step 4 — Fix design

Design the fix. **Don't write the code.** Describe it precisely enough that the main-agent context can implement without re-investigating.

1. **Proximate fix.** Stop the immediate bleeding — smallest change that prevents the observed symptom.
2. **Root fix.** Address the cause Five Whys surfaced in Step 2. May live in a different layer than the symptom (parser, schema, contract). Without this, the bug returns in a different shape.
3. **Process fix.** Every "no" from Step 3's contributing factors becomes a deliverable here — the test that should have caught it, the type that should have been tighter, the monitor that should have alerted, the review checklist item.
4. **Pattern fix.** If Step 3 found other occurrences, decide bundle vs split.
5. **Tradeoffs.** Performance, breaking-change surface, backward compat, migration path.
6. **Best-practice check.** If the fix touches a domain you're not deeply expert in (E.164 phone, JWT, OAuth, DB isolation, retry/idempotency, crypto), use `WebSearch` / `WebFetch`. Cite sources.
7. **Tests required.** Regression test for `/test-writing` handoff. Property/contract tests if applicable.
8. **Risk + rollback.** Deploy risk, revert path, feature flag if needed.
9. **Sanity check.** If the proposed fix were applied, would the Phase 1 repro pass? If unsure, the fix isn't tight enough.

---

### Step 5 — Master report (action-grouped)

Write to `docs/diagnoses/YYYY-MM-DD_<slug>.md` (or per-project diagnoses dir if documented in CLAUDE.md).

**Slug logic:** issue/bug ID if available; else first 3–4 words of the symptom.

```yaml
---
date: YYYY-MM-DD
status: done
verdict: REAL_BUG | NOT_A_BUG | ALREADY_FIXED | CANT_REPRODUCE | ENVIRONMENTAL
severity: critical | high | medium | low
files_affected: <N>
pattern_occurrences: <N>
---
```

Body:

```markdown
## Verdict
<one-line verdict + one-sentence rationale>

## Symptom
- Expected: ...
- Observed: ...
- Where: file:line
- Trigger: ...
- Source: ...

## Proximate cause
<one line: the immediate failure mode>

## Root cause
<one line: what allowed the proximate cause to exist (Five Whys terminus)>

## Affected scenarios
| Scenario | Frequency | Impact |

## Dependencies involved
- ...

## Pattern occurrences (Step 3)
| File:Line | Severity | Same fix? | Notes |

## Why this shipped (contributing factors)
- Test gap: ...
- Type/lint gap: ...
- Review gap: ...
- Monitoring gap: ...

## Proposed fix
- Approach: ...
- Tradeoffs: ...
- Best-practice references (if researched):
  - <URL> — <one-line summary>
- Tests required: ...
- Rollback: ...

## Action groups (for the main-agent context)

### → Code changes
| File:Line | What changes | Complexity |

### → Tests to add (handoff to /test-writing)
| Test type | Behavior | Tier |

### → Verifications before merging
| What | How |

### → Human judgment required
| Issue | Why human-only |

## Next steps
1. ...
2. ...
```

---

## What this skill must refuse

- **Modifying any code** — read-only investigation. Never Edit.
- **Designing a fix without verifying the bug is real** — Step 2 gates Steps 3–4.
- **Stopping at the first occurrence** — Step 3 is mandatory unless verdict skips it.
- **Recommending a fix without articulating tradeoffs.** If the fix is obvious, say so; if it has tradeoffs, list them.
- **Skipping web research when the fix touches a domain outside your expertise.** One extra `WebSearch` beats shipping a fix that contradicts industry practice.
- **Auto-applying the fix** — final disposition is the main-agent context's job.
- **Pattern-scanning beyond the changed/touched repos** — stay in scope. Multi-repo investigation is fine when the workspace contains multiple repos; out-of-scope codebases are noise.

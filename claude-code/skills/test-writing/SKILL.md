---
name: test-writing
description: Multi-agent test authoring. Smart orchestrator that classifies the diff, picks the right specialist writers per file in parallel, runs sanity verification, then critic + validator passes. Idempotent — running twice on the same state produces the same report. Use after a feature/fix is implemented and before opening a PR.
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, Agent
---

## Multi-Agent Test Writing

You are the test-writing orchestrator. You analyze the diff, classify every changed file by stack and test type, brief specialist writer agents in parallel, run a sanity check, then dispatch critic + validator agents to grade the output.

**CRITICAL TOOL CONSTRAINT: You MUST use the `Agent` tool to launch writer agents. NEVER use TaskCreate or any Task-prefixed tools.**

Ownership:
- **Orchestrator** (you): detection, classification, behavior extraction, fan-out, sanity run, synthesis.
- **Writers**: test code only. Never modify implementation source.
- **Critic**: quality review + mutation pass.
- **Validator**: spec coverage + tier coherence + xfail tracker check.

The skill does NOT loop. It produces an action-grouped master report and stops. The main-agent context (the parent conversation) reads the report, applies fixes (impl bugs, test rewrites, missing coverage), commits, and re-invokes `/test-writing` for the next pass.

---

### Step 0 — Detect the testing environment

Don't assume anything. Read project context first:

1. **Project CLAUDE.md hierarchy.** Read `CLAUDE.md` at repo root, then `code/CLAUDE.md` if present, then per-repo `CLAUDE.local.md`. Read `KNOWLEDGE.md` and `STATUS.md` if they exist. Lift:
   - Documented test conventions (frameworks, layout, helpers)
   - Project gotchas (validators, auth flows, known broken patterns)
   - Mutation tool used in the project, if mentioned
   - Existing testing infrastructure status
2. **Probe install state** in each touched repo:
   - Python: grep `requirements.txt` / `pyproject.toml` for `pytest`, `pytest-asyncio`, `httpx`, `hypothesis`, `freezegun`, `mutmut`, `asyncpg`
   - JS/TS: read `package.json` for `vitest`, `jest`, `@testing-library/react`, `@playwright/test`, `fast-check`, `msw`, `stryker-mutator`
   - System: `command -v mutmut`, `command -v stryker`, `command -v pitest`
3. **Probe existing test layout AND the project's discovery config:**
   - **Vitest:** read `vitest.config.{ts,js,mjs}` at repo root OR the `test:` block in `vite.config.{ts,js,mjs}`. Capture the `include` glob (e.g., `['tests/**/*.test.{ts,tsx}']` vs `['src/**/*.test.{ts,tsx}']`). If `include` doesn't match `src/**`, **co-located tests will not be discovered** — Step 2 must place tests under the matching directory.
   - **Jest:** capture `testMatch` / `testRegex` from `package.json` or `jest.config.*`.
   - **Pytest:** layout follows `tests/` by default plus any `testpaths` set in `pytest.ini` / `pyproject.toml [tool.pytest.ini_options]`.
   - **Playwright:** capture `testDir` from `playwright.config.*`.
   - Also note existing dirs: `tests/`, `__tests__/`, co-located `*.test.ts`, `e2e/`.
   - **Record the canonical test path glob per repo.** Step 2 uses it to assign writer test paths so the test runner actually discovers the file.
4. **Missing-framework handling.** If a critical framework is missing for a writer type you'd want to spawn, do NOT silently install. Flag in the briefing: "Property tests skipped — Hypothesis not installed; install before re-run." Skip that writer type but continue with others.
5. **Greenfield handling.** If no test conventions exist anywhere in the touched repo, ASK the user before bootstrapping (which framework, which layout, which mutation tool). Don't pick defaults silently — getting this wrong sets the convention for the project.

If you can't read CLAUDE.md or probe deps, escalate to the user before continuing.

---

### Step 1 — Gather and classify the diff

```bash
git branch --show-current
git fetch origin staging --quiet 2>/dev/null || git fetch origin main --quiet
git diff --stat origin/staging...HEAD 2>/dev/null || git diff --stat origin/main...HEAD
git log origin/staging..HEAD --oneline 2>/dev/null || git log origin/main..HEAD --oneline
git diff origin/staging...HEAD -- . ':(exclude)package-lock.json' ':(exclude)yarn.lock' ':(exclude)*.lock' 2>/dev/null \
  || git diff origin/main...HEAD -- . ':(exclude)package-lock.json' ':(exclude)yarn.lock' ':(exclude)*.lock'
```

Then **analyze yourself**:

1. **Mode** — `bug` (branch starts `fix/`/`hotfix/`, commits reference an issue) / `feature` (branch starts `feat/`, new files / new public API) / `mixed`. If unclear, ask.

2. **Stack per file** — use the path-→-stack mapping documented in the project's CLAUDE.md. Generic fallback: `pyproject.toml`/`requirements.txt` near the file → backend; `package.json` with `next` → website-like; `vite` only → admin-like.

3. **Skip these files:**
   - Pure renames, formatting-only, comment-only changes
   - Lock files, generated files
   - **Trivial files**: < 5 non-comment non-blank lines, type-only files, re-export-only files. State why each was skipped.

4. **Per-file test-type plan.** Read project CLAUDE.md for project-specific routing. Generic fallback:

   ```
   BACKEND:
     pure logic (services/utils/models/validators) → unit
     endpoints / routers                            → integration + contract
     parsers / serializers / state machines         → unit + property
     external SDK boundaries (openai/twilio/etc.)   → contract
     migrations                                     → migration

   FRONTEND / ADMIN:
     stores/slices, utils, hooks, lib              → unit
     services, api adapters                         → integration
     components, pages                              → component
     critical user journeys (auth/checkout/etc.)   → component + e2e
   ```

5. **Behavior extraction (your job — keep it simple).** For each file under test, list 3–10 behaviors as one-line tuples:

   ```
   <name>  |  <input/precondition>  |  <expected output/postcondition>
   ```

   Read the public contract: signatures, type defs, docstrings, route decorators, prop types, exported symbols. **Do not open the implementation body** unless the contract is genuinely ambiguous.

   Examples:
   - Backend endpoint: `login_with_valid_creds | POST /login {email,pw} | 200 + session_token + cookie set`
   - React component: `submit_disabled_when_invalid | render with empty form | submit button disabled`
   - Util: `normalize_e164 | "+91_6302964327" | "+916302964327"`

   Aim for 3–5 behaviors per simple file, up to 10 for complex ones. Don't enumerate every edge case — writers handle equivalence-partitioning + boundary-value within their tier.

6. **Tier per behavior** — `regression` (default) / `smoke` (happy path on critical flows) / `xfail` (only with a tracker reference: issue #, STATUS.md line, known-bug doc).

7. **Briefing** — 5–10 bullets summarizing what changed, stacks touched, per-file plan, project-specific gotchas lifted from CLAUDE.md/KNOWLEDGE.md, mutation tool availability.

Print the plan to the user as a brief status block — do **not** prompt for confirmation:

```
Mode: <bug | feature | mixed>
Files under test: <N> (skipped <M>: <reasons>)
Stacks: <list>
Per-file plan:
  <file>  → <writer-types>  (tier: <R|S|X>)
Total writer agents to spawn: <N>
Mutation tool: <mutmut | stryker | hand-mutation>
Output dir: docs/tests/YYYY-MM-DD_<slug>-*.md
```

Then proceed immediately to Step 2. Only pause for confirmation if the user's invocation explicitly requested one (e.g., "show me the plan before fan-out", "validate scope first"). Default behavior: status print + go.

---

### Step 2 — File paths (collision-safe)

**Slug logic (pick first match):**
1. PR review: `pr<NUMBER>-<short-description>`
2. Feature branch: branch name slugified
3. Bug fix: `bug-<short-description>`
4. Fallback: first 3–4 words from briefing

**Report paths:**
```
docs/tests/YYYY-MM-DD_<slug>-writer-<type>-<file-stem>.md   # one per writer
docs/tests/YYYY-MM-DD_<slug>-critic.md
docs/tests/YYYY-MM-DD_<slug>-validator.md
docs/tests/YYYY-MM-DD_<slug>-master.md
```

**Test-file paths — type suffix prevents writer collisions on the same source file:**

**Resolution rule (READ THIS BEFORE USING THE TABLE):** the `include` glob probed in Step 0 #3 wins. If `vitest.config.ts` says `include: ['tests/**/*.test.{ts,tsx}']`, frontend writers MUST place tests under `tests/<area>/` regardless of what the "Frontend" column below shows. Co-located paths only work when the project's `include` actually matches `src/**`. Same logic for jest `testMatch` and pytest `testpaths`. The table below is a fallback for greenfield repos with no config.

| Writer | Backend (pytest) | Frontend (vitest, co-located default) | Frontend (vitest, `tests/**` config) | E2E (playwright) |
|---|---|---|---|---|
| unit | `tests/unit/test_<file>.py` | `<file>.test.ts(x)` co-located | `tests/unit/<file>.test.ts(x)` | n/a |
| integration | `tests/integration/test_<file>.py` | `<file>.integration.test.tsx` | `tests/integration/<file>.test.tsx` | n/a |
| component | n/a | `<Component>.test.tsx` | `tests/components/<area>/<Component>.test.tsx` | n/a |
| property | `tests/property/test_<file>.py` | `<file>.property.test.ts` | `tests/property/<file>.test.ts` | n/a |
| contract | `tests/contract/test_<seam>.py` | `<area>.contract.test.ts` | `tests/contract/<area>.test.ts` | n/a |
| regression | `tests/regression/test_bug_<id>.py` | `<area>.regression.test.tsx` | `tests/regression/<area>.test.tsx` | `e2e/regression-<id>.spec.ts` |

If neither the project's `include` glob nor any existing test files match `src/**` AND no `tests/` dir exists, you're in greenfield-test territory — go back to Step 0 #5 and ask the user.
| migration | `tests/migrations/test_<NNN>_<name>.py` | n/a | n/a |
| e2e | n/a | n/a | `e2e/<flow>.spec.ts` |

If existing repo conventions diverge, **match the existing convention** but apply a writer-type suffix anyway to prevent overwrites between writers targeting the same source file. Tell each writer their assigned path explicitly.

---

### Step 3 — Fan-out (single parallel message)

**MANDATORY: All writer agents in a SINGLE message with parallel `Agent` calls.** This applies to bug, feature, AND mixed mode.

- **Bug mode** — one `test-writer-regression` per distinct bug. Two bugs in the branch → two regression-writers in parallel. Don't expand coverage.
- **Feature mode** — for each file under test, spawn the applicable specialist writers. Skip writer types that don't apply.
- **Mixed mode** — regression-writer(s) for bug-touched files PLUS feature writers for non-bug files, all in the single parallel message.

**Batching cap.** If a single round would spawn more than ~8 writer agents, batch into multiple parallel rounds (8 per round) rather than one giant fan-out. Wait for each round to complete before starting the next. Tell the user the round count up front.

**Agent failure handling.** If any writer fails to produce its `OUTPUT_FILE` or returns malformed output, log it, continue with the other writers, and mark that file as `partial` in the master report. Don't retry the failed writer in the same `/test-writing` run — that's the main-agent context's job on the next pass.

#### Writer registry

| Agent | Spawns when |
|---|---|
| `test-writer-unit` | Pure-logic file (service, util, slice, hook) |
| `test-writer-integration` | Endpoint, page, form |
| `test-writer-component` | React component / page |
| `test-writer-e2e` | Critical user journey only |
| `test-writer-property` | Parser, serializer, math, reversible op |
| `test-writer-regression` | Bug fix (one per distinct bug) |
| `test-writer-contract` | API seam (FE↔BE, BE↔external) |
| `test-writer-migration` | DB migration |

#### Writer prompt template

```
## Output File
**You MUST write your full report to:**
OUTPUT_FILE: <abs path>

## Test File
**You MUST write your test code to (orchestrator-assigned, type-suffixed):**
TEST_FILE: <abs path>

## Working directory
CWD: <abs path of the repo containing this file>

## Scope
- Branch: <branch>
- Mode: <bug | feature>
- Tier: <regression | smoke | xfail (with tracker ref)>
- Stack: <BACKEND | WEBSITE | ADMIN | other>
- File under test: <abs path>

## Public contract (orchestrator-extracted — do NOT re-read implementation body)
<signatures, types, docstrings>

## Behaviors to cover
1. <name> | <input> | <expected>
2. ...

## Project gotchas (from CLAUDE.md / KNOWLEDGE.md)
- ...

## Existing test conventions (probed in Step 0)
- Framework: <pytest | vitest | playwright>
- Layout: <existing convention in this repo>
- Helpers available: <list, with paths>

## Mock policy for this stack
- <stack-specific>

## Mutation tool used by the project
- <mutmut | stryker | hand-mutation by critic>

This is an AUTHORING task. You write the test file. You DO NOT modify the implementation file. After authoring, run the new tests on the real impl and confirm they pass — that's your verification beat. Mutation testing is the critic's job, not yours.
```

**Tailor each briefing — different specialty emphasis per writer**. Don't send the same prose to every agent.

---

### Step 4 — Sanity verification (orchestrator-run, fast)

After all writers complete:

1. **Run new tests on the current (real) impl** for each writer's test file (use the right CWD per repo):
   ```bash
   cd <repo>
   pytest <test_file> -x --tb=short        # backend
   npx vitest run <test_file>              # frontend
   npx playwright test <test_file>         # e2e
   ```

2. **All new tests must pass.** If any fail:
   - Compare the test against the contract in your behavior list. If the test matches the contract and fails, you've likely surfaced an **impl bug** — record under "→ Possible impl bugs" in the master report. Don't reject the test.
   - If the test mismatches the contract → ask the writer to rewrite (one retry). After retry, if still failing, mark `partial` and record in master report.

3. **Roll back rejected tests** so the next run starts clean. Use `git checkout -- <test_file>` if the file was already tracked; else `rm` it. Never leave bad tests on disk.

That is the orchestrator's only verification beat. Mutation runs in the critic. Spec coverage runs in the validator.

---

### Step 5 — Critic + Validator (parallel, single message)

Spawn both in parallel after Step 4. They have **non-overlapping scopes** — read each agent's prompt definition for boundaries.

| Agent | Owns |
|---|---|
| `test-critic` | Quality review + per-file mutation pass |
| `test-completion-validator` | Spec coverage + tier coherence + xfail tracker check |

These do NOT duplicate work. Critic does NOT redo spec coverage. Validator does NOT redo mutation. The master report aggregates both.

#### Critic briefing
```
## Output File
OUTPUT_FILE: <path>

## Scope
- Branch, files under test, new test files, behaviors per file
- Mutation tool: <mutmut | stryker | hand-mutation>
- Sanity run results from Step 4

## Your job
Run the suite. Read the tests. Run mutation per file (or call the project's mutation tool). Flag tautology, weak assertions, over-mocking, sleep-waits, implementation coupling, snapshot abuse. Do NOT modify any files. Do NOT redo spec-coverage check (validator's job).
```

#### Validator briefing
```
## Output File
OUTPUT_FILE: <path>

## Scope
- Branch, files under test, behaviors-per-file (orchestrator's spec)
- New test files
- Sanity run results from Step 4

## Your job
Verify every spec behavior has at least one test. Verify tier classifications. Verify each xfail references a real tracker. Read impl files briefly for hidden code paths the spec missed. Do NOT modify any files. Do NOT redo mutation testing (critic's job).
```

---

### Step 6 — Coverage report (informational only)

If a coverage tool is configured in the project, run it scoped to the new test files:

```bash
pytest --cov=<src> --cov-report=term-missing <new_test_files> -q     # backend
npx vitest run --coverage <new_test_files>                            # frontend
```

Coverage goes into the master report as informational, **not as a verdict gate**. Coverage is a floor metric, not a quality oracle. If no coverage tool exists, skip and note "coverage skipped — tool not configured."

---

### Step 7 — Master report (action-grouped)

Read all writer reports + critic + validator + sanity results. Build:

```
---
status: done | partial | blocked
mode: bug | feature | mixed
branch: <branch>
date: YYYY-MM-DD
files_tested: <N>
tests_added: <N>
mutants_killed: <N>
mutants_survived: <N>
verdict: READY | NEEDS_REWRITE | NEEDS_INVESTIGATION | BLOCK
---

# Test Authoring Report

## Verdict
<one-line verdict + one-sentence rationale>

## Action groups (for the main-agent context to handle on next pass)

### → Test rewrites needed
| File:Line | Test name | Why | Suggested fix |
| ...

### → Possible impl bugs (sanity surfaced something that looks wrong)
| File:Line | Test name | What failed | Possible cause | Investigation hint |
| ...

### → Coverage gaps (next /test-writing run should re-spawn writers)
| Behavior | File | Recommended writer type | Notes |
| ...

### → Human judgment required
| Issue | Why human-only | Recommendation |
| ...

## Per-file results
| File | Writers | Tests added | Mutants killed/total | Critic | Validator |

## Tier breakdown
- Regression: <N>
- Smoke: <N>
- Xfail: <N> (each with tracker ref verified by validator)

## What looks good
- ...

## Coverage delta (informational, not a gate)
- ...

## Agent reports
| Agent | Verdict | Output |
| ...

## Next-pass instructions for the main-agent context
1. Investigate any "possible impl bugs" before merging.
2. Apply suggested fixes for "test rewrites needed."
3. Re-run /test-writing to re-test the affected files.
4. Repeat until verdict is READY.
```

### Verdict rules

- **READY** — sanity passes, mutation kill rate ≥ 80% on regression-tier tests, validator APPROVED, no surviving mutants on regression tests.
- **NEEDS_REWRITE** — critic or validator flagged rewriteable issues. Recoverable in the next pass after main-agent fixes.
- **NEEDS_INVESTIGATION** — sanity check failed but tests look right vs contract. Likely an impl bug surfaced. Hand to human.
- **BLOCK** — verification couldn't run (broken build, missing deps, no DB, no mutation tool AND hand-mutation timed out). Escalate.

If mutation can't run AT ALL, mark verdict as `partial` with explicit note rather than pretending tests are good.

---

### Step 8 — Cleanup + standup

- All test files written or rolled back per Step 4 outcome.
- All reports under `docs/tests/`.
- No implementation files modified — verify with `git diff <impl-paths>` (must be empty); if not, surface to user.
- If on a project that maintains a standup file (<project> maintains `docs/standups/<next-business-day>.txt`), append: tests added, mutation kill rate, files covered. Skip if no standup convention exists.

---

## What this skill must refuse

- **No diff** — return early.
- **Modifying impl files** — never. Verify clean with `git diff` before finishing.
- **Auto-pushing or merging** — final disposition is human.
- **Skipping Step 0** — no plan without environment detection. CLAUDE.md and dep probes come first.
- **Spawning writers serially when they could be parallel** — single Agent message with multiple parallel calls.
- **More than one writer per bug in bug-mode** — bug mode is surgical. Multiple bugs spawn multiple parallel regression-writers; one bug spawns one.
- **Xfail without a tracker reference** — validator rejects.
- **Looping on its own** — produce master report, stop. The main-agent context handles fixes and re-invokes the skill.
- **Silently installing missing test frameworks** — flag and ask.

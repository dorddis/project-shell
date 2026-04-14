# CLAUDE.md - [PROJECT_NAME]

**Role:** [YOUR_ROLE] at [COMPANY] ([PROJECT_NAME] product)
**Started:** [START_DATE]

---

## Document Formatting

- **Horizontal rules (`---`):** Only use at the very top (after title/header) and very bottom of documents. Do NOT place `---` between sections -- headings alone provide sufficient separation.

---

## Product

**[PROJECT_NAME]** - [PRODUCT_DESCRIPTION].

- [Key feature 1 -- what it does, who uses it]
- [Key feature 2 -- what it does, who uses it]
- [Key feature 3 -- what it does, who uses it]
- Target market: [TARGET_MARKET]
- Competitors: [COMPETITOR_1], [COMPETITOR_2] ([what they lack that you offer])

**Environments:**
- Production: [PROD_URL]
- Staging/UAT: [STAGING_URL]
- Local dev: localhost:[PORT]

## Team

| Role | Person | Notes |
|------|--------|-------|
| [Founder/CEO] | [Name] | [Location, timezone, communication style] |
| [Backend Dev] | [Name] | [What they own, key context] |
| [Frontend Dev] | [Name] | [What they own, key context] |
| [Designer] | [Name] | [What they own, key context] |
| **[YOUR_ROLE]** | **[YOUR_NAME]** | [Your focus areas] |

## My Role

[YOUR_ROLE] owning:
- **Track 1:** [PRIMARY_RESPONSIBILITY] -- [current status: active / on hold / completed]
- **Track 2:** [SECONDARY_RESPONSIBILITY] -- [current status]

Current tasks and priorities live in `STATUS.md`.

## Key Context

**[LEADER_NAME]'s operating pattern:**
- [How they communicate -- async? sync? what cadence?]
- [Urgency patterns -- do they want everything "today"? Are they methodical?]
- [Scope alignment -- do you need to push back on scope, or is it well-defined?]
- [Autonomy level -- micromanaged or trusted to run independently?]

**Vendor / External team dynamics (if applicable):**
- [Who controls what -- GitHub admin, cloud provider, CI/CD]
- [Who can merge PRs -- is it you, them, shared?]
- [Communication channels -- Slack, Basecamp, email, Jira comments]
- [Known friction points -- e.g., "they merge without running migrations"]
- See `KNOWLEDGE.md > Vendor Relationship` for full details

**Tech stack:** [e.g., "FastAPI + Next.js 14"]. Full details in `KNOWLEDGE.md > Tech Stack`.

**Access checklist:**
- [ ] Company email: [YOUR_EMAIL]
- [ ] GitHub org: [ORG_NAME] (role: [admin/member/etc.])
- [ ] Cloud provider: [AWS/GCP/Azure] (IAM role: [details])
- [ ] CI/CD pipeline access
- [ ] Staging DB (direct access? VPN? IP whitelist?)
- [ ] Local DB ([db_name] on localhost:[port], user [user]/[pass])
- [ ] Project management: [Jira/Linear/ClickUp] (API token in `.env`)
- [ ] Communication: [Slack/Teams/Discord]

## Working Hours

- **[YOUR_TIMEZONE]:** [START] - [END] ([notes on flexibility])
- [LEADER_NAME] timezone: [THEIR_TZ] -- overlap: [HOURS] hours
- Team standups: [TIME] [TIMEZONE]

## Folder Structure

```
[PROJECT_NAME]/
├── CLAUDE.md              # This file - role, workflow, schedule
├── AGENTS.md              # Universal AI context (cross-tool compatible)
├── STATUS.md              # Current priorities, blockers, waiting-on
├── KNOWLEDGE.md           # ALL product/architecture knowledge (single source of truth)
├── SESSION_INDEX.md       # Session discovery index
├── docs/                  # ALL non-code artifacts
│   ├── standups/          # Daily standup prep files (YYYY-MM-DD.txt)
│   ├── reviews/           # Agent review outputs. Frontmatter status: done|partial|in-progress|pending
│   ├── codebase/          # Reference docs: repo audits, analyses, issue trackers
│   ├── research/          # Tool comparisons, approach evaluations
│   └── architecture/      # Cross-cutting proposals, ADRs, strategy docs
├── sessions/              # Session logs (one per work session, append-only)
├── workflows/             # Reusable AI workflows (wrap, review, etc.)
├── code/                  # Cloned repos + shared dev context (if wrapper project)
│   ├── CLAUDE.md          # Shared product context for ALL dev work
│   ├── backend/
│   │   └── CLAUDE.local.md  # Backend-specific dev patterns + architecture
│   └── frontend/
│       └── CLAUDE.local.md  # Frontend-specific dev patterns + architecture
├── internal/              # Contracts, comp, company docs (never committed to shared repos)
└── archive/               # Old/completed work (never delete, always archive)
```

**Where things go:**
- **Code review agent outputs** -> `docs/reviews/` (with frontmatter status tag)
- **Research, analysis, test results, audits** -> `docs/<subfolder>/` (always tracked)
- **Code changes (staging/hotfix)** -> `code/` repos (on staging branch)
- **Code changes (features)** -> feature branches or worktrees
- **Architecture decisions, product knowledge** -> `KNOWLEDGE.md` (single source of truth)
- **Current state, priorities** -> `STATUS.md`
- **Daily standup notes** -> `docs/standups/YYYY-MM-DD.txt` (next day's prep, auto-accumulated)

**Context hierarchy (what Claude reads):**
1. `CLAUDE.md` (root) -> role, workflow, schedule
2. `code/CLAUDE.md` -> product context for all dev work (team, vendor, architecture)
3. `code/*/CLAUDE.local.md` -> repo-specific patterns, key files, coding conventions
4. `KNOWLEDGE.md` -> deep reference (read on demand, not every session)

**IMPORTANT: When context is missing, read `KNOWLEDGE.md` before asking the user.** It contains full product architecture, tech stack details, vendor history, security audit findings, and infrastructure state. Key sections to reference:
- **Local dev setup (DB, backend, frontend)** -> `KNOWLEDGE.md > Local Development Setup`
- **Tech stack / architecture questions** -> `KNOWLEDGE.md > Tech Stack`, `> Backend Architecture`, `> Frontend Architecture`
- **Infrastructure** -> `KNOWLEDGE.md > Infrastructure`
- **Security findings** -> `KNOWLEDGE.md > Known Security Issues`
- **Vendor dynamics** -> `KNOWLEDGE.md > Vendor Relationship`
- **Current sprint / blockers** -> `STATUS.md` (check first 30 lines for current state)

## Standup Notes (Auto-Accumulate)

**Location:** `docs/standups/YYYY-MM-DD.txt` (date = the NEXT standup day, not today)

**Throughout every session, auto-save standup-worthy items** to tomorrow's standup file. Anything that's a completed task, merged PR, blocker resolved, decision made, or noteworthy progress should be appended.

**When to write:**
- PR merged or created -> add to standup file
- Migration run -> add to standup file
- Blocker resolved or new blocker found -> add to standup file
- Spec/doc delivered to someone -> add to standup file
- Decision made in a meeting/call -> add to standup file
- Anything your manager would want to hear about -> add to standup file

**Format:** Plain text, same structure as existing files in `docs/standups/`. Sections: WHAT I DID, OPEN PRs, BLOCKERS, WHAT I'M WORKING ON TODAY, DEMO LINKS. Keep it terse -- bullet points, not paragraphs.

**Rules:**
- Short and precise. No fluff, no filler words.
- Write as neutral facts or first-person actions.
- No AI fingerprints. Write like a human typed quick notes.

**On session start:** Read tomorrow's standup file (if it exists) to see what's already accumulated.

**On `/wrap` or session end:** Ensure the standup file for the next business day is up to date with everything done this session.

**File naming:** Use the date of the NEXT standup. If working on Monday, file is for Tuesday. If working on Friday, file is for Monday. Weekends accumulate into Monday's file.

## Code Routing (WHERE to make changes)

- **Feature work** -> feature branch: `git checkout -b feature/[your-name]-[feature-name] [base-branch]`
- **Hotfix** -> fix branch off main: `git checkout -b fix/[your-name]-[description] main`
- **New feature (with worktrees)** -> `cd code/<repo> && git worktree add ../../worktrees/<name> -b feature/[your-name]-<name> [base-branch]`

**If using git worktrees** (recommended for multi-repo projects):

| Worktree | Repo | Branch |
|----------|------|--------|
| `worktrees/[feature-name]/` | [repo] | `feature/[your-name]-[feature-name]` |

**Rules:**
- NEVER edit `code/` when a worktree exists for that feature
- Feature work -> use its worktree in `worktrees/`
- Staging hotfix -> edit `code/<repo>/` directly

## Git Workflow

**Git Identity:**
- **Name:** [YOUR_NAME]
- **Email:** [YOUR_EMAIL]
- **GitHub:** [YOUR_GITHUB_USERNAME] (org: [ORG_NAME])

**Before every commit, push, or PR:**

1. **Review all changes** -- check for secrets/key leaks, debug statements, unintended files, pattern violations
2. **Run linting/formatting** if configured
3. **Run tests** if they exist
4. **Commit messages** -- clean, professional, Conventional Commits format
5. **No AI fingerprints** -- no co-author attribution lines unless your team wants them

**CRITICAL: NEVER create a PR unless:**
1. The code has been **tested locally** (build passes, manual verification, E2E where applicable)
2. All changes have been **reviewed for quality** (self-review at minimum, AI review recommended)
3. You are confident the code is **production-ready** -- not "ready enough"

**Commit messages** -- Conventional Commits format:

```
<type>(<scope>): <description>

- file1 path - what was done and why
- file2 path - what was done and why
```

**Types:**
| Type | When |
|------|------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `refactor` | Restructure without behavior change |
| `perf` | Performance improvement |
| `test` | Adding/fixing tests |
| `docs` | Documentation only |
| `chore` | Maintenance, deps, configs |
| `build` | Build system or dependency changes |

**Scope:** Optional but encouraged. Use the component/module name (e.g., `auth`, `api`, `dashboard`).

## DB & Migrations

**Migration strategy:** [Alembic / Prisma / manual SQL / Flyway / Knex / Django / etc.]

**Local DB:**
- Host: localhost:[PORT]
- DB: [DB_NAME], User: [USER]/[PASS]

**Staging DB:**
- Host: [STAGING_HOST]
- Access: [how -- VPN? IP whitelist? SSH tunnel?]
- Credentials: [where -- Secrets Manager? .env? Ask team lead?]
- **WARNING:** If your backend `.env` points to local DB, NEVER use `.env` creds for staging queries.

**Applying migrations:**
```bash
# Local
[your local migration command]

# Staging
[your staging migration command -- e.g., script or manual psql]
```

**Migration rules:**
- Check ALL open branches before picking a migration number (avoid collisions)
- Use idempotent patterns (`IF NOT EXISTS` / `IF EXISTS`) where possible
- Mention migration files explicitly in PR descriptions and team communication
- Apply migrations yourself if you have direct DB access; don't wait for others

## Related Locations

| What | Where |
|------|-------|
| Meeting recordings | [Path or service] |
| Contract/comp docs | `internal/` |
| Session logs | `sessions/` |
| Architecture docs | `docs/architecture/` |
| Project management | [Tool name + URL] |

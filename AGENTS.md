# AGENTS.md - [PROJECT_NAME]

**Role:** [YOUR_ROLE] at [COMPANY] ([PROJECT_NAME] product)
**Started:** [START_DATE]

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
- [Communication style, cadence, urgency patterns]
- [Scope alignment approach -- do you push back, or is it well-defined?]
- [Autonomy level -- trusted or micromanaged?]

**Vendor / External team dynamics (if applicable):**
- [Who controls what -- GitHub, cloud, CI/CD]
- [Who can merge PRs]
- [Communication channels]
- [Known friction points]
- See `KNOWLEDGE.md > Vendor Relationship` for full details

**Tech stack:** [e.g., "FastAPI + Next.js 14"]. Full details in `KNOWLEDGE.md > Tech Stack`.

**Access checklist:**
- [ ] Company email: [YOUR_EMAIL]
- [ ] Source control: [GitHub/GitLab/Bitbucket] (org: [ORG_NAME], role: [admin/member])
- [ ] Cloud provider: [AWS/GCP/Azure] (role: [details])
- [ ] CI/CD pipeline access
- [ ] Staging DB (access method: [direct/VPN/IP whitelist])
- [ ] Local DB ([db_name] on localhost:[port])
- [ ] Project management: [Jira/Linear/ClickUp]
- [ ] Communication: [Slack/Teams/Discord]

## Working Hours

- **[YOUR_TIMEZONE]:** [START] - [END] ([notes on flexibility])
- [LEADER_NAME] timezone: [THEIR_TZ] -- overlap: [HOURS] hours
- Team standups: [TIME] [TIMEZONE]

## Folder Structure

```
[PROJECT_NAME]/
├── AGENTS.md              # This file - role, workflow, team, schedule
├── CLAUDE.md              # Claude Code specific context (if using Claude)
├── STATUS.md              # Current priorities, blockers, waiting-on
├── KNOWLEDGE.md           # Evergreen product/architecture reference
├── SESSION_INDEX.md       # Session discovery index
├── docs/                  # All non-code artifacts
│   ├── standups/          # Daily standup prep files (YYYY-MM-DD.txt)
│   ├── reviews/           # Code review agent outputs
│   ├── codebase/          # Repo audits, analyses, issue trackers
│   ├── research/          # Tool comparisons, approach evaluations
│   └── architecture/      # ADRs, design docs, proposals
├── sessions/              # Session logs (one per work session, append-only)
├── workflows/             # Reusable AI workflows (wrap, review, etc.)
├── code/                  # Cloned repos + shared dev context (if wrapper project)
│   ├── backend/
│   └── frontend/
├── internal/              # Contracts, comp, company docs (never shared)
└── archive/               # Old/completed work (never delete, always archive)
```

**Where things go:**
- **Code review outputs** -> `docs/reviews/` (with frontmatter status tag)
- **Research, analysis, test results, audits** -> `docs/<subfolder>/`
- **Architecture decisions, product knowledge** -> `KNOWLEDGE.md` (single source of truth)
- **Current state, priorities** -> `STATUS.md`
- **Daily standup notes** -> `docs/standups/YYYY-MM-DD.txt` (next day's prep, auto-accumulated)

**Context hierarchy (what the AI reads):**
1. `AGENTS.md` / `CLAUDE.md` (root) -> role, workflow, schedule
2. `STATUS.md` -> current state (read first 30 lines for quick orientation)
3. `KNOWLEDGE.md` -> deep reference (read on demand, not every session)

**IMPORTANT: When context is missing, read `KNOWLEDGE.md` before asking the user.** It contains product architecture, tech stack details, environment setup, vendor history, and historical decisions. Key sections:
- **Local dev setup** -> `KNOWLEDGE.md > Local Development Setup`
- **Tech stack / architecture** -> `KNOWLEDGE.md > Tech Stack`, `> Backend Architecture`, `> Frontend Architecture`
- **Infrastructure** -> `KNOWLEDGE.md > Infrastructure`
- **Security** -> `KNOWLEDGE.md > Security Considerations`
- **Vendor dynamics** -> `KNOWLEDGE.md > Vendor / External Team Dynamics`
- **Current sprint / blockers** -> `STATUS.md` (check first 30 lines)

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

**Format:** Plain text. Sections: WHAT I DID, OPEN PRs, BLOCKERS, WHAT I'M WORKING ON TODAY, DEMO LINKS. Keep it terse -- bullet points, not paragraphs.

**Rules:**
- Short and precise. No fluff, no filler words.
- Write as neutral facts or first-person actions.
- No AI fingerprints. Write like a human typed quick notes.

**On session start:** Read the next standup file (if it exists) to see what's already accumulated.

**File naming:** Use the date of the NEXT standup. Working Monday -> file for Tuesday. Working Friday -> file for Monday. Weekends accumulate into Monday's file.

## Code Routing (WHERE to make changes)

- **Feature work** -> feature branch: `git checkout -b feature/[your-name]-[feature-name] [base-branch]`
- **Hotfix** -> fix branch off main: `git checkout -b fix/[your-name]-[description] main`
- **With git worktrees** -> `git worktree add ../../worktrees/<name> -b feature/[your-name]-<name> [base-branch]`
- **NEVER edit `code/` directly when a worktree exists** for that feature

## Git Workflow

**Git Identity:**
- **Name:** [YOUR_NAME]
- **Email:** [YOUR_EMAIL]
- **GitHub:** [YOUR_GITHUB_USERNAME] (org: [ORG_NAME])

**Branch strategy:**
- `main` / `master` -- production
- `staging` -- integration/testing
- `qa` -- QA validation (if applicable)
- `feature/[your-name]-[feature-name]` -- feature branches
- `fix/[your-name]-[bug-description]` -- bug fixes

**Before every commit, push, or PR:**

1. **Review all changes** for secrets/key leaks, debug statements, unintended files
2. **Run linting/formatting** if configured
3. **Run tests** if they exist
4. **Write clean commit messages** -- Conventional Commits format
5. **No AI fingerprints** unless your team wants them

**CRITICAL: NEVER create a PR unless:**
1. The code has been **tested locally** (build passes, manual verification)
2. All changes have been **reviewed for quality**
3. You are confident the code is **production-ready**

**Commit messages** -- Conventional Commits:
```
<type>(<scope>): <description>

- file1 path - what was done and why
- file2 path - what was done and why
```

Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `chore`, `build`

## DB & Migrations

**Migration strategy:** [Alembic / Prisma / manual SQL / Flyway / etc.]

**Local DB:** [connection details]

**Staging DB:** [access method, credential location]

**Applying migrations:**
```bash
# Local
[your local migration command]

# Staging
[your staging migration command]
```

**Migration rules:**
- Check ALL open branches before picking a migration number (avoid collisions)
- Use idempotent patterns (`IF NOT EXISTS` / `IF EXISTS`) where possible
- Mention migration files explicitly in PR descriptions
- Apply migrations yourself if you have direct DB access

## Key Rules

1. **Read before editing** -- never overwrite files blindly
2. **Archive, never delete** -- move old files to `archive/`, don't delete them
3. **Session logs are append-only** -- never modify past sessions
4. **Cross-reference, don't duplicate** -- link between files instead of copying content
5. **STATUS.md is the living doc** -- update it every session with current state
6. **KNOWLEDGE.md is evergreen** -- only add things that won't change week-to-week
7. **When context is missing, read KNOWLEDGE.md** -- it likely has the answer

## Related Locations

| What | Where |
|------|-------|
| Session logs | `sessions/` |
| Architecture docs | `docs/architecture/` |
| Contract/comp docs | `internal/` |
| Project management | [Tool name + URL] |
| Meeting recordings | [Path or service] |

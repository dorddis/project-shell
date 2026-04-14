# [PROJECT_NAME] - KNOWLEDGE

Evergreen reference for the [PROJECT_NAME] product and [COMPANY]. This file contains information that doesn't change week-to-week -- architecture, decisions, how things work, business context. For current state and priorities, see `STATUS.md`.

---

## Company

**[COMPANY]** - [Brief description].
- Founder: [Name] ([Location])
- Founded: [Year]
- Funding: [Bootstrapped / Seed / Series A / etc.]
- Size: [Team size -- e.g., "6 people, all remote"]
- Also operates: [Other products/entities if applicable]

## Product: [PROJECT_NAME]

[2-3 sentences: what it does, who it's for, why it exists.]

### Core Features

<!-- List each major feature with enough detail that an AI can understand the domain. -->

#### [Feature 1 Name]
- [What it does -- user-facing description]
- [How it works -- technical summary]
- [Key files/services involved]
- **Known issues:** [Any bugs or limitations affecting development]

#### [Feature 2 Name]
- [What it does]
- [How it works]
- **Known issues:** [If any]

#### [Feature 3 Name]
- [What it does]
- [How it works]

### Planned Features

<!-- Features that have been discussed/designed but not built yet. Include enough context that you can pick them up later without losing the thread. -->

#### [Planned Feature Name] (Planned - [Date or timeframe])
- **Concept:** [What it is]
- **Owner:** [Who's building it]
- **Priority:** [After X is done / Q2 / deferred indefinitely]
- **Design notes:** [Any decisions already made]

## Target Market

- **Primary:** [Who -- e.g., "Indian diaspora in the US hosting cultural events"]
- **Secondary:** [If applicable]
- **Competitors:** [Name] ([what they do well / what they lack])
- **Differentiator:** [Why your product wins]

## Monetization

<!-- How does or will the product make money? -->

- **Current:** [e.g., "Free beta, no monetization yet"]
- **Planned:** [e.g., "Freemium with premium AI features, affiliate revenue"]
- **Pricing model:** [If exists]

---

## Tech Stack (Confirmed from Codebase)

<!-- Be specific -- version numbers, actual packages, not just framework names. This is what the AI uses to write correct code. -->

### Backend
- **Framework:** [e.g., FastAPI 0.104]
- **Language:** [e.g., Python 3.12]
- **Database:** [e.g., PostgreSQL 16]
- **ORM/Query:** [e.g., SQLAlchemy 2.0 with async, raw SQL for complex queries]
- **Auth:** [e.g., JWT (python-jose) + session-based registration flow]
- **API style:** [e.g., REST, single main.py monolith, no versioning]
- **Key packages:** [List important ones -- e.g., "httpx, pydantic, celery, redis"]
- **Hosting:** [e.g., AWS EC2 t3.medium, Docker, GitHub Actions CI/CD]

### Frontend
- **Framework:** [e.g., Next.js 14 (App Router)]
- **Language:** [e.g., TypeScript 5.3]
- **State management:** [e.g., Redux Toolkit + RTK Query]
- **Styling:** [e.g., Tailwind CSS 3.4 + custom design tokens]
- **Key packages:** [List important ones -- e.g., "next-auth, framer-motion, react-hook-form"]
- **Hosting:** [e.g., Vercel, or EC2 behind CloudFront]

### Infrastructure
- **Cloud:** [e.g., AWS us-west-1]
- **CI/CD:** [e.g., GitHub Actions -- build + deploy on push to staging/production]
- **CDN:** [e.g., CloudFront with S3 origin for static assets]
- **Monitoring:** [e.g., CloudWatch logs + Sentry for frontend errors]
- **DNS:** [e.g., Route53]
- **Secrets:** [e.g., AWS Secrets Manager for DB creds, .env for local]

---

## Backend Architecture

<!-- Describe the actual codebase structure, not the ideal. This is reference for the AI to write correct code. -->

### Directory Structure
```
[backend-repo]/
├── main.py                # [e.g., FastAPI app entry point, all routes]
├── app/
│   ├── models/            # [e.g., SQLAlchemy models]
│   ├── services/          # [e.g., Business logic]
│   ├── routes/            # [e.g., API route handlers]
│   └── utils/             # [e.g., Helpers, prompts, validators]
├── database/
│   └── migrations/        # [e.g., Sequential SQL files]
└── tests/
```

### Key Patterns
- [e.g., "All routes in main.py (monolith -- no router separation yet)"]
- [e.g., "Models use SQLAlchemy declarative base, async sessions"]
- [e.g., "No dependency injection -- services instantiated directly"]
- [e.g., "Error handling: bare try/except in many places (known tech debt)"]

### Key Files
- `[file]` -- [what it does, why it matters -- e.g., "main.py (17K lines, contains all routes -- god file, refactor planned)"]
- `[file]` -- [what it does]

## Frontend Architecture

### Directory Structure
```
[frontend-repo]/
├── src/
│   ├── app/               # [e.g., Next.js App Router pages]
│   ├── components/        # [e.g., Shared UI components]
│   ├── store/             # [e.g., Redux slices]
│   ├── services/          # [e.g., API client functions]
│   └── utils/             # [e.g., Helpers, constants]
├── public/
└── tests/
```

### Key Patterns
- [e.g., "App Router with server components where possible"]
- [e.g., "Auth via next-auth with custom credential provider"]
- [e.g., "Global state in Redux, server state via RTK Query"]

### Key Files
- `[file]` -- [what it does]
- `[file]` -- [what it does]

---

## Local Development Setup

### Prerequisites
- [Language runtime + version -- e.g., "Python 3.12, Node.js 20"]
- [Database -- e.g., "PostgreSQL 16 running on localhost:5432"]
- [Other -- e.g., "Redis 7 for background jobs"]

### Backend Setup
```bash
cd code/[backend-repo]
[create virtual env command]
[install deps command]
[copy env file command]
[run migrations command]
[start server command]
```

### Frontend Setup
```bash
cd code/[frontend-repo]
[install deps command]
[copy env file command]
[start dev server command]
```

### Common Gotchas
- [e.g., "Frontend .env.local must use `localhost` not `127.0.0.1` for same-site cookies"]
- [e.g., "Backend .env points to LOCAL DB only -- never use these creds for staging"]
- [e.g., "Missing X column on Y table causes 401s -- run latest migrations"]

---

## Environments

| Environment | URL | Database | Branch | Deploy method | Notes |
|-------------|-----|----------|--------|---------------|-------|
| Local | localhost:[PORT] | [local db name] | any | manual | Dev machine |
| Staging | [URL] | [staging db] | staging | [auto/manual] | [who has access, how to deploy] |
| QA | [URL] | [qa db] | qa | [auto/manual] | [if you have a QA env] |
| Production | [URL] | [prod db] | main/production | [auto/manual] | [who deploys, any gates] |

---

## Key Decisions

<!-- Document important architectural and product decisions with context. These are the "why" behind the code. Add new decisions as subsections. -->

### [Decision Title] ([Date])

**Decision:** [What was decided]
**Context:** [Why -- what problem were you solving, what constraints existed]
**Alternatives considered:** [What else was on the table and why it was rejected]
**Consequences:** [What this means for future development -- tradeoffs accepted]

### [Decision Title 2] ([Date])

**Decision:** [What was decided]
**Context:** [Why]

---

## Vendor / External Team Dynamics

<!-- If you work with external vendors, contractors, or partner teams, document the relationship dynamics here. This is critical context for the AI to understand communication patterns and approval flows. -->

### [Vendor/Team Name]

- **What they do:** [e.g., "External dev shop, handles DevOps and some backend features"]
- **Communication channel:** [e.g., "Dedicated project management tool threads only, not Slack or email"]
- **Who controls what:** [e.g., "They admin GitHub, AWS console, CI/CD pipelines"]
- **PR flow:** [e.g., "They merge their own PRs. Internal team sends PRs for review first."]
- **Known friction:** [e.g., "They've merged PRs without running DB migrations -- always mention migration files explicitly"]
- **Timeline:** [e.g., "Keeping them until prepaid features are complete, then transitioning"]

---

## Security Considerations

<!-- Things the AI should know when writing code for this project. -->

- [e.g., "Always validate user input on backend, never trust frontend validation alone"]
- [e.g., "Use parameterized queries -- never string concatenation for SQL"]
- [e.g., "Secrets in AWS Secrets Manager, never in .env for non-local environments"]
- [e.g., "CORS configured for specific origins only, not wildcard"]
- [e.g., "Known: rate limiting only on auth endpoints, needs expansion to all API routes"]

### Known Security Issues (Being Tracked)

| Issue | Severity | Status | Tracking |
|-------|----------|--------|----------|
| [Description] | [Critical/High/Medium/Low] | [Open/In Progress/Fixed] | [PR/Issue link] |

---

## Business Context

<!-- Non-technical context that affects development priorities. -->

- **Business model:** [How the product makes money or plans to]
- **Key metrics:** [What the team optimizes for -- e.g., "user signups, event creation rate"]
- **Regulatory:** [Compliance requirements -- GDPR, SOC2, HIPAA, PCI-DSS, etc.]
- **Investors/stakeholders:** [Who has influence on priorities]

---

## Hiring / Team Growth (if applicable)

<!-- Track hiring context that affects your work. Remove if not relevant. -->

| Role | Status | Notes |
|------|--------|-------|
| [Role being hired] | [Interviewing / Offered / Filled / On hold] | [Key context] |

# Project Shell -- Setup Guide

A structured project management system for AI-assisted software development. Works with any agentic coding tool (GitHub Copilot, Cursor, Claude Code, Windsurf, Aider, Cline, Amazon Q, Continue.dev).

This template gives your AI assistant persistent context across sessions: what the project is, what you're working on, what decisions have been made, and how to wrap up work properly.

## What You Get

| File | Purpose | Update frequency |
|------|---------|-----------------|
| `AGENTS.md` | Universal AI context file (cross-tool) | When project fundamentals change |
| `CLAUDE.md` | Claude Code specific context (richer) | When project fundamentals change |
| `STATUS.md` | Current priorities, blockers, action items | Every session (living doc) |
| `KNOWLEDGE.md` | Evergreen reference (architecture, decisions, how things work) | When new info arrives |
| `SESSION_INDEX.md` | Searchable index of all past sessions | Auto-updated on wrap |
| `sessions/` | Point-in-time session logs with YAML frontmatter | One per session |
| `docs/standups/` | Daily standup prep (auto-accumulated) | Throughout each session |
| `docs/reviews/` | Code review outputs with status tracking | Per review |
| `workflows/wrap.md` | Session wrap-up workflow (tool-agnostic) | Rarely |
| `archive/` | Old/completed work (nothing gets deleted) | When things are done |

## Quick Start (15 minutes)

### Step 1: Copy the template

Copy this entire `project-shell-template/` folder to your project root. Rename it or merge it into your existing structure.

```bash
cp -r project-shell-template/ ~/my-project/
cd ~/my-project/
```

### Step 2: Customize AGENTS.md

Open `AGENTS.md` and fill in the placeholders:

- `[PROJECT_NAME]` -- your project name
- `[PRODUCT_DESCRIPTION]` -- one-line description
- `[YOUR_NAME]` -- your name
- `[YOUR_ROLE]` -- your role (e.g., "Senior Backend Engineer")
- `[COMPANY]` -- your company name
- Team table -- fill in your team members
- Tech stack -- fill in your actual stack
- Folder structure -- adjust to match your repo layout

### Step 3: Set up tool-specific config

Pick your tool(s) and copy the appropriate config file:

**GitHub Copilot:**
```bash
# Context instructions (repo-wide)
mkdir -p .github
cp tool-configs/copilot-instructions.md .github/copilot-instructions.md

# Prompt files (slash commands: /wrap, /commit, /review, etc.)
mkdir -p .github/prompts
cp copilot-prompts/*.prompt.md .github/prompts/
```

**Cursor:**
```bash
mkdir -p .cursor/rules
cp tool-configs/cursor-rules.mdc .cursor/rules/project.mdc
```

**Claude Code:**
Already done -- Claude Code reads `CLAUDE.md` from project root automatically.

**Windsurf:**
```bash
mkdir -p .windsurf/rules
cp tool-configs/windsurf-rules.md .windsurf/rules/project.md
```

**Cline / Roo Code:**
```bash
mkdir -p .clinerules
cp tool-configs/clinerules.md .clinerules/project.md
```

**Aider:**
```bash
cp tool-configs/aider.conf.yml .aider.conf.yml
```

**Amazon Q:**
```bash
mkdir -p .amazonq/rules
cp tool-configs/amazonq-rules.md .amazonq/rules/project.md
```

**Continue.dev:**
```bash
cp tool-configs/continuerules .continuerules
```

### Step 4: Initialize STATUS.md and KNOWLEDGE.md

Open `STATUS.md` and write your current priorities. Even just 3-5 bullet points is enough to start. The AI will help maintain it going forward.

Open `KNOWLEDGE.md` and add any important reference info: architecture decisions, environment setup, key URLs, API docs links, etc.

### Step 5: Set up .gitignore

Add to your `.gitignore`:
```
# AI tool configs with potential secrets
.env
CLAUDE.local.md

# Tool-specific (optional -- commit these if you want team-wide rules)
# .cursor/
# .windsurf/
# .github/copilot-instructions.md
```

**Recommendation:** Commit `AGENTS.md`, `CLAUDE.md`, `STATUS.md`, `KNOWLEDGE.md`, and `sessions/` to git. This gives your future self (and teammates) full context history.

## How It Works

### The 3-Tier Context System

Your AI assistant reads context from three files, each serving a different purpose:

```
STATUS.md       -- "What's happening NOW" (changes daily)
KNOWLEDGE.md    -- "How things WORK" (changes when you learn something new)  
AGENTS.md       -- "WHO I am and HOW I work" (changes when project fundamentals shift)
```

**Rule of thumb:** If you're unsure where something goes:
- Is it about current state, blockers, or action items? -> `STATUS.md`
- Is it a decision, architecture detail, or reference info? -> `KNOWLEDGE.md`
- Is it about the project identity, team, or workflow? -> `AGENTS.md`

### Session Lifecycle

Each work session follows this pattern:

1. **Start:** AI reads `STATUS.md` to understand current state
2. **Work:** You code, discuss, make decisions
3. **Wrap:** Run the wrap workflow (see `workflows/wrap.md`)
   - Updates `STATUS.md` with new state
   - Creates a session log in `sessions/`
   - Updates `SESSION_INDEX.md`
   - Commits everything

### Session Logs

Each session creates a log file with YAML frontmatter for searchability:

```yaml
---
wrap_id: 2026-04-14_auth-refactor
date: 2026-04-14
project: my-project
tags: [auth, refactor, security]
summary: Refactored auth middleware to use JWT rotation
status: closed
related: []
---
```

Tags create a knowledge graph. When you ask "what did we decide about auth?", the AI can search `SESSION_INDEX.md` by tag and fetch the relevant session.

### Standup Auto-Accumulation

Throughout a session, noteworthy items (PRs merged, blockers found, decisions made) get appended to `docs/standups/YYYY-MM-DD.txt`. By end of day, your standup notes are already written.

### The Wrap Workflow

The wrap workflow (`workflows/wrap.md`) is a structured prompt you can give to any AI tool at end of session. It:

1. Scans the conversation for decisions, status changes, open items
2. Updates `STATUS.md` (adds new items, marks completed ones)
3. Creates a session log with frontmatter
4. Updates `SESSION_INDEX.md`
5. Commits context files separately from code changes

**For Claude Code:** Copy `workflows/wrap.md` to your Claude commands directory:
```bash
# Global command (all projects)
cp workflows/wrap.md ~/.claude/commands/wrap.md

# Or project-specific
mkdir -p .claude/commands
cp workflows/wrap.md .claude/commands/wrap.md
```
Then invoke with `/wrap [session-name]`.

**For other tools:** Paste the contents of `workflows/wrap.md` as a prompt at end of session, or set it up as a saved prompt/snippet in your tool.

### Claude Code: 6-Agent Review + Commit Skills

The `claude-code/` folder contains a full multi-agent code review system and a commit workflow, built for Claude Code's Agent tool. This is the most powerful part of the template -- 6 specialist agents review your code in parallel like a senior dev team.

**Setup:**
```bash
# Copy agent definitions (global -- works across all projects)
mkdir -p ~/.claude/agents
cp claude-code/agents/review-*.md ~/.claude/agents/

# Copy skills (project-specific)
mkdir -p .claude/skills/review .claude/skills/commit
cp claude-code/skills/review/SKILL.md .claude/skills/review/
cp claude-code/skills/commit/SKILL.md .claude/skills/commit/
```

**Usage:**
- `/commit` -- stages, builds, reviews, and commits with a clean message
- `/review` -- launches 6 parallel agents (build, security, logic, quality, conflicts, gaps), then synthesizes a master report

**The 6 review agents:**
| Agent | What it checks |
|-------|---------------|
| `review-build` | Compilation, linting, type-checking, dependency health |
| `review-security` | Secrets, injection, OWASP Top 10, auth bypass, XSS |
| `review-logic` | Bugs, edge cases, race conditions, null access, type lies |
| `review-quality` | Naming, structure, duplication, complexity, conventions |
| `review-conflicts` | Merge conflicts, branch overlap, migration gaps, deploy risks |
| `review-gaps` | Missing pieces, dead code, error handling, UX gaps, test gaps |

Reports go to `docs/reviews/YYYY-MM-DD_<slug>-<agent>.md` with a master summary.

### GitHub Copilot: Prompt Files for Review, Commit, and Wrap

Copilot uses **Prompt Files** (`.prompt.md` in `.github/prompts/`) as reusable slash commands in Copilot Chat and Agent Mode. The `copilot-prompts/` folder contains Copilot-native versions of the same workflows.

**Setup:**
```bash
mkdir -p .github/prompts
cp copilot-prompts/*.prompt.md .github/prompts/
```

**Available prompts (invoke in Copilot Chat):**

| Command | What it does |
|---------|-------------|
| `/review` | Full 6-area code review (build, security, logic, quality, conflicts, gaps) |
| `/review-security` | Targeted security review (OWASP Top 10, secrets, injection) |
| `/review-logic` | Targeted logic review (bugs, edge cases, race conditions) |
| `/commit` | Build verification + staged commit with conventional message |
| `/wrap` | End-of-session: update STATUS.md, create session log, commit context |

**How it compares to Claude Code:**

| Capability | Claude Code | GitHub Copilot |
|-----------|-------------|----------------|
| Context file | `CLAUDE.md` (auto-loaded) | `.github/copilot-instructions.md` (auto-loaded) |
| Universal context | `AGENTS.md` (also read) | `AGENTS.md` (also read) |
| Slash commands | `.claude/skills/*/SKILL.md` | `.github/prompts/*.prompt.md` |
| Multi-agent review | 6 parallel agents, master report | Single-pass comprehensive review |
| Scoped rules | `.claude/rules/*.md` with path globs | `.instructions.md` files with `applyTo` globs |
| Personal overrides | `CLAUDE.local.md` (gitignored) | VS Code settings (user-level instructions) |

**Key differences:**

1. **No parallel agents.** Copilot runs one model at a time. The `/review` prompt compensates by packing all 6 checklists into one comprehensive pass. For deeper reviews, run the targeted prompts (`/review-security`, `/review-logic`) individually.

2. **Prompt files need `applyTo` for auto-triggering.** Without `applyTo` frontmatter, prompts are only invoked manually via `/name`. This is fine for review/commit/wrap -- you want those manual anyway.

3. **Path-scoped instructions.** If you want Copilot to automatically apply different rules for different parts of the codebase, create `.instructions.md` files:
   ```markdown
   ---
   name: 'Backend conventions'
   description: 'Python/FastAPI patterns for backend code'
   applyTo: 'backend/**/*.py'
   ---
   Use async/await for all endpoint handlers.
   Use SQLAlchemy ORM for queries, never raw SQL.
   Standard response format: {"data": ..., "error": false, "message": "...", "status": 200}
   ```
   Place these in `.github/instructions/` or anywhere in the workspace.

4. **Organization-level instructions.** If your team uses GitHub org settings, an admin can set default instructions that apply across all repos (GitHub.com > Org settings > Copilot > Custom instructions). This is the equivalent of Claude Code's `~/.claude/CLAUDE.md`.

**Recommended Copilot setup (complete):**
```
.github/
├── copilot-instructions.md          # Repo-wide context (from tool-configs/)
├── prompts/
│   ├── wrap.prompt.md               # /wrap - session wrap-up
│   ├── commit.prompt.md             # /commit - build + commit
│   ├── review.prompt.md             # /review - full 6-area review
│   ├── review-security.prompt.md    # /review-security - targeted
│   └── review-logic.prompt.md       # /review-logic - targeted
└── instructions/                    # (optional) path-scoped rules
    ├── backend.instructions.md      # applyTo: 'backend/**/*.py'
    └── frontend.instructions.md     # applyTo: 'frontend/**/*.tsx'
```

## Cross-Tool Compatibility Reference

### Context File Names by Tool

| Tool | Root file | Rules directory | File extension |
|------|-----------|-----------------|----------------|
| **GitHub Copilot** | `.github/copilot-instructions.md` | `.github/instructions/` | `.instructions.md` |
| **Cursor** | `.cursorrules` (legacy) | `.cursor/rules/` | `.mdc` |
| **Claude Code** | `CLAUDE.md` | `.claude/rules/` | `.md` |
| **Windsurf** | `.windsurfrules` (legacy) | `.windsurf/rules/` | `.md` |
| **Aider** | `CONVENTIONS.md` (manual load) | -- | `.md` |
| **Continue.dev** | `.continuerules` | -- | plain text |
| **Amazon Q** | -- | `.amazonq/rules/` | `.md` |
| **Cline** | `.clinerules` | `.clinerules/` | `.md` |
| **Roo Code** | `.roorules` | `.roo/rules/` | `.md` |
| **Universal** | `AGENTS.md` | -- | `.md` |

### Which Tools Read AGENTS.md?

`AGENTS.md` is the emerging universal standard (Linux Foundation / Agentic AI Foundation). As of April 2026:
- **Reads it:** GitHub Copilot, Cursor, Windsurf, OpenAI Codex, Gemini CLI
- **Reads if present:** Claude Code (but prioritizes `CLAUDE.md`)
- **Does not read it:** Aider, Continue.dev, Amazon Q, Cline, Roo Code

### Recommended Multi-Tool Strategy

1. **Write your canonical context in `AGENTS.md`** -- this is the universal file
2. **Keep `CLAUDE.md` for Claude Code** -- it supports richer instructions
3. **Copy key sections to tool-specific configs** as needed (see `tool-configs/`)
4. **Don't over-duplicate** -- maintain one source of truth, reference it from tool configs

### Character Limits

| Tool | Limit |
|------|-------|
| Cursor | ~2,000 words per rule recommended |
| Windsurf | 6,000 chars per rule, 12,000 chars total active |
| Others | No hard limits (but shorter = better attention) |

## Folder Structure Reference

```
your-project/
├── AGENTS.md              # Universal AI context (cross-tool)
├── CLAUDE.md              # Claude Code context (richer, optional)
├── STATUS.md              # Current state (living doc)
├── KNOWLEDGE.md           # Evergreen reference
├── SESSION_INDEX.md       # Session discovery index
│
├── sessions/              # Session logs (append-only)
│   └── YYYY-MM-DD_session-name.md
│
├── docs/                  # Non-code artifacts
│   ├── standups/          # Daily standup prep
│   ├── reviews/           # Code review outputs
│   ├── research/          # Research, analysis
│   └── architecture/      # ADRs, design docs
│
├── workflows/             # Reusable AI workflows
│   └── wrap.md            # Session wrap-up workflow
│
├── tool-configs/          # Tool-specific config templates (copy to correct location)
│   ├── copilot-instructions.md
│   ├── cursor-rules.mdc
│   ├── windsurf-rules.md
│   ├── clinerules.md
│   ├── aider.conf.yml
│   ├── amazonq-rules.md
│   └── continuerules
│
├── claude-code/           # Claude Code specific (agents + skills)
│   ├── agents/            # 6 review agent definitions
│   │   ├── review-build.md
│   │   ├── review-security.md
│   │   ├── review-logic.md
│   │   ├── review-quality.md
│   │   ├── review-conflicts.md
│   │   └── review-gaps.md
│   └── skills/            # Slash command skills
│       ├── review/SKILL.md   # /review orchestrator (6 parallel agents)
│       └── commit/SKILL.md   # /commit workflow
│
├── copilot-prompts/       # GitHub Copilot prompt files (copy to .github/prompts/)
│   ├── wrap.prompt.md        # /wrap - session wrap-up
│   ├── commit.prompt.md      # /commit - build + commit
│   ├── review.prompt.md      # /review - comprehensive 6-area review
│   ├── review-security.prompt.md  # /review-security - targeted
│   └── review-logic.prompt.md     # /review-logic - targeted
│
├── archive/               # Old/completed work (never delete, always archive)
│
└── code/                  # Your actual code repos (if wrapper project)
    ├── backend/
    └── frontend/
```

## Tips

- **Start small.** Fill in AGENTS.md and STATUS.md. Everything else can grow organically.
- **Let the AI maintain STATUS.md.** After each session, ask it to update the file. It gets better at this over time.
- **Use tags consistently.** Pick 10-20 tags and reuse them across sessions. Consistent tags make search work.
- **Archive, never delete.** Move old stuff to `archive/`. You'll thank yourself when you need context from 3 months ago.
- **Wrap every session.** The 2 minutes spent wrapping saves 20 minutes of context-rebuilding next time.
- **Keep KNOWLEDGE.md lean.** Only add things that are hard to derive from the code itself. Architecture decisions, business context, vendor dynamics -- not code patterns.

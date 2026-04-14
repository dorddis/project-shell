# Project Context

This project uses a structured context system. Key files:

- **STATUS.md** - Current priorities, blockers, action items (living doc, changes daily)
- **KNOWLEDGE.md** - Evergreen reference: architecture, decisions, tech stack
- **AGENTS.md** - Project identity, team, workflow

## Before Starting Work

1. Read `STATUS.md` first 30 lines for current state
2. Read `AGENTS.md` for project overview and team context
3. Check `KNOWLEDGE.md` before asking questions

## Workflow Rules

- Update `STATUS.md` at end of every session
- Append standup-worthy items to `docs/standups/YYYY-MM-DD.txt`
- Create session logs in `sessions/` with YAML frontmatter
- Archive old work to `archive/`, never delete files

## Code Standards

- Conventional Commits: `type(scope): description`
- Check for secrets and debug statements before committing
- Follow existing patterns in the codebase

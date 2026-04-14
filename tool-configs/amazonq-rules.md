# Project Context and Coding Standards

## Priority: High

## Purpose

Ensure AI assistant reads project context files and follows established workflow.

## Instructions

This project uses a structured context system:

- **STATUS.md** - Current priorities, blockers, action items (living doc)
- **KNOWLEDGE.md** - Evergreen reference: architecture, decisions, tech stack
- **AGENTS.md** - Project identity, team, workflow

### Before Starting Work

1. Read `STATUS.md` for current state
2. Read `AGENTS.md` for project overview
3. Check `KNOWLEDGE.md` before asking questions the docs might answer

### Workflow

- Update `STATUS.md` at end of every session
- Create session logs in `sessions/` with YAML frontmatter
- Archive old work to `archive/`, never delete files
- Use Conventional Commits: `type(scope): description`

### Code Quality

- Check for secrets and debug statements before committing
- Follow existing patterns in the codebase
- Read files before editing them
- Write tests for new functionality

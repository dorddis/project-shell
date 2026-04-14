# GitHub Copilot Instructions

Copy this file to `.github/copilot-instructions.md` in your project root.

## Project Context

This project uses a structured context system. Before starting work:

1. Read `STATUS.md` for current priorities and blockers
2. Read `AGENTS.md` for project overview, team, and workflow
3. Read `KNOWLEDGE.md` for architecture and technical decisions (on demand)

## Workflow

- Track current work in `STATUS.md` (update every session)
- Log completed sessions in `sessions/` with YAML frontmatter
- Append standup items to `docs/standups/YYYY-MM-DD.txt` throughout work
- Archive old work to `archive/`, never delete files

## Code Standards

- Use Conventional Commits: `type(scope): description`
- Review changes for secrets, debug statements, and unintended files before committing
- Write tests for new functionality
- Follow existing code patterns and conventions in the repo

## File Routing

- Current state and priorities -> `STATUS.md`
- Evergreen reference and decisions -> `KNOWLEDGE.md`
- Research and analysis -> `docs/<subfolder>/`
- Session logs -> `sessions/YYYY-MM-DD_name.md`
- Standup notes -> `docs/standups/YYYY-MM-DD.txt`

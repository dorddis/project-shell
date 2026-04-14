# [PROJECT_NAME] - STATUS

**Last updated:** [DATE] ([brief summary of latest changes])

## Current Focus

<!-- What are you working on RIGHT NOW? 2-3 bullet points max. This is the first thing the AI reads each session. -->

- [ ] [Priority 1 -- what and why]
- [ ] [Priority 2 -- what and why]
- [ ] [Priority 3 -- what and why]

## Launch / Release Timeline (if applicable)

<!-- Remove this section if you don't have a specific timeline. Otherwise track key dates and milestones. -->

**[Milestone]: [Date]. [Next milestone]: [Date].**

[1-2 sentences summarizing where things stand relative to timeline.]

## Deployment Checklist (if applicable)

<!-- Use this for tracking multi-step deployments, releases, or migrations. Remove if not needed. Check off as you go. -->

### Phase 0: Pre-Requisites
- [ ] [Pre-req 1 -- what needs to happen, who owns it]
- [ ] [Pre-req 2]

### Phase 1: [Phase Name]
- [ ] [Step 1 -- what, who, dependencies]
- [ ] [Step 2]
- [ ] [Step 3]

### Phase 2: [Phase Name]
- [ ] [Step 1]
- [ ] [Step 2]

### Known Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| [What could go wrong] | [What breaks if it does] | [How to prevent or recover] |

## Active Work

<!-- Track each active workstream as its own subsection. This is the meat of STATUS.md. -->

### [Feature/Task Name]

**Status:** in-progress
**Branch:** `feature/[your-name]-[feature-name]`
**PR:** #[number] ([repo])

- [x] [Completed step]
- [x] [Completed step]
- [ ] [Remaining step]
- [ ] [Remaining step]
- **Blocker:** [if any -- what's blocking, who it's waiting on]

### [Feature/Task Name 2]

**Status:** waiting-review
**Branch:** `feature/[branch-name]`
**PR:** #[number]

- [What was submitted]
- **Waiting on:** [Person] to review

### [Feature/Task Name 3]

**Status:** blocked
**Branch:** `fix/[branch-name]`

- [What's done]
- **Blocked by:** [Description -- e.g., "need access to prod DB", "waiting on design from designer"]
- **Since:** [Date]

## Blockers

<!-- Active blockers that are preventing progress on something. Remove when resolved. -->

| Blocker | Waiting on | Since | Impact |
|---------|-----------|-------|--------|
| [Description] | [Person/team] | [Date] | [What feature/task it blocks] |
| [Description] | [Person/team] | [Date] | [What it blocks] |

## Open PRs (verified from GitHub [DATE])

<!-- Keep this up to date. Run `gh pr list` to verify. Mark status accurately. -->

| Repo | PR | Description | Status | Notes |
|------|----|-------------|--------|-------|
| [backend] | #[num] | [description] | awaiting review | [who should review] |
| [frontend] | #[num] | [description] | changes requested | [what needs fixing] |
| [backend] | #[num] | [description] | approved, ready to merge | [waiting on CI / manual merge] |

## Recently Completed

<!-- Move items here when done. Archive this section periodically (move to archive/ when it gets long). -->

- [x] [Completed item] -- [date]. [PR #num merged / deployed / etc.]
- [x] [Completed item] -- [date]
- [x] [Completed item] -- [date]

## Key Decisions (Recent)

<!-- Decisions made recently that affect current work. Move to KNOWLEDGE.md when they become evergreen reference. -->

| Decision | Date | Context |
|----------|------|---------|
| [What was decided] | [Date] | [Why -- who was involved, what drove the decision] |
| [What was decided] | [Date] | [Why] |

## Upcoming

<!-- What's next after current focus is done? Not a full backlog -- just the next 1-2 things you'll pick up. -->

- [Next priority 1 -- brief description]
- [Next priority 2 -- brief description]

## Testing Infrastructure (if applicable)

<!-- Track what testing exists and what's missing. Remove if not relevant to your project. -->

- **Backend:** [framework + count -- e.g., "pytest, 47 tests committed on staging"]
- **Frontend:** [framework + count -- e.g., "Vitest, 22 unit tests + 26 Playwright E2E"]
- **CI:** [status -- e.g., "GitHub Actions workflows for all 3 repos, trigger on PR to staging"]
- **Gaps:** [what's not tested yet]

## Carried Forward

<!-- Items from previous sprints/cycles that are still relevant. Review periodically -- archive if stale. -->

- [Item still in play -- why it's still here]
- [Item still in play]

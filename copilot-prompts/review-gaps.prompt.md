---
name: 'review-gaps'
description: 'Gap analysis: missing pieces, dead code, untested paths, UX gaps, production risks'
---

You are a tech lead doing a final review before a PR ships. You ask: "What did the developer forget? What's incomplete? What will break in production that works in dev?"

Get the diff: `git diff origin/main...HEAD -- . ':(exclude)package-lock.json'`

Think like a user, not a developer.

## Checklist

### Completeness
- Does the implementation match what the PR/branch description says?
- Are there TODO/FIXME/HACK comments in the new code?
- Are there placeholder values or hardcoded test data?
- Are loading states handled? Empty states? Error states?
- Is the feature complete end-to-end, or does it depend on unmerged work?

### Dead Code & Cleanup
- Unused imports (especially after refactoring)
- Unreachable code blocks
- Commented-out code that should be removed
- Console.log / print statements left in
- Unused variables, functions, or components
- **Duplicate components:** Does a similar component already exist elsewhere in the codebase?

### Error Handling Gaps
- API calls without error handling (no try/catch, no .catch())
- User-facing errors showing raw technical messages
- Network timeout handling
- 401/403 handling (token expiry, unauthorized access)
- Form validation gaps (client-side but not server-side, or vice versa)

### UX Gaps
- Loading indicators missing during async operations
- No feedback after user actions (submit, delete, update)
- Buttons not disabled during processing (double-submit risk)
- Missing responsive behavior (mobile vs desktop)
- Text truncation without tooltips on overflow
- **Accessibility:** Missing aria labels, keyboard navigation, screen reader support

### Testing Gaps
- What test would you write first for this code?
- What's the riskiest untested path?
- Are there integration points that could break silently?

### Production vs Dev Differences
- Hardcoded localhost URLs
- Development-only env vars that won't exist in production
- Features that work with test data but fail with real data
- CORS or cookie settings that differ between dev and staging/prod

## Output

Save report to `docs/reviews/[DATE]_[description]-gaps.md`:

```markdown
## Gap Analysis

**Verdict:** COMPLETE / GAPS FOUND / INCOMPLETE

### Missing Pieces
| # | Priority | What's Missing | Where | Impact if Shipped |
|---|----------|----------------|-------|-------------------|

### Dead Code / Cleanup
| # | File:Line | Issue | Action |
|---|-----------|-------|--------|

### Error Handling Gaps
| # | File:Line | Scenario | What Happens Now | Should Happen |
|---|-----------|----------|------------------|---------------|

### Production Risks
| # | Risk | Dev Behavior | Prod Behavior | Fix |
|---|------|-------------|---------------|-----|

### Suggested Tests (top 3 most valuable)
1. ...
2. ...
3. ...
```

Think like a user, not a developer. What will go wrong the first time someone uses this feature?

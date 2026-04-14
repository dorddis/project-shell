# Code Reviews

Agent-generated code review outputs. Each file represents one review pass.

## Status Legend

| Status | Meaning |
|--------|---------|
| `done` | All findings addressed |
| `partial` | Some fixed, others deferred |
| `in-progress` | Branch still being worked |
| `pending` | Awaiting someone's decision |
| `reference` | Informational only |

## File Format

```yaml
---
status: done
---
```

Followed by: Overall Assessment, Critical Issues (must fix), High/Medium/Low findings with file paths and suggested fixes.

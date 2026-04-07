# Run Log

> Records what this run tried to solve, what it actually did, and what tangible result it produced.
>
> This is cross-issue run history; it does not replace `.agent-workflow/docs/plan/archive/*.md`.

## Maintenance Rules

1. On each startup or continuation of the same run, reuse the latest entry whose `Status` is `in_progress`; create a new entry only when the previous one has ended (`done` / `blocked` / `failed`).
2. Stage 2 is responsible for clarifying what this run is trying to solve, at minimum the active issue or blocker.
3. Stage 4 and Stage 6 continuously append what was done and what real outcomes were produced.
4. If the run stops because of a blocker, failure, human handoff, or no safe next task, the entry must be completed with `End Time`, `Status`, and `Actual Result`.
5. Prefer concrete facts over vague summaries; results should prioritize verifiable artifacts such as commits, PRs, test results, or handoff notes.

## Entry Template

```markdown
## RUN-YYYYMMDD-HHMMSSZ

- Start Time: YYYY-MM-DDTHH:MM:SSZ
- End Time:
- Status: in_progress
- Goal:
  - To be clarified in Stage 2
- Work Performed:
  - To be appended by later stages
- Actual Result:
  - To be appended by later stages
```

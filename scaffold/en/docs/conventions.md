# Conventions

> This document answers: What does code look like? How are git operations handled?
>
> Inclusion criteria: Only style-based constraints that **rely on agent self-discipline** belong here. Structural rules mechanically enforced by a linter or CI belong in `architecture.md`.

## Naming Conventions (to be filled)

- File names: `kebab-case` / `snake_case` (pick one and be consistent)
- Class names: `PascalCase`
- Variables and functions: `camelCase` or `snake_case` (follow language idiom)
- Constants: `UPPER_SNAKE_CASE`

## Function Contract (to be filled)

1. Function inputs and outputs must be predictable; error paths must be testable.
2. Public functions must declare parameters, return values, and exception semantics.
3. Implicit global state mutation is forbidden.

## Error Handling Pattern (to be filled)

- Error representation: (exceptions / Result type / error codes)
- Log level conventions:
- Retry strategy:

## Git Conventions (to be filled)

### Commit Message

- Format: `<type>(<scope>): <subject>`
- Type enum: `feat / fix / refactor / docs / test / chore`
- Subject language: (Chinese / English)

### Branch Naming

- Default format: `codex/<issue_id>`
- Example: `codex/42-add-user-auth`
- Teams may substitute their own prefix for `codex`, but must keep the one-issue-one-branch rule

### Delivery Record Convention

- The archive's delivery summary must include at least the local commit hash, verification conclusion, and the next human step when needed
- If there is security or release risk, it must be written in the archive or handoff record

## Experiment Result Convention

- If the current issue runs experiments, evaluations, or smoke tests, the canonical result directory is `results/issue<issue_id>/`
- Example directory: `results/issue1-smoke-test/`
- This directory must contain `results/issue<issue_id>/SUMMARY.md`
- After each experiment, append one section to `SUMMARY.md` with at least:
  - Experiment name / time
  - Goal or hypothesis
  - Model and key settings
  - Workflow / pipeline
  - Key input conditions such as input length, batch size, seed, and data slice
  - Command, environment, hardware, or scheduler information
  - Raw log / artifact paths
  - Primary result and metrics
  - Attempted analysis of the result, including failed or inconclusive outcomes
- Multiple experiments from the same issue may share one `SUMMARY.md`; raw logs, plots, JSON, CSV, and other artifacts should live in the same directory or its subdirectories

## Maintenance Rules

1. When style conflicts arise, this document takes precedence.
2. Add a new pattern here before rolling it out.
3. Once a rule is enforced by a linter, migrate it to `architecture.md`.

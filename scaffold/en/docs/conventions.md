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
- After one issue is finished, `stage.lock` has returned to `stage1/done/previous=stage6`, and the working tree is clean, the next issue may branch directly from the current HEAD without first switching back to the default branch
- If the team requires every new issue to restart from the default branch, write that rule explicitly here and follow it

### Delivery Record Convention

- The archive's delivery summary must include at least the local commit hash, verification conclusion, and the next human step when needed
- If there is security or release risk, it must be written in the archive or handoff record

## Experiment Result Convention

- Only issues that **actually execute result-producing experiments, evaluations, benchmarks, or exploratory smoke tests** need a result directory: `results/issue<issue_id>/`
- Example directory: `results/issue1-smoke-test/`
- If an experiment was only planned but never actually executed, do not create a placeholder directory or empty `SUMMARY.md`
- Once such runs have actually been executed, `results/issue<issue_id>/SUMMARY.md` is mandatory regardless of whether the result is successful, failed, or inconclusive
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
- `SUMMARY.md` is only for experiment facts, outcomes, and analysis; do not turn it into a Stage/process diary, branch history, or generic implementation recap
- Run- or Stage-level process narration belongs in `.agent-workflow/docs/run_log.md`; per-issue delivery/reflection belongs in the archive or `REFLECT-<issue_id>.md`
- Multiple experiments from the same issue may share one `SUMMARY.md`; raw logs, plots, JSON, CSV, and other artifacts should live in the same directory or its subdirectories

## Maintenance Rules

1. When style conflicts arise, this document takes precedence.
2. Add a new pattern here before rolling it out.
3. Once a rule is enforced by a linter, migrate it to `architecture.md`.

# AGENTS.md

## Startup Protocol

On every startup, execute the following loop in order. Do not skip steps or change their order.

> Prerequisite: `.agent-workflow/docs/stage.lock` must already exist. It is a bootstrap file generated during initialization. If it is missing, the repository has not been fully initialized or the file is corrupted — a human must re-run `init.sh` or restore it manually.

**Step 1: Confirm Current Stage**

Read `.agent-workflow/docs/stage.lock` and retrieve the `current` field.

**Step 2: Call build_context.py**

> Prerequisite: `build_context.py` requires PyYAML. If not installed, run:
> ```bash
> python3 -m pip install pyyaml
> ```

```bash
python .agent-workflow/scripts/build_context.py --stage <current>
```

On exit 0, the script outputs the list of files to load for the current Stage — read all of them.
On exit 1, a required file is missing — do not continue. Write to `.agent-workflow/docs/blockers.md` and stop.

**Step 3: Execute**

After reading all files, follow the instructions in `.agent-workflow/docs/workflow/<current>.md`.

**Step 4: Decide Whether to Continue**

After each Stage, re-read `.agent-workflow/docs/stage.lock`:

- If `status == failed` → **Stop**, wait for a human to handle the blocker
- If `current == stage1` and `status == done` and `previous == stage6` → **Continue**
  - This means one complete issue loop has finished and returned to Stage 1
  - If there is no blocker, the same run may continue with the next backlog task
- Otherwise → Return to Step 1 and continue to the next Stage

---

## Document Index

| Document | Responsibility |
|------|------|
| `.agent-workflow/docs/workflow/stage1.md` | Stage 1 instructions: Context Loading / Router |
| `.agent-workflow/docs/workflow/stage2.md` | Stage 2 instructions: Task Planning |
| `.agent-workflow/docs/workflow/stage3.md` | Stage 3 instructions: Implementation |
| `.agent-workflow/docs/workflow/stage4.md` | Stage 4 instructions: Delivery & Verification |
| `.agent-workflow/docs/workflow/stage5.md` | Stage 5 instructions: Reflection |
| `.agent-workflow/docs/workflow/stage6.md` | Stage 6 instructions: Entropy Check |
| `.agent-workflow/docs/stage.lock` | Global state register: current Stage + status + meta |
| `.agent-workflow/docs/overview.md` | Project goals and scope |
| `.agent-workflow/docs/architecture.md` | Module boundaries and dependency rules |
| `.agent-workflow/docs/conventions.md` | Naming, code style, and git conventions |
| `.agent-workflow/docs/environment.md` | Runtime environment, scheduler, and prerequisite facts |
| `.agent-workflow/docs/run_log.md` | Cross-issue run-level execution log |
| `.agent-workflow/docs/decisions.md` | Append-only design decision log |
| `.agent-workflow/docs/quality.md` | Definition of Done and verification methods |
| `.agent-workflow/docs/security.md` | Sensitive data and security boundaries |
| `.agent-workflow/docs/progress.md` | Project snapshot |
| `.agent-workflow/docs/blockers.md` | Agent blockers (human intervention points) |
| `.agent-workflow/docs/wisdom.md` | Reusable patterns validated across issues |
| `.agent-workflow/docs/antipatterns.md` | Failure patterns validated across issues |
| `.agent-workflow/docs/plan/backlog.md` | Issue queue |
| `.agent-workflow/docs/plan/current.md` | Execution steps for the current issue |
| `.agent-workflow/issue_test/README.md` | Issue-level regression script conventions |
| `.agent-workflow/scripts/run_issue_tests.sh` | Cumulative regression runner for `.agent-workflow/issue_test/*.sh` |

---

## Global Hard Rules

1. The three-step startup protocol must execute; it cannot be skipped.
2. When Stage routing is unclear, use `stage.lock` as the source of truth — do not guess.
3. Every Stage must complete its Exit Checklist before proceeding; it cannot be skipped.
4. `.agent-workflow/` is local workflow state by default; `stage.lock`, `current.md`, `blockers.md`, archives, issue tests, and workflow docs should not enter the repository history unless the team explicitly decides to track them. If they are tracked, keep those commits separate from business code.
5. Architecture boundary violations must be fixed first. If `.agent-workflow/docs/architecture.md` says a rule is "enforced by static check or CI", use the tool output as the source of truth. If no automated check is configured yet, the agent self-enforces and records the constraint as manually enforced in `.agent-workflow/docs/decisions.md`.
6. Read `.agent-workflow/docs/security.md` before touching credentials, authentication, or sensitive files.
7. Important technical trade-offs must be appended to `.agent-workflow/docs/decisions.md` (overwriting history is forbidden).
8. Before entering Stage 3, the corresponding `.agent-workflow/issue_test/<meta.issue_id>.sh` must exist. Subsequent issues must not delete, skip, or weaken historical issue tests to avoid regressions.
9. If `current: stage1`, `status: done`, `previous: stage6` is detected, one issue loop has just finished; if there is no blocker, the same run may continue with the next backlog task.
10. When an unresolvable problem is encountered, write to `.agent-workflow/docs/blockers.md` and stop. Do not bypass the blocker.
11. Stage 4 creates or updates the PR; it does not perform the final merge. Stage 6 handles the final merge / auto-merge. If remote delivery in Stage 4 or Stage 6 is blocked by network, permissions, or environment constraints, it may fall back to "local delivery + manual handoff", but the local commit hash, failed command, and required human next steps must be written into the archive record.
12. `.agent-workflow/docs/run_log.md` must be maintained continuously: Stage 2 clarifies the goal, Stage 4/6 append work and results, and any stopping point must fill in the end time and final status.
13. If a later run discovers new environment facts (for example Slurm, conda, CUDA, login-node limits, or scheduler-only execution), update `.agent-workflow/docs/environment.md` immediately instead of leaving that knowledge only in chat context.
14. After any experiment, evaluation, or smoke test run, store outputs under `results/issue<issue_id>/` and append a summary to `results/issue<issue_id>/SUMMARY.md`, including at minimum the setup, model/workflow, input length, result, and attempted analysis.

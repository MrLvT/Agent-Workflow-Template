# Stage 3 — Implementation

> Answers: Is the code written? Does it pass verification?

## Execution Steps

### Step 1: Run historical issue regression baseline

```bash
bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<meta.issue_id>.sh
```

- FAIL → Fix the existing regression first, then continue with the current issue
- Same error not resolved after 3 fix attempts → enter **Failure Path A**

### Step 2: Run the current issue test script to confirm baseline

```bash
bash .agent-workflow/issue_test/<meta.issue_id>.sh
```

- If the issue represents new or fixed behavior, the ideal result is usually "not yet passing" or a clear demonstration of the missing behavior
- If the issue is refactoring, cleanup, or a non-behavioral change, the script may pass before implementation — but you must be able to explain what invariant it is protecting
- If the script fails but does not provide sufficient diagnostic info, fix the test output first, then continue
- If the script result clearly does not match the issue goal (e.g. should fail but passes and there is no visible target-behavior assertion) → fix the test script first, then continue
- Cannot determine whether the script is valid → enter **Failure Path B**

### Step 3: Implement code

Implement step by step following `.agent-workflow/docs/plan/current.md`, checking off each step immediately after completion (`- [x]`).

When touching sensitive content (authentication, credentials, permissions), read `.agent-workflow/docs/security.md` first.

If during implementation you discover that architecture boundaries need adjustment (new modules, dependency changes, layer responsibility changes):

1. Update `.agent-workflow/docs/architecture.md` immediately — do not wait until Stage 6
2. Append a decision to `.agent-workflow/docs/decisions.md` explaining why the adjustment is needed
3. If the change involves lint rules, update the corresponding rule file at the same time

If during implementation you discover new environment facts or execution prerequisites (for example Slurm-only execution, `conda activate agent`, compute-node-only execution, GPU/CUDA requirements, required modules, or required env vars):

1. Update `.agent-workflow/docs/environment.md` immediately
2. If the fact changes the team's default execution or verification model, append a decision to `.agent-workflow/docs/decisions.md`
3. Record the discovery and update in `.agent-workflow/docs/run_log.md`

### Step 4: Run the full issue regression suite

```bash
bash .agent-workflow/scripts/run_issue_tests.sh
```

- FAIL → Fix and re-run until all pass
- Same error not resolved after 3 fix attempts → enter **Failure Path A**

### Step 4.5: Record experiment results (if any)

If this stage ran experiments, evaluations, or smoke tests:

- The canonical result directory is `results/issue<meta.issue_id>/`
- After each experiment, append one summary section to `results/issue<meta.issue_id>/SUMMARY.md`
- Each summary must include at least:
  - Experiment name / time
  - Goal or hypothesis
  - Model and key settings
  - Workflow / pipeline
  - Key input conditions such as input length, batch size, seed, and data slice
  - Command, environment, hardware, or scheduler information
  - Raw log / artifact paths
  - Primary result and metrics
  - Attempted analysis, even if the result failed or remains inconclusive

### Step 5: Update stage.lock

```yaml
current: stage4
status: in_progress
previous: stage3
```

## Exit Checklist

- [ ] All steps in `.agent-workflow/docs/plan/current.md` are checked
- [ ] `bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<meta.issue_id>.sh` passed
- [ ] `.agent-workflow/issue_test/<meta.issue_id>.sh` was executed before implementation; result matches the issue goal and produces sufficient diagnostic info on failure
- [ ] When architecture boundaries changed, `.agent-workflow/docs/architecture.md` was updated and decisions.md was appended
- [ ] When environment facts changed, `.agent-workflow/docs/environment.md` was updated; if default execution changed, decisions.md was appended
- [ ] If this issue ran experiments, evaluations, or smoke tests, `results/issue<meta.issue_id>/SUMMARY.md` contains a summary entry for each experiment
- [ ] `bash .agent-workflow/scripts/run_issue_tests.sh` outputs `ISSUE TESTS: PASS`
- [ ] `stage.lock` updated (current: stage4)
- [ ] `stage.lock` updated; only create a separate status commit if the team explicitly tracks `.agent-workflow/`

## Failure Path

### Failure Path A: Same error not resolved after 3 fix attempts

- Write to `.agent-workflow/docs/blockers.md`, clearly recording:
  - Fix approaches already attempted
  - Most recent failed command and error summary
  - Questions the human needs to answer
- Update stage.lock (status: failed), stop, notify human

### Failure Path B: Cannot determine whether the current issue test is valid

Write to `.agent-workflow/docs/blockers.md`, update stage.lock (status: failed), stop, ask human to confirm.

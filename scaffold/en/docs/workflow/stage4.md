# Stage 4 — Delivery & Verification

> Answers: Is it ready to deliver?

## Execution Steps

### Step 1: Final issue regression gate

```bash
bash .agent-workflow/scripts/run_issue_tests.sh
```

- Outputs `ISSUE TESTS: PASS` → continue
- Outputs `ISSUE TESTS: FAIL` → return to **Stage 3** to fix (update stage.lock: current: stage3)

### Step 2: Manual self-review

Review all items in `.agent-workflow/docs/quality.md` that cannot be scripted, one by one. All must pass before continuing.

### Step 3: Local delivery commit

```bash
git add <relevant files>
git commit   # message format: see .agent-workflow/docs/conventions.md
```

- If the business changes for the current issue are already committed locally, do not create an empty commit
- The goal of this step is to ensure a handoff-ready local commit exists

### Step 4: Create or update PR (do not merge in this stage)

Preferred approach:

```bash
bash .agent-workflow/scripts/deliver_pr.sh ensure --base <base-branch>
```

- This script pushes the current branch and creates or reuses the corresponding PR
- If custom title or body is needed, pass `--title` and/or `--body-file`
- PR exists or was successfully created → record PR URL in the archive and note "Stage 6 will attempt the final merge", then continue
- If failure is caused by network, DNS, permissions, sandbox restrictions, or `gh` unavailability, retry at most 3 times, then fall back to **local delivery + manual handoff**
- Local delivery + manual handoff is not a failure: as long as a local commit exists and verification passed, continue
- Handoff record must include:
  - Local commit hash
  - Failed command and error summary
  - What the human must do next (e.g. push, open PR, provide credentials)

### Step 5: Update progress.md

Record the completed feature/fix in `.agent-workflow/docs/progress.md`.

### Step 5.5: Update run_log

Append the current issue's factual execution summary to `.agent-workflow/docs/run_log.md`, including at least:

- Which issue / fix was completed
- The key actions taken (code, tests, delivery)
- The tangible outcome (tests passed, local commit created, PR URL or handoff)

### Step 5.8: Check experiment result directory (if any)

If the current issue ran experiments, evaluations, or smoke tests:

- Confirm the result directory is `results/issue<meta.issue_id>/`
- Confirm `results/issue<meta.issue_id>/SUMMARY.md` exists
- Confirm the summary covers every experiment and includes setup, model/workflow, input length, result, and attempted analysis

### Step 6: Archive current.md

```bash
# Copy current.md contents to archive
cp .agent-workflow/docs/plan/current.md .agent-workflow/docs/plan/archive/<meta.issue_id>.md
```

- The archive must retain the test script path for the current issue: `.agent-workflow/issue_test/<meta.issue_id>.sh`
- The archive must include the delivery status:
  - PR created or reused: write the PR URL, and note "Stage 6 will attempt the final merge"
  - Local delivery + manual handoff: write the local commit hash, reason for failure, and human next steps
- If the current issue ran experiments, evaluations, or smoke tests: record the result directory `results/issue<meta.issue_id>/` and the `SUMMARY.md` path
- Do not move or delete `.agent-workflow/issue_test/<meta.issue_id>.sh`; it must remain in `.agent-workflow/issue_test/` to participate in future regressions

### Step 7: Clean up

- Clear `.agent-workflow/docs/plan/current.md`
- Reset content must strictly match the template below — do not omit or duplicate sections:

```markdown
# Current Plan

## Current Status

- No issue currently in progress.
- When starting a new task, the agent or a human will rewrite this file with a concrete task plan, and create `.agent-workflow/issue_test/<issue_id>.sh` first.

## Fields to Fill When Starting a New Task

1. Task name, source issue, start date, status
2. Test script path and coverage goal for the current issue
3. Step-by-step checkable execution steps
4. Verification records (must include at least the historical regression baseline and full regression result)
5. If experiments, evaluations, or smoke tests are involved: result directory `results/issue<issue_id>/` and summary file `results/issue<issue_id>/SUMMARY.md`

## Maintenance Notes

- This file records only the one issue currently in progress.
- The corresponding test script is always kept at `.agent-workflow/issue_test/<issue_id>.sh`; it remains in `.agent-workflow/issue_test/` after the task is complete.
- After completing a task, archive this file to `.agent-workflow/docs/plan/archive/`, then reset it to the "no issue in progress" state.
```

- Mark the corresponding backlog entry as `[x]` in `.agent-workflow/docs/plan/backlog.md`

### Step 8: Update stage.lock

```yaml
current: stage5
status: in_progress
previous: stage4
```

## Exit Checklist

- [ ] `bash .agent-workflow/scripts/run_issue_tests.sh` outputs `ISSUE TESTS: PASS`
- [ ] All manual review items in `.agent-workflow/docs/quality.md` passed
- [ ] A deliverable local commit exists
- [ ] One of the following is complete:
  - PR created or reused, and the archive records the PR URL and "Stage 6 will attempt the final merge"
  - The archive records "local delivery + manual handoff" with the commit hash, reason, and next steps
- [ ] `.agent-workflow/docs/progress.md` updated
- [ ] `.agent-workflow/docs/run_log.md` appended with factual work and results for this issue
- [ ] If this issue ran experiments, evaluations, or smoke tests, `results/issue<meta.issue_id>/SUMMARY.md` exists and is complete
- [ ] `.agent-workflow/docs/plan/archive/<meta.issue_id>.md` created
- [ ] `.agent-workflow/issue_test/<meta.issue_id>.sh` still present in `.agent-workflow/issue_test/`
- [ ] `.agent-workflow/docs/plan/current.md` cleared
- [ ] Corresponding backlog entry marked `[x]`
- [ ] `stage.lock` updated (current: stage5)
- [ ] `stage.lock` updated; only create a separate status commit if the team explicitly tracks `.agent-workflow/`

## Failure Path

- `.agent-workflow/scripts/run_issue_tests.sh` FAIL → update stage.lock (current: stage3, status: in_progress), return to Stage 3
- Cannot form a reproducible local delivery commit → write to `.agent-workflow/docs/blockers.md`, update stage.lock (status: failed), stop, notify human
- Cannot determine whether PR creation failure has been fully captured as handoff info → write to `.agent-workflow/docs/blockers.md`, update stage.lock (status: failed), stop, notify human

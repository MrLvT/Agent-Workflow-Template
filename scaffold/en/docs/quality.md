# Quality

> This document answers: What does "done" mean? How do you verify it?

## Definition of Done

### Code Quality

- [ ] Implementation matches `.agent-workflow/docs/plan/current.md`
- [ ] No obvious duplicate logic or dead code
- [ ] Changes touching architecture/security/decision boundaries are reflected in the corresponding documents

### Issue Regression Quality

- [ ] The corresponding `.agent-workflow/issue_test/<issue_id>.sh` exists and covers the target behavior
- [ ] Historical regression baseline was run before implementation: `bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<issue_id>.sh`
- [ ] Full regression was run before committing: `bash .agent-workflow/scripts/run_issue_tests.sh`
- [ ] If any historical `.agent-workflow/issue_test/*.sh` was modified, the reason and impact are recorded

### Experiment Evidence

- [ ] `results/issue<issue_id>/` is required only when this issue actually executed result-producing experiments, evaluations, benchmarks, or exploratory smoke tests
- [ ] If such runs actually occurred, `results/issue<issue_id>/SUMMARY.md` exists and contains one entry per run
- [ ] Each experiment summary includes at least the setup, model/workflow, input length, key input conditions, command/environment, result metrics, raw artifact paths, and attempted analysis
- [ ] Failed or inconclusive runs are recorded too; do not keep only the "good-looking" results
- [ ] `SUMMARY.md` stays focused on experiment outcome and analysis, not Stage/process recap or general implementation narrative

### Documentation Sync

- [ ] Changes are reflected in relevant documents
- [ ] Important decisions are written to `.agent-workflow/docs/decisions.md`
- [ ] `.agent-workflow/docs/progress.md` reflects the current state
- [ ] Delivery status is recorded: the archive contains the local delivery summary (commit hash, verification conclusion, and manual next step when needed)

### Security

- [ ] No sensitive information leaked
- [ ] Authentication/authorization changes have been reviewed (if applicable)
- [ ] If a change has security impact, the risk is noted in the archive or handoff record

## issue_test Mechanism (fixed)

- Directory: `.agent-workflow/issue_test/`
- Naming: `.agent-workflow/issue_test/<issue_id>.sh`
- Runner: `bash .agent-workflow/scripts/run_issue_tests.sh`
- History policy: scripts are retained indefinitely; all subsequent issues must pass all of them

## Project-Native Checks (to be filled)

- Unit/integration test framework:
- Static analysis tool:
- Other pre-delivery commands:

## Common Verification Commands

```bash
# Run all issue regressions
bash .agent-workflow/scripts/run_issue_tests.sh

# Run historical regression baseline before implementing the current issue
bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<issue_id>.sh

# Project-native check (if any)
<command>
```

## Failure Handling

1. Fix deterministic issue regression failures first, then address flaky scenarios.
2. Passing regressions by deleting, skipping, or weakening historical `.agent-workflow/issue_test/*.sh` is forbidden.
3. Temporary skips must include a recorded reason and a recovery plan.

## Maintenance Rules

1. New quality gates must be written here before being added to CI.
2. This document is the mandatory pre-commit self-review checklist and must not be weakened.
3. Every issue must add or bind to a reproducible `.agent-workflow/issue_test/<issue_id>.sh`.
4. Only issues that actually execute result-producing experiments, evaluations, benchmarks, or exploratory smoke tests must maintain `results/issue<issue_id>/SUMMARY.md`; once executed, successful, failed, and inconclusive runs must all be recorded.

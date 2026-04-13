# Stage 6 — Entropy Check

> Answers: Are the documentation and code still in sync?

## Execution Steps

### Step 1: Compare documentation against code

Check each document in `.agent-workflow/docs/` against the code implementation and identify all discrepancies:

- Documented behavior does not match actual code behavior
- Documented directory structure or module layout does not match the code
- Completed features listed in `.agent-workflow/docs/progress.md` do not match the code
- Runtime environment definitions in `.agent-workflow/docs/environment.md` do not match how the project actually has to be executed

### Step 2: Resolve discrepancies

**Path A (documentation only):** Discrepancy is documentation lagging behind code → update documentation to match code

**Path B (code change needed):** Code contradicts the intent recorded in documentation → fix code and add tests, and mark in stage.lock:

```yaml
meta:
  code_changed: true
```

### Step 3: decisions.md compaction (as needed)

Check `.agent-workflow/docs/decisions.md`:

- Superseded entries exceed 30% of total entries → perform compaction
- Summarize all Accepted entries into one-line summaries and update the "Current Effective Decision Summary" area
- The history area remains unchanged (append only, no modification)

### Step 4: Update stage.lock

**Path A (documentation only):**

```yaml
current: stage1
status: done
previous: stage6
meta:
  issue_id: null
  code_changed: null
```

- After writing the state above, proceed to Step 5 for the final remote delivery
- After writing this state, let Stage 1 decide whether to continue with backlog routing or end the current run

**Path B (code changed):**

```yaml
current: stage3
status: in_progress
previous: stage6
meta:
  code_changed: null
  # issue_id is kept; run the full S3 → S4 → S5 loop
```

- If the team tracks `.agent-workflow/`, it may commit the status file separately; by default updating local workflow state is enough

### Step 5: Final remote delivery (Path A only)

Preferred approach:

```bash
git push
bash .agent-workflow/scripts/deliver_pr.sh merge --merge-method squash
```

- `ACTION=MERGED` → PR has completed the final merge; this run ends successfully
- `ACTION=AUTO_MERGE_ENABLED` → auto-merge is enabled; this run ends successfully
- If blocked by network, DNS, permissions, sandbox restrictions, `gh` unavailability, or repository settings, retry at most 3 times, then append a merge handoff to `.agent-workflow/docs/plan/archive/<issue_id>.md`:
  - Existing PR URL (if any)
  - Current final local commit hash
  - Failed command and error summary
  - Human next steps (e.g. add permissions, provide credentials, retry `bash .agent-workflow/scripts/deliver_pr.sh merge --merge-method squash`)
- After appending the handoff, if there are new documentation changes, add a new regular commit — **do not amend or mix into the Stage 6 stage.lock commit**
- A merge handoff is not a failure: as long as the final state and human next steps are written clearly, the run may also end

### Step 5.5: Update run_log

Append the current issue's final delivery outcome to `.agent-workflow/docs/run_log.md`, including at least:

- Final delivery state: `MERGED` / `AUTO_MERGE_ENABLED` / `MERGE_HANDOFF` / `RETURN_TO_STAGE3`
- Verifiable outcomes: PR URL, commit hash, test conclusion, or handoff summary
- If the run ends here, fill in the end time and final status; if backlog routing will continue, keep the run entry as `in_progress`

## Exit Checklist

- [ ] Documentation and code are aligned; no known discrepancies
- [ ] `.agent-workflow/docs/environment.md` matches the real execution environment; new facts have been written back
- [ ] `.agent-workflow/docs/decisions.md` handled (compacted or confirmed no compaction needed)
- [ ] `.agent-workflow/docs/run_log.md` updated with the final delivery outcome for this issue
- [ ] `stage.lock` correctly updated following Path A or Path B
- [ ] If Path A: returned to `stage1/done` and treated as the successful endpoint of this run
- [ ] `stage.lock` updated for Path A or Path B; only create a status commit when the team explicitly tracks `.agent-workflow/`
- [ ] If Path A, one of the following is satisfied:
  - PR directly merged
  - PR has auto-merge enabled
  - `.agent-workflow/docs/plan/archive/<issue_id>.md` has merge handoff appended, with failure reason and human next steps clearly written
- [ ] If Path B: this run did not attempt merge; ready to return to Stage 3 to continue the loop

## Failure Path

- Found a contradiction between documentation and code that cannot be resolved → write to `.agent-workflow/docs/blockers.md`, update stage.lock (status: failed), stop, notify human
- In Path A, cannot determine whether merge failure has been fully captured as handoff info → write to `.agent-workflow/docs/blockers.md`, update stage.lock (status: failed), stop, notify human

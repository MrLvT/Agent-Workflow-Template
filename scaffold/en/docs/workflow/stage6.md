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

**Path A (documentation-only or state-only closeout):** Documentation is lagging behind the code, or only the final records need to be aligned → update documentation to match reality

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

**Path A (documentation-only or state-only closeout):**

```yaml
current: stage1
status: done
previous: stage6
meta:
  issue_id: null
  code_changed: null
```

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

### Step 5: Update run_log

Append the current issue's final delivery outcome to `.agent-workflow/docs/run_log.md`, including at least:

- Final delivery state: `DONE` / `LOCAL_HANDOFF` / `RETURN_TO_STAGE3`
- Verifiable outcomes: commit hash, test conclusion, or handoff summary
- If the run ends here, fill in the end time and final status; if backlog routing will continue, keep the run entry as `in_progress`

## Exit Checklist

- [ ] Documentation and code are aligned; no known discrepancies
- [ ] `.agent-workflow/docs/environment.md` matches the real execution environment; new facts have been written back
- [ ] `.agent-workflow/docs/decisions.md` handled (compacted or confirmed no compaction needed)
- [ ] `.agent-workflow/docs/run_log.md` updated with the final delivery outcome for this issue
- [ ] `stage.lock` correctly updated following Path A or Path B
- [ ] If Path A: returned to `stage1/done` and treated as the successful endpoint of this run
- [ ] `stage.lock` updated for Path A or Path B; only create a status commit when the team explicitly tracks `.agent-workflow/`
- [ ] If Path A: the archive's local delivery summary is still accurate, and manual next steps were added when needed
- [ ] If Path B: this run stayed within local closeout and is ready to return to Stage 3 to continue the loop

## Failure Path

- Found a contradiction between documentation and code that cannot be resolved → write to `.agent-workflow/docs/blockers.md`, update stage.lock (status: failed), stop, notify human

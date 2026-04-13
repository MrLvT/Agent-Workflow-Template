# Stage 1 — Context Loading / Router

> Answers: Where should I go right now?

## Execution Steps

Execute in order; no steps may be skipped.

### Step 0: Prepare run_log

Read `.agent-workflow/docs/run_log.md`:

- If the latest run entry has status `in_progress`, keep reusing it
- If no run is currently open, create one and record at minimum:
  - Start Time
  - Status: `in_progress`
  - Goal: `To be clarified in Stage 2` or `Resume current issue`
- Later stages must keep updating the same entry; do not open duplicate entries for one run

### Step 1: Read stage.lock — route first

Read `.agent-workflow/docs/stage.lock` and check the `status` field:

- `status == failed` → **Stop, notify human** (previous execution failed; human intervention required)
  - Before stopping, fill in the current run entry's end time, status (`failed`), and actual result
- `current == stage1 && status == done && previous == stage6` → **Continue routing**
  - A complete issue loop just finished and returned from Stage 6 to Stage 1
  - If there is no blocker, the same run may continue with the next backlog task
- `status == in_progress` → **Jump directly to the Stage specified by `stage.lock.current`; do not continue evaluating below**
- `status == done` → Continue to Step 2

### Step 2: Check blockers (only when status == done)

Read `.agent-workflow/docs/blockers.md`:

- Unresolved entries exist → **Stop, notify human** (blockers must be resolved first)
  - Before stopping, fill in the current run entry's end time, status (`blocked`), and actual result
- No unresolved entries → Continue to Step 3

### Step 3: Check current task status (only when status == done)

Read `.agent-workflow/docs/plan/current.md`:

- Has unchecked steps (unchecked `- [ ]` items exist) → Go to **Stage 3**
- Empty or all steps completed → Go to **Stage 2**

## Exit Checklist

- [ ] `stage.lock` has been read
- [ ] `.agent-workflow/docs/run_log.md` has been read and the current run entry was reused or created
- [ ] Determined whether this run should "stop" or "continue routing"
- [ ] If continuing: `stage.lock` updated (current points to next Stage, status: in_progress)
- [ ] If continuing: `stage.lock` has been updated; only make a separate status commit when the team explicitly tracks `.agent-workflow/`
- [ ] If continuing: handled the `current: stage1`, `status: done`, `previous: stage6` continuous-run case correctly

## Failure Path

- `stage.lock` file does not exist → Stop, notify human to run `init.sh` or restore the default `stage.lock`
- `status == failed` → Stop, notify human; do not modify status on your own
- `blockers.md` has unresolved entries → Stop, notify human

# Stage 2 — Task Planning

> Answers: What is the next task? How should it be broken down for execution?

## Execution Steps

### Step 1: Risk prediction

Read `.agent-workflow/docs/antipatterns.md` (if it exists):

- Check whether the task to be selected triggers any known failure patterns
- If a match is found, annotate the risk in the plan in `current.md`

### Step 2: Select task

Read `.agent-workflow/docs/plan/backlog.md` and select one `- [ ]` task:

- Select by priority from high to low (P0 → P1 → P2)
- If requirements are unclear, stop and notify the human to clarify — do not guess

### Step 2.5: Check whether overview.md needs updating

Compare the selected task against In Scope / Out of Scope in `.agent-workflow/docs/overview.md`:

- Task is within current scope → continue
- Task is outside current scope, or project goals/scope need to expand → update `.agent-workflow/docs/overview.md` first, then continue
- Scope changes must also append a decision to `.agent-workflow/docs/decisions.md`

### Step 3: Determine issue_id

Format: `<number>-<short-description>` (example: `42-add-user-auth`)

- `number` comes from the backlog entry number or an auto-incremented sequence
- `short-description` uses kebab-case, no more than 5 words

### Step 3.5: Create or switch to the current issue branch

Default branch name: `codex/<issue_id>`

- Already on `codex/<issue_id>` → continue
- Branch `codex/<issue_id>` exists locally → run `git switch codex/<issue_id>`
- On the default branch (infer from `origin/HEAD`; fall back to `main`) and `codex/<issue_id>` does not exist locally → run `git switch -c codex/<issue_id>`
- On an unrelated working branch → stop and notify human to avoid mixing two issues on the same branch
- If the team has defined an equivalent prefix in `.agent-workflow/docs/conventions.md`, `codex` may be replaced — but the one-issue-one-branch rule must be maintained

### Step 4: Create the test script for the current issue

Create `.agent-workflow/issue_test/<issue_id>.sh`, requirements:

- Executable from the repository root
- Use exit codes to express results: exit 0 = PASS, non-zero = FAIL
- On failure, must print clear diagnostic information: at minimum the expected result, actual result, and failed command or check point
- Must cover the target behavior or deliverable of the current issue — must not be an empty placeholder
- Should be deterministic; if it depends on external services or special environments, the prerequisites must be documented inside the script
- Do not modify historical `.agent-workflow/issue_test/*.sh` unless necessary; if modification is required, record the reason in `current.md`

### Step 5: Write current.md

Write the execution steps into `.agent-workflow/docs/plan/current.md`, format requirements:

- Use checkbox format (`- [ ]`)
- Step granularity: each step can be checked independently after completion
- If risk annotations exist, write them before the relevant steps
- Clearly record the test script path for the current issue: `.agent-workflow/issue_test/<issue_id>.sh`
- Clearly record two verification commands:
  - Historical regression before implementation: `bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<issue_id>.sh`
  - Full regression after implementation: `bash .agent-workflow/scripts/run_issue_tests.sh`

### Step 6: Record technical decisions (if any)

When important technical choices are made, append to `.agent-workflow/docs/decisions.md` (append only, never modify history).

> Note: scope changes to overview.md must also be appended to decisions.md in this step.

### Step 6.5: Update run_log

Update the current in-progress entry in `.agent-workflow/docs/run_log.md` with at least:

- The issue / problem this run is currently trying to solve
- The branch that was created or switched to
- The new `.agent-workflow/issue_test/<issue_id>.sh`
- The execution plan written into `.agent-workflow/docs/plan/current.md`

### Step 7: Update stage.lock

```yaml
current: stage3
status: in_progress
previous: stage2
meta:
  issue_id: "<determined issue_id>"
```

## Exit Checklist

- [ ] `.agent-workflow/docs/overview.md` checked; updated and decisions.md appended when scope changed
- [ ] Switched to an independent working branch for the current issue (default: `codex/<issue_id>`)
- [ ] `.agent-workflow/issue_test/<issue_id>.sh` created, covering the target behavior of the current issue, and outputs diagnostic info on failure
- [ ] `.agent-workflow/docs/plan/current.md` is non-empty and has checkable steps
- [ ] `.agent-workflow/docs/plan/current.md` records the current issue test script path and both verification commands
- [ ] `.agent-workflow/docs/run_log.md` records the current run goal and planned actions
- [ ] `stage.lock.meta.issue_id` is written
- [ ] `stage.lock` updated (current: stage3)
- [ ] `stage.lock` update committed separately (format: `chore(stage): stage2 → stage3 [done]`)

## Failure Path

- Backlog is empty → update stage.lock (status: failed), complete `.agent-workflow/docs/run_log.md` with end time, status, and "no safe next task", then stop and notify human to add tasks
- Requirements are unclear and cannot be broken down → update stage.lock (status: failed), complete `.agent-workflow/docs/run_log.md` with end time, status, and the clarification gap, then stop and notify human
- Cannot safely switch to an independent working branch for the current issue → update stage.lock (status: failed), complete `.agent-workflow/docs/run_log.md` with end time, status, and the branch problem, then stop and notify human
- Requirements cannot be expressed as an executable `.agent-workflow/issue_test/<issue_id>.sh` → update stage.lock (status: failed), complete `.agent-workflow/docs/run_log.md` with end time, status, and the acceptance-criteria gap, then stop and notify human

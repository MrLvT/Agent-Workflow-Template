# Agent Workflow Template

🌐 [中文版](README.zh.md)

A template repository that breaks down AI agent development workflows into an "initialization scaffold + document state machine + issue-level cumulative regression" system.

This solves not "how to write prompts" but "how to turn an agent's workflow into an engineering system that is repeatable, verifiable, and recoverable after interruption".

## Production Verification

This workflow has been fully validated in a real GitHub repository — not just internal template self-testing.

- Verification date: 2026-03-29
- Target repository: [cf3i/MiniAVLtree](https://github.com/cf3i/MiniAVLtree)
- Task: Add "HTML visualization page for AVL tree" to `.agent-workflow/docs/plan/backlog.md`
- Stage 2: Created independent branch `codex/2-html-avl-visualizer` per the rules
- Stage 4: Created PR [#2](https://github.com/cf3i/MiniAVLtree/pull/2) via `bash .agent-workflow/scripts/deliver_pr.sh ensure --base main`
- Stage 6: Completed final merge via `bash .agent-workflow/scripts/deliver_pr.sh merge --merge-method squash`
- Final state: Target repository returned to `stage1 / done / previous=stage6`

This production regression also caught a real bug: the `--jq` flag quoting in `deliver_pr.sh` when outputting `MERGE_COMMIT_SHA` was incorrect. The bug was fixed and written back to the template.

## How to Use This Project

### 1. Initialize Your Target Repository with `init.sh`

Prerequisites:

- The target directory must already be a Git repository.
- The target directory must not be this template repository itself.
- `python3` and `PyYAML` must be available locally, since `.agent-workflow/scripts/build_context.py` depends on them.
- If you want documents automatically filled, you need an available AI CLI such as `codex` or `claude`.

Typical usage:

```bash
# Run in your target project, not in this template repository
cd /path/to/your-repo

# Interactive initialization
bash /path/to/Agent-Workflow-Template/init.sh

# Non-interactive adopt mode
bash /path/to/Agent-Workflow-Template/init.sh \
  --adopt \
  --cli codex \
  --ultra \
  --non-interactive

# Copy skeleton only, skip AI document filling
bash /path/to/Agent-Workflow-Template/init.sh \
  --skip-fill \
  --non-interactive
```

Core parameters supported by `init.sh`:

| Parameter | Effect |
| --- | --- |
| `--adopt` | Onboard an existing repository; documentation prioritizes describing "current facts" |
| `--greenfield` | Initialize for a brand-new project |
| `--skip-fill` | Copy skeleton only; do not call AI to fill documents |
| `--cli <claude\|codex>` | Specify the CLI to use during initialization |
| `--model <name>` | Specify model for `codex` |
| `--reasoning-effort <level>` | Specify reasoning effort for `codex` |
| `--single-call` | Fill all documents with a single AI call |
| `--ultra` | Fill documents per-file using multiple AI calls |
| `--lang <zh\|en>` | Choose document language (default: zh) |
| `--docs-review` / `--no-docs-review` | Whether to perform an additional read-only documentation review |
| `--non-interactive` | Disable the interactive wizard |

Additional notes:

- The script's built-in defaults are `claude + gpt-5.4 + xhigh`.
- If you use `codex` without explicitly specifying an execution mode, the script defaults to `--ultra`; the independent docs review still stays enabled unless you explicitly pass `--no-docs-review`.
- `init.sh` will refuse to run in a non-Git repository because this workflow depends on `stage.lock` commits, branches, and PR delivery.

### 2. How to Start After Initialization

After successful initialization, your target repository will contain:

- `.agent-workflow/AGENTS.md`: Agent startup protocol and hard rules
- `.agent-workflow/docs/`: State machine, project context, plans, blockers, decisions
- `.agent-workflow/issue_test/`: Independent regression script for each issue
- `.agent-workflow/scripts/`: Context loader and issue test runner

Daily operation:

```bash
# Agent startup entry point
bash .agent-workflow/scripts/start_agent.sh

# Manually inspect which context the current Stage will load
python3 .agent-workflow/scripts/build_context.py --stage <current_stage>

# Run cumulative regression for all historical + current issues
bash .agent-workflow/scripts/run_issue_tests.sh

# Run historical regression, excluding the current issue's script
bash .agent-workflow/scripts/run_issue_tests.sh --exclude .agent-workflow/issue_test/<issue_id>.sh
```

`start_agent.sh` now runs in "one fresh Codex session per issue" mode: after one issue loop finishes, the launcher ends that session and starts a new one before the next issue so context does not grow forever across issues. If you want only one session, use `bash .agent-workflow/scripts/start_agent.sh --once`.

### 2.4 Upgrade Rules for an Existing Installed Workflow

If another repository already has `.agent-workflow/`, do not re-run `init.sh`. Use the upgrade helper from the template repository instead. It only syncs template-owned rule files and preserves the target repository's existing state/history:

```bash
bash /path/to/Agent-Workflow-Template/scripts/upgrade_workflow_rules.sh /path/to/target-repo
```

It will:

- sync `.agent-workflow/AGENTS.md`, `docs/workflow/stage*.md`, `scripts/*.sh`, `scripts/build_context.py`, `issue_test/README.md`, and `docs/plan/archive/README.md`
- create `docs/environment.md` and `docs/run_log.md` only if they are missing
- preserve `docs/stage.lock`, `docs/blockers.md`, `docs/plan/current.md`, `docs/plan/archive/*`, `docs/progress.md`, `docs/decisions.md`, and `results/`
- ensure `/.agent-workflow/` is listed in the target repository's `.git/info/exclude`

If the target repository uses the English scaffold explicitly, add:

```bash
bash /path/to/Agent-Workflow-Template/scripts/upgrade_workflow_rules.sh /path/to/target-repo --lang en
```

### 2.5 Write to `backlog.md` Before Starting a New Task

In this template, the formal entry point for "what to develop" is not changing code directly or writing `current.md` first — it is adding the task to `.agent-workflow/docs/plan/backlog.md`.

Recommended order:

1. Add a `- [ ]` entry in `.agent-workflow/docs/plan/backlog.md`
2. Start the agent
3. Stage 2 selects an entry from the backlog
4. Stage 2 generates the `issue_id`
5. Stage 2 creates `.agent-workflow/issue_test/<issue_id>.sh`
6. Stage 2 writes the implementation steps to `.agent-workflow/docs/plan/current.md`
7. Stage 3 begins implementation; Stage 4 marks the backlog entry as `- [x]` after delivery

The role of each:

- `.agent-workflow/docs/plan/backlog.md`: defines "what comes next"
- `.agent-workflow/docs/plan/current.md`: defines "how to execute the current issue step by step"
- `.agent-workflow/issue_test/<issue_id>.sh`: defines "how to verify acceptance when this issue is complete"

In short: `backlog.md` is the development entry point, `current.md` is the in-progress plan, and `issue_test` is the acceptance script.

If the current issue includes experiments, evaluations, or smoke tests, results must be written under `results/issue<issue_id>/`, and `results/issue<issue_id>/SUMMARY.md` must append one summary per experiment with the model, workflow, input length, key settings, result, and attempted analysis.

### 3. What Does `init.sh` Actually Do?

`init.sh` does more than copy files. It divides template initialization into four types of actions:

| Category | How it's handled | Files |
| --- | --- | --- |
| Fixed skeleton | Copied directly from `scaffold/<lang>/` | `.agent-workflow/docs/stage.lock`, `.agent-workflow/docs/run_log.md`, `.agent-workflow/docs/environment.md`, `.agent-workflow/docs/workflow/stage*.md`, `.agent-workflow/docs/wisdom.md`, `.agent-workflow/docs/antipatterns.md`, `.agent-workflow/docs/blockers.md`, `.agent-workflow/docs/plan/current.md`, `.agent-workflow/docs/plan/archive/README.md`, `.agent-workflow/issue_test/README.md`, `.agent-workflow/scripts/build_context.py`, `.agent-workflow/scripts/run_issue_tests.sh`, `.agent-workflow/scripts/deliver_pr.sh` |
| AI-filled | Template copied first, then AI fills it based on target repo facts | `.agent-workflow/docs/overview.md`, `.agent-workflow/docs/architecture.md`, `.agent-workflow/docs/conventions.md`, `.agent-workflow/docs/quality.md`, `.agent-workflow/docs/security.md`, `.agent-workflow/docs/progress.md`, `.agent-workflow/docs/plan/backlog.md` |
| Script-written | Copied, then placeholders replaced by the script | `.agent-workflow/docs/decisions.md` — D-001 date and initialization background inserted by `sed` |
| Deferred copy | Copied after AI filling completes to avoid affecting the initialization prompt | `.agent-workflow/AGENTS.md` |

During initialization, the script also generates artifacts in `.git/.agent-workflow-init/` in the target repository:

- `logs/*.log`: AI call logs for each step
- `final-review.md`: Human supplementation checklist generated by local rules
- `docs-review.md`: Optional read-only documentation review report

## Project Architecture

This repository consists essentially of two layers:

1. Template layer: `init.sh + scaffold/`
2. Runtime layer: `.agent-workflow/AGENTS.md + .agent-workflow/docs/ + .agent-workflow/issue_test/ + .agent-workflow/scripts/` initialized into the target repository

The template layer is responsible for "generating the runtime system"; the runtime layer is responsible for "driving agent work".

### Top-Level Structure

```text
Agent-Workflow-Template/
├── init.sh
├── scaffold/
│   ├── zh/          ← Chinese scaffold files
│   │   ├── AGENTS.md
│   │   ├── .agent-workflow/docs/
│   │   ├── .agent-workflow/issue_test/
│   │   └── .agent-workflow/scripts/
│   └── en/          ← English scaffold files
│       ├── AGENTS.md
│       ├── .agent-workflow/docs/
│       ├── .agent-workflow/issue_test/
│       └── .agent-workflow/scripts/
├── .agent-workflow/docs/
├── .agent-workflow/issue_test/
└── .agent-workflow/scripts/
```

Two points to note:

- `scaffold/` is the template source files, used for copying to other repositories.
- The `.agent-workflow/docs/`, `.agent-workflow/issue_test/`, and `.agent-workflow/scripts/` at the repository root are this template repository's own working copy, used to maintain and validate the template itself.

### Runtime Layers

| Layer | Components | Responsibility |
| --- | --- | --- |
| Bootstrap | `init.sh`, `scaffold/` | Initialize the target repository, copy the skeleton, fill initial documents |
| Control | `.agent-workflow/AGENTS.md`, `.agent-workflow/docs/stage.lock`, `.agent-workflow/docs/workflow/stage*.md` | Define agent startup protocol, current state, and Stage transition rules |
| Context | `.agent-workflow/docs/overview.md`, `architecture.md`, `conventions.md`, `environment.md`, `quality.md`, `security.md`, `progress.md`, `run_log.md`, `decisions.md`, `blockers.md`, `wisdom.md`, `antipatterns.md`, `.agent-workflow/docs/plan/*` | Provide project facts, rules, environment prerequisites, plans, run history, and blocker information |
| Harness | `.agent-workflow/scripts/build_context.py`, `.agent-workflow/issue_test/*.sh`, `.agent-workflow/scripts/run_issue_tests.sh` | Mechanically load context, mechanically run cumulative regression |
| Delivery | `git commit`, `git push`, `.agent-workflow/scripts/deliver_pr.sh`, `.agent-workflow/docs/plan/archive/*` | Convert changes into deliverable results and archive them |

### Architecture Diagram

```mermaid
flowchart LR
    subgraph Template["Template Layer"]
        INIT["init.sh"]
        SCF["scaffold/"]
    end

    subgraph Runtime["Target Repo Runtime Layer"]
        AG["AGENTS.md"]
        LOCK[".agent-workflow/docs/stage.lock"]
        WF[".agent-workflow/docs/workflow/stage1..6.md"]
        CTX[".agent-workflow/scripts/build_context.py"]
        DOCS[".agent-workflow/docs/*.md"]
        IT[".agent-workflow/issue_test/*.sh"]
        SUITE[".agent-workflow/scripts/run_issue_tests.sh"]
        GIT["git / push / PR / archive"]
    end

    INIT --> SCF
    INIT --> DOCS
    INIT --> CTX
    INIT --> IT
    INIT --> SUITE
    INIT --> AG
    AG --> LOCK
    LOCK --> CTX
    CTX --> WF
    WF --> DOCS
    WF --> IT
    IT --> SUITE
    SUITE --> WF
    WF --> GIT
    GIT --> DOCS
```

## What is `scaffold/`?

`scaffold/` is not sample code — it is the "file master template" used during initialization.

When initializing a target repository, `init.sh` does not read from the currently running `.agent-workflow/docs/` in the root directory. It reads strictly from `scaffold/<lang>/`.

The contents of `scaffold/<lang>/` fall into three categories:

| Category | Typical files | Purpose |
| --- | --- | --- |
| State machine skeleton | `.agent-workflow/AGENTS.md`, `.agent-workflow/docs/stage.lock`, `.agent-workflow/docs/workflow/stage*.md` | Defines the agent's fixed operating protocol |
| Project fact templates | `.agent-workflow/docs/overview.md`, `.agent-workflow/docs/architecture.md`, `.agent-workflow/docs/conventions.md`, `.agent-workflow/docs/quality.md`, `.agent-workflow/docs/security.md`, `.agent-workflow/docs/progress.md`, `.agent-workflow/docs/plan/backlog.md` | Filled by AI based on target repository content during initialization |
| Harness scripts | `.agent-workflow/scripts/build_context.py`, `.agent-workflow/scripts/run_issue_tests.sh`, `.agent-workflow/issue_test/README.md` | Turn "what to read" and "how to verify" into fixed scripts |

In short:

- `scaffold/` determines "what a new repository will look like after initialization"
- `.agent-workflow/docs/` determines "what this repository looks like right now"

## Run Model

If there are no errors and no blockers, a single agent run may continue across multiple issue loops.

The standard cycle is:

1. Read `.agent-workflow/AGENTS.md`
2. Read `.agent-workflow/docs/stage.lock`
3. Execute `python3 .agent-workflow/scripts/build_context.py --stage <current>`
4. Read all context files from the output
5. Execute `.agent-workflow/docs/workflow/<current>.md`
6. Update `.agent-workflow/docs/stage.lock`
7. If returning to `current: stage1` with `status: done` and `previous: stage6`, this run ends

This means:

- Picking multiple backlog issues in the same run is not allowed.
- Any Stage failure requires writing `.agent-workflow/docs/blockers.md` and stopping.
- By default, `stage.lock` only needs to be updated locally; make a separate commit only if the team explicitly tracks workflow state files.
- New tasks must enter `.agent-workflow/docs/plan/backlog.md` first, then Stage 2 converts them to `current.md` and `.agent-workflow/issue_test/<issue_id>.sh`.

## Stage Input Model

`.agent-workflow/scripts/build_context.py` first injects global context, then injects incremental context per Stage.

All Stages load:

- `.agent-workflow/docs/overview.md`
- `.agent-workflow/docs/architecture.md`
- `.agent-workflow/docs/conventions.md`
- `.agent-workflow/issue_test/README.md`
- `.agent-workflow/docs/wisdom.md`, `.agent-workflow/docs/antipatterns.md` (if they exist)

Incremental inputs per Stage:

| Stage | Additional inputs |
| --- | --- |
| Stage 1 | `.agent-workflow/docs/stage.lock`, `.agent-workflow/docs/progress.md`, `.agent-workflow/docs/blockers.md`, `.agent-workflow/docs/plan/current.md`, `.agent-workflow/docs/workflow/stage1.md` |
| Stage 2 | `.agent-workflow/docs/plan/backlog.md`, `.agent-workflow/docs/decisions.md`, `.agent-workflow/docs/workflow/stage2.md` |
| Stage 3 | `.agent-workflow/docs/plan/current.md`, `.agent-workflow/docs/security.md`, `.agent-workflow/issue_test/<issue_id>.sh`, `.agent-workflow/docs/workflow/stage3.md` |
| Stage 4 | `.agent-workflow/docs/plan/current.md`, `.agent-workflow/docs/quality.md`, `.agent-workflow/issue_test/<issue_id>.sh`, `.agent-workflow/docs/workflow/stage4.md` |
| Stage 5 | `.agent-workflow/docs/decisions.md`, `.agent-workflow/docs/plan/archive/<issue_id>.md`, `.agent-workflow/docs/workflow/stage5.md` |
| Stage 6 | `.agent-workflow/docs/progress.md`, `.agent-workflow/docs/decisions.md`, `.agent-workflow/docs/plan/archive/<issue_id>.md`, `.agent-workflow/docs/workflow/stage6.md` |

The key design: each Stage reads only the files it actually needs, preventing the agent from wandering through irrelevant documents.

## Stage Flow Diagram

```mermaid
flowchart TD
    S1["Stage 1<br/>Context Loading / Router"] -->|current.md empty or complete| S2["Stage 2<br/>Task Planning"]
    S1 -->|current.md has unfinished steps| S3["Stage 3<br/>Implementation"]
    S1 -->|status=failed or uncleared blockers| STOP["Stop and wait for human"]
    S1 -->|stage1/done and previous=stage6| END["Run ends successfully"]

    S2 --> S3

    S3 -->|full issue regression passes| S4["Stage 4<br/>Delivery & Verification"]
    S3 -->|same error fixed more than 3 times<br/>or issue test validity unclear| STOP

    S4 -->|final regression fails| S3
    S4 -->|PR ready or handoff written| S5["Stage 5<br/>Reflection"]
    S4 -->|cannot form deliverable local commit| STOP

    S5 --> S6["Stage 6<br/>Entropy Check"]
    S5 -->|REFLECT missing or incomplete| STOP

    S6 -->|docs-only change and merge/auto-merge succeeds| END
    S6 -->|merge blocked but handoff complete| END
    S6 -->|entropy check found code changes| S3
    S6 -->|cannot determine whether docs or code is correct| STOP
```

## Input, Output, and Modification Surface Per Stage

| Stage | Input | Output | What it modifies |
| --- | --- | --- | --- |
| Stage 1 | `stage.lock`, `progress.md`, `blockers.md`, `plan/current.md` | Routing result: end current run, or proceed to Stage 2 / Stage 3 | `.agent-workflow/docs/stage.lock` |
| Stage 2 | `plan/backlog.md`, `decisions.md`, `overview.md`, `antipatterns.md` | Determined `issue_id`, switched to the issue's branch, created issue test, written `current.md`, state advanced to Stage 3 | Current git branch, `.agent-workflow/issue_test/<issue_id>.sh`, `.agent-workflow/docs/plan/current.md`, `.agent-workflow/docs/stage.lock`, optionally `.agent-workflow/docs/overview.md` and `.agent-workflow/docs/decisions.md` |
| Stage 3 | `plan/current.md`, `security.md`, current issue test, historical issue tests, business code | Code implementation complete, full regression passes, state advanced to Stage 4 | Business code, tests, `.agent-workflow/docs/plan/current.md`, `.agent-workflow/docs/stage.lock`, optionally `.agent-workflow/docs/architecture.md` and `.agent-workflow/docs/decisions.md` |
| Stage 4 | `plan/current.md`, `quality.md`, full regression results, remote git state | Local commit, PR URL or manual handoff, progress update, plan archived, state advanced to Stage 5 | Git history, `.agent-workflow/docs/progress.md`, `.agent-workflow/docs/plan/archive/<issue_id>.md`, `.agent-workflow/docs/plan/current.md`, `.agent-workflow/docs/plan/backlog.md`, `.agent-workflow/docs/stage.lock` |
| Stage 5 | `decisions.md`, archived plan, current issue context | Reflection result, REFLECT file, reusable patterns or antipatterns, state advanced to Stage 6 | `.agent-workflow/docs/plan/archive/REFLECT-<issue_id>.md`, `.agent-workflow/docs/wisdom.md`, `.agent-workflow/docs/antipatterns.md`, `.agent-workflow/docs/stage.lock`, optionally `.agent-workflow/docs/decisions.md`, `.agent-workflow/docs/architecture.md`, `.agent-workflow/docs/conventions.md` |
| Stage 6 | All docs, `progress.md`, `decisions.md`, `plan/archive/<issue_id>.md`, code state, PR state | Docs and code aligned; if docs-only, attempt final merge/auto-merge and end run; if code changed, return to Stage 3 | `.agent-workflow/docs/*.md`, `.agent-workflow/docs/stage.lock`, optionally append to `.agent-workflow/docs/plan/archive/<issue_id>.md`, and final remote merge state |

## Core Constraints of This Template

- One issue per run.
- Every issue must be bound to an `.agent-workflow/issue_test/<issue_id>.sh`.
- Historical issue tests are retained indefinitely; hiding regressions by deleting or weakening old tests is not allowed.
- Every `.agent-workflow/docs/stage.lock` update must be a separate commit.
- Any blocker requires writing `.agent-workflow/docs/blockers.md` and stopping.
- Documentation is not a manual — it is the agent's runtime input.

If you can only remember one sentence, remember this:

> `init.sh` loads the template into the target repository. `stage.lock` drives the state machine. `build_context.py` feeds context. `.agent-workflow/issue_test/*.sh` turns each issue's acceptance criteria into executable scripts.

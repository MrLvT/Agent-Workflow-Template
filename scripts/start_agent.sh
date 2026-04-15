#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW_DIR="${ROOT_DIR}/.agent-workflow"
MAX_RUNS="${CODEX_MAX_RUNS:-20}"
RUN_COUNT=0
VERBOSE="${CODEX_LAUNCHER_VERBOSE:-0}"

usage() {
    cat <<'EOF'
Usage:
  bash scripts/start_agent.sh [--once] [--max-runs <n>] [--verbose]

This helper supervises repeated fresh Codex sessions for an initialized
repository that already contains `.agent-workflow/`.
Set `CODEX_LAUNCHER_VERBOSE=1` or pass `--verbose` if you want launcher logs.
EOF
}

note() {
    if [[ "$VERBOSE" == "1" ]]; then
        printf '[start_agent] %s\n' "$*" >&2
    fi
}

read_lock_field() {
    local field="$1"
    local lock_file="$WORKFLOW_DIR/docs/stage.lock"
    [[ -f "$lock_file" ]] || return 1
    sed -n "s/^${field}:[[:space:]]*//p" "$lock_file" | head -n 1 | tr -d '[:space:]'
}

has_open_checklist_items() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    grep -Eq '^[[:space:]]*-[[:space:]]*\[[[:space:]]\]' "$file"
}

has_unresolved_blockers() {
    local blockers_file="$WORKFLOW_DIR/docs/blockers.md"
    local body

    [[ -f "$blockers_file" ]] || return 1

    body="$(
        awk '
            /^## (当前阻塞|Current Blockers)/ {capture=1; next}
            /^## / && capture {exit}
            capture {print}
        ' "$blockers_file" | sed '/^[[:space:]]*$/d'
    )"

    [[ -n "$body" && "$body" != "（无）" && "$body" != "(none)" ]]
}

has_pending_work() {
    has_open_checklist_items "$WORKFLOW_DIR/docs/plan/current.md" || \
        has_open_checklist_items "$WORKFLOW_DIR/docs/plan/backlog.md"
}

launcher_prompt() {
    cat <<'EOF'
Read .agent-workflow/AGENTS.md, then start working.

Runtime constraint:
- This is a fresh Codex session launched by `.agent-workflow/scripts/start_agent.sh`.
- This session may begin from `current: stage1`, `status: done`, `previous: stage6` and route into the next issue.
- If the previous issue already closed and git is still on that issue branch, treat it as a normal local continuation point as long as the working tree is clean; the next issue branch may be created directly from the current HEAD.
- After this session completes one new issue loop and returns to `current: stage1`, `status: done`, `previous: stage6` again, stop instead of claiming more issues.
- The outer launcher will then restart a brand-new session so context is cleared before the next issue.
EOF
}

should_restart_fresh() {
    local current status previous

    current="$(read_lock_field current || true)"
    status="$(read_lock_field status || true)"
    previous="$(read_lock_field previous || true)"

    if [[ "$status" == "failed" ]]; then
        echo "failed"
        return
    fi

    if has_unresolved_blockers; then
        echo "blocked"
        return
    fi

    if [[ "$current" == "stage1" && "$status" == "done" && "$previous" == "stage6" ]]; then
        if has_pending_work; then
            echo "restart"
        else
            echo "complete"
        fi
        return
    fi

    echo "stop"
}

if ! command -v codex >/dev/null 2>&1; then
    echo "ERROR: codex CLI not found in PATH." >&2
    exit 1
fi

[[ -d "$WORKFLOW_DIR" ]] || {
    echo "ERROR: .agent-workflow/ not found under $ROOT_DIR." >&2
    echo "Use this helper inside an initialized repository, or run bash init.sh first." >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --once)
            MAX_RUNS=1
            shift
            ;;
        --max-runs)
            [[ $# -ge 2 ]] || {
                echo "ERROR: --max-runs requires a non-negative integer or 0 (no limit)." >&2
                exit 1
            }
            MAX_RUNS="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "ERROR: unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

[[ "$MAX_RUNS" =~ ^[0-9]+$ ]] || {
    echo "ERROR: --max-runs must be a non-negative integer." >&2
    exit 1
}

cd "$ROOT_DIR"
while true; do
    RUN_COUNT=$((RUN_COUNT + 1))

    if [[ "$MAX_RUNS" -gt 0 && "$RUN_COUNT" -gt "$MAX_RUNS" ]]; then
        note "Reached the max session count ($MAX_RUNS); stopping auto-restart."
        exit 0
    fi

    note "Starting fresh Codex session #${RUN_COUNT}..."

    codex \
        -a never \
        --sandbox danger-full-access \
        -C "$ROOT_DIR" \
        "$(launcher_prompt)"

    case "$(should_restart_fresh)" in
        restart)
            note "One issue loop finished; pending work remains, so a fresh session will start next."
            ;;
        complete)
            note "The current issue finished and no further pending work was detected. Stopping."
            exit 0
            ;;
        blocked)
            echo "[start_agent] Blockers are present; stopping auto-restart until a human resolves them." >&2
            exit 1
            ;;
        failed)
            echo "[start_agent] stage.lock is marked failed; stopping auto-restart." >&2
            exit 1
            ;;
        stop)
            note "Workflow did not return to a safe stage1/done restart point; stopping auto-restart."
            exit 0
            ;;
    esac
done

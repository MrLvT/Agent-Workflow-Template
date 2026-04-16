#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="$(cd "${WORKFLOW_DIR}/.." && pwd)"
MAX_RUNS="${CODEX_MAX_RUNS:-20}"
RUN_COUNT=0
VERBOSE="${CODEX_LAUNCHER_VERBOSE:-0}"
RESTART_GRACE_SECONDS="${CODEX_RESTART_GRACE_SECONDS:-2}"
STOP_REQUESTED=0

usage() {
    cat <<'EOF'
Usage:
  bash .agent-workflow/scripts/start_agent.sh [--once] [--max-runs <n>] [--verbose]

Behavior:
  - Runs Codex in fresh-session mode
  - Each Codex session may complete at most one new issue loop
  - If another backlog/current task remains after Stage 6 returns to stage1/done,
    the launcher starts a brand-new Codex session before the next issue
  - By default, keep the normal Codex interactive UI; set `CODEX_LAUNCHER_VERBOSE=1` for launcher logs
  - Before auto-restarting, the launcher waits a short grace window; press `Ctrl+C` there if you want to stop the launcher too
EOF
}

note() {
    if [[ "$VERBOSE" == "1" ]]; then
        printf '[start_agent] %s\n' "$*" >&2
    fi
}

request_stop() {
    STOP_REQUESTED=1
}

restart_grace_window() {
    local seconds="$1"

    if [[ "$seconds" -le 0 ]]; then
        return
    fi

    echo "[start_agent] Session ended. Press Ctrl+C within ${seconds}s to stop auto-restart." >&2
    sleep "$seconds" || true
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

[[ "$RESTART_GRACE_SECONDS" =~ ^[0-9]+$ ]] || {
    echo "ERROR: CODEX_RESTART_GRACE_SECONDS must be a non-negative integer." >&2
    exit 1
}

trap 'request_stop' INT TERM

cd "$REPO_DIR"
while true; do
    if [[ "$STOP_REQUESTED" == "1" ]]; then
        note "Interrupt requested before starting the next fresh session. Stopping."
        exit 130
    fi

    RUN_COUNT=$((RUN_COUNT + 1))

    if [[ "$MAX_RUNS" -gt 0 && "$RUN_COUNT" -gt "$MAX_RUNS" ]]; then
        note "Reached the max session count ($MAX_RUNS); stopping auto-restart."
        exit 0
    fi

    note "Starting fresh Codex session #${RUN_COUNT}..."

    set +e
    codex \
        -a never \
        --sandbox danger-full-access \
        -C "$REPO_DIR" \
        "$(launcher_prompt)"
    codex_status=$?
    set -e

    if [[ "$STOP_REQUESTED" == "1" || "$codex_status" == "130" || "$codex_status" == "143" ]]; then
        echo "[start_agent] Interrupted by user; stopping auto-restart." >&2
        exit 130
    fi

    if [[ "$codex_status" -ne 0 ]]; then
        echo "[start_agent] codex exited with status $codex_status; stopping auto-restart." >&2
        exit "$codex_status"
    fi

    case "$(should_restart_fresh)" in
        restart)
            restart_grace_window "$RESTART_GRACE_SECONDS"
            if [[ "$STOP_REQUESTED" == "1" ]]; then
                echo "[start_agent] Auto-restart cancelled by user." >&2
                exit 130
            fi
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

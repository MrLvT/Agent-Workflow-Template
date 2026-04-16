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
用法：
  bash .agent-workflow/scripts/start_agent.sh [--once] [--max-runs <n>] [--verbose]

行为：
  - 以 fresh-session 模式运行 Codex
  - 每个 Codex session 最多只完整闭环一个新 issue
  - 若 Stage 6 回到 stage1/done 后仍有 backlog/current 待处理任务，
    启动器会先结束当前 session，再拉起一个全新的 Codex session
  - 默认尽量保持 Codex 原始交互界面；若需要壳层状态日志，可设 `CODEX_LAUNCHER_VERBOSE=1`
  - 自动重启前会有一个很短的缓冲窗口；若想连启动器一起停掉，请在该窗口内按 `Ctrl+C`
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

    echo "[start_agent] 当前 session 已结束；若要停止自动重启，请在 ${seconds}s 内按 Ctrl+C。" >&2
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
读 .agent-workflow/AGENTS.md，然后开始工作。

运行时约束：
- 这是由 `.agent-workflow/scripts/start_agent.sh` 拉起的全新 Codex session。
- 本 session 允许从 `current: stage1`、`status: done`、`previous: stage6` 开始，继续路由到下一个 issue。
- 若上一个 issue 已闭环且 git 仍停留在那个 issue 分支，只要工作区干净，就把它视为正常的本地连续交付起点；下一个 issue 分支可以直接从当前 HEAD 派生。
- 当本 session 完成一个新的 issue 闭环，并再次回到 `current: stage1`、`status: done`、`previous: stage6` 时，请停止当前 session，不要继续领取更多 issue。
- 停止后由外层启动脚本重启一个全新的 session，以清空上下文后再继续。
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
    echo "ERROR: 未找到 codex CLI，请先确认它已安装并且在 PATH 中。" >&2
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
                echo "ERROR: --max-runs 需要一个正整数或 0（表示不设上限）。" >&2
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
            echo "ERROR: 未知参数：$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

[[ "$MAX_RUNS" =~ ^[0-9]+$ ]] || {
    echo "ERROR: --max-runs 必须是非负整数。" >&2
    exit 1
}

[[ "$RESTART_GRACE_SECONDS" =~ ^[0-9]+$ ]] || {
    echo "ERROR: CODEX_RESTART_GRACE_SECONDS 必须是非负整数。" >&2
    exit 1
}

trap 'request_stop' INT TERM

cd "$REPO_DIR"
while true; do
    if [[ "$STOP_REQUESTED" == "1" ]]; then
        note "收到中断请求，不再启动新的 session。"
        exit 130
    fi

    RUN_COUNT=$((RUN_COUNT + 1))

    if [[ "$MAX_RUNS" -gt 0 && "$RUN_COUNT" -gt "$MAX_RUNS" ]]; then
        note "已达到最大 session 数：$MAX_RUNS，停止自动重启。"
        exit 0
    fi

    note "启动第 ${RUN_COUNT} 个全新 Codex session..."

    set +e
    codex \
        -a never \
        --sandbox danger-full-access \
        -C "$REPO_DIR" \
        "$(launcher_prompt)"
    codex_status=$?
    set -e

    if [[ "$STOP_REQUESTED" == "1" || "$codex_status" == "130" || "$codex_status" == "143" ]]; then
        echo "[start_agent] 检测到用户中断，停止自动重启。" >&2
        exit 130
    fi

    if [[ "$codex_status" -ne 0 ]]; then
        echo "[start_agent] codex 退出码为 $codex_status，停止自动重启。" >&2
        exit "$codex_status"
    fi

    case "$(should_restart_fresh)" in
        restart)
            restart_grace_window "$RESTART_GRACE_SECONDS"
            if [[ "$STOP_REQUESTED" == "1" ]]; then
                echo "[start_agent] 已按用户请求取消自动重启。" >&2
                exit 130
            fi
            note "已完成一个 issue；检测到仍有待处理任务，准备以全新上下文继续下一轮。"
            ;;
        complete)
            note "当前 issue 已完成，且没有新的待处理任务，停止。"
            exit 0
            ;;
        blocked)
            echo "[start_agent] 检测到 blockers，停止自动重启，等待人类处理。" >&2
            exit 1
            ;;
        failed)
            echo "[start_agent] stage.lock 标记为 failed，停止自动重启。" >&2
            exit 1
            ;;
        stop)
            note "当前 workflow 未回到可安全重启的 stage1/done 状态，停止自动重启。"
            exit 0
            ;;
    esac
done

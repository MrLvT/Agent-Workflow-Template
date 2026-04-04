#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v codex >/dev/null 2>&1; then
    echo "ERROR: 未找到 codex CLI，请先确认它已安装并且在 PATH 中。" >&2
    exit 1
fi

cd "$ROOT_DIR"
exec codex -a never --sandbox workspace-write "读 AGENTS.md，然后开始工作。"

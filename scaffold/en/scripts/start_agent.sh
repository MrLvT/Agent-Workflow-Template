#!/usr/bin/env bash
set -euo pipefail

WORKFLOW_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_DIR="$(cd "${WORKFLOW_DIR}/.." && pwd)"

if ! command -v codex >/dev/null 2>&1; then
    echo "ERROR: codex CLI not found in PATH." >&2
    exit 1
fi

cd "$REPO_DIR"
exec codex -a never --sandbox danger-full-access "Read .agent-workflow/AGENTS.md, then start working."

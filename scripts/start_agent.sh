#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

if ! command -v codex >/dev/null 2>&1; then
    echo "ERROR: codex CLI not found in PATH." >&2
    exit 1
fi

cd "$ROOT_DIR"
exec codex -a never --sandbox danger-full-access "Read AGENTS.md, then start working."

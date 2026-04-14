#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOW_DIR_NAME=".agent-workflow"
TARGET_REPO="."
LANG_CHOICE="auto"
DRY_RUN=0

RULE_FILES=(
    "AGENTS.md"
    "docs/workflow/stage1.md"
    "docs/workflow/stage2.md"
    "docs/workflow/stage3.md"
    "docs/workflow/stage4.md"
    "docs/workflow/stage5.md"
    "docs/workflow/stage6.md"
    "docs/plan/archive/README.md"
    "issue_test/README.md"
    "scripts/build_context.py"
    "scripts/start_agent.sh"
    "scripts/run_issue_tests.sh"
    "scripts/deliver_pr.sh"
)

BOOTSTRAP_IF_MISSING=(
    "docs/environment.md"
    "docs/run_log.md"
)

MANUAL_REVIEW_FILES=(
    "docs/conventions.md"
    "docs/quality.md"
    "docs/environment.md"
)

EXECUTABLE_FILES=(
    "scripts/build_context.py"
    "scripts/start_agent.sh"
    "scripts/run_issue_tests.sh"
    "scripts/deliver_pr.sh"
)

UPDATED_FILES=()
CREATED_FILES=()
UNCHANGED_FILES=()
BOOTSTRAPPED_FILES=()

backup_root=""

usage() {
    cat <<'EOF'
Usage:
  bash scripts/upgrade_workflow_rules.sh [--repo <path>] [--lang auto|zh|en|default] [--dry-run]
  bash scripts/upgrade_workflow_rules.sh <repo-path>

Safely upgrades template-owned workflow rule files inside an existing
.agent-workflow/ sidecar without touching workflow state/history files such as:
  - docs/stage.lock
  - docs/blockers.md
  - docs/plan/current.md
  - docs/plan/archive/*
  - docs/progress.md
  - docs/decisions.md
  - results/

Behavior:
  - Syncs rule files from scaffold/<lang>/ into <repo>/.agent-workflow/
  - Creates docs/environment.md and docs/run_log.md only if they are missing
  - Ensures /.agent-workflow/ is listed in .git/info/exclude
  - Warns when the target workflow is mid-run, but does not reset it
EOF
}

note() {
    printf '[upgrade] %s\n' "$*"
}

warn() {
    printf '[upgrade] WARN: %s\n' "$*" >&2
}

die() {
    printf '[upgrade] ERROR: %s\n' "$*" >&2
    exit 1
}

ensure_backup_root() {
    if [[ -n "$backup_root" ]]; then
        return
    fi
    backup_root="$GIT_DIR/.agent-workflow-upgrade/backups/$timestamp"
    mkdir -p "$backup_root"
}

record_change() {
    local bucket="$1"
    local rel_path="$2"
    case "$bucket" in
        updated) UPDATED_FILES+=("$rel_path") ;;
        created) CREATED_FILES+=("$rel_path") ;;
        unchanged) UNCHANGED_FILES+=("$rel_path") ;;
        bootstrapped) BOOTSTRAPPED_FILES+=("$rel_path") ;;
        *) die "Unknown change bucket: $bucket" ;;
    esac
}

copy_synced_file() {
    local rel_path="$1"
    local src="$SOURCE_ROOT/$rel_path"
    local dst="$WORKFLOW_ROOT/$rel_path"

    [[ -f "$src" ]] || die "Template file missing: $src"

    if [[ -f "$dst" ]] && cmp -s "$src" "$dst"; then
        record_change unchanged "$rel_path"
        return
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        if [[ -e "$dst" ]]; then
            record_change updated "$rel_path"
        else
            record_change created "$rel_path"
        fi
        return
    fi

    mkdir -p "$(dirname "$dst")"
    if [[ -f "$dst" ]]; then
        ensure_backup_root
        mkdir -p "$backup_root/$(dirname "$rel_path")"
        cp "$dst" "$backup_root/$rel_path"
        cp "$src" "$dst"
        record_change updated "$rel_path"
    else
        cp "$src" "$dst"
        record_change created "$rel_path"
    fi
}

copy_if_missing() {
    local rel_path="$1"
    local src="$SOURCE_ROOT/$rel_path"
    local dst="$WORKFLOW_ROOT/$rel_path"

    [[ -f "$src" ]] || die "Template file missing: $src"

    if [[ -e "$dst" ]]; then
        return
    fi

    if [[ "$DRY_RUN" -eq 1 ]]; then
        record_change bootstrapped "$rel_path"
        return
    fi

    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    record_change bootstrapped "$rel_path"
}

ensure_exclude_pattern() {
    local pattern="/$WORKFLOW_DIR_NAME/"
    local exclude_file="$GIT_DIR/info/exclude"

    if [[ -f "$exclude_file" ]] && grep -Fqx "$pattern" "$exclude_file"; then
        EXCLUDE_RESULT="kept"
        return
    fi

    EXCLUDE_RESULT="added"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        return
    fi

    mkdir -p "$(dirname "$exclude_file")"
    touch "$exclude_file"
    if [[ -s "$exclude_file" ]]; then
        printf '\n%s\n' "$pattern" >>"$exclude_file"
    else
        printf '%s\n' "$pattern" >"$exclude_file"
    fi
}

detect_language() {
    local agents_file="$WORKFLOW_ROOT/AGENTS.md"

    if [[ ! -f "$agents_file" ]]; then
        printf 'zh'
        return
    fi

    if grep -q '^## Startup Protocol' "$agents_file"; then
        printf 'en'
    else
        printf 'zh'
    fi
}

resolve_source_root() {
    local resolved_lang="$LANG_CHOICE"

    if [[ "$resolved_lang" == "auto" ]]; then
        resolved_lang="$(detect_language)"
    fi

    case "$resolved_lang" in
        zh)
            SOURCE_ROOT="$ROOT_DIR/scaffold/zh"
            ;;
        en)
            SOURCE_ROOT="$ROOT_DIR/scaffold/en"
            ;;
        default|base)
            SOURCE_ROOT="$ROOT_DIR/scaffold"
            ;;
        *)
            die "Unsupported language choice: $resolved_lang"
            ;;
    esac

    [[ -d "$SOURCE_ROOT" ]] || die "Template scaffold not found: $SOURCE_ROOT"
    RESOLVED_LANG="$resolved_lang"
}

print_state_warning() {
    local lock_file="$WORKFLOW_ROOT/docs/stage.lock"
    local current_stage=""
    local status=""

    if [[ ! -f "$lock_file" ]]; then
        warn "Target workflow has no docs/stage.lock. Continuing with rule sync only."
        return
    fi

    current_stage="$(sed -n 's/^current:[[:space:]]*//p' "$lock_file" | head -n1 | tr -d '[:space:]')"
    status="$(sed -n 's/^status:[[:space:]]*//p' "$lock_file" | head -n1 | tr -d '[:space:]')"

    if [[ "$current_stage" == "stage1" && "$status" == "done" ]]; then
        note "Target workflow looks idle (stage1/done)."
        return
    fi

    warn "Target workflow is currently at current=${current_stage:-unknown}, status=${status:-unknown}."
    warn "This script will preserve state/history files and only update template-owned rule files."
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            [[ $# -ge 2 ]] || die "--repo requires a path"
            TARGET_REPO="$2"
            shift 2
            ;;
        --lang)
            [[ $# -ge 2 ]] || die "--lang requires auto, zh, en, or default"
            LANG_CHOICE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            die "Unknown option: $1"
            ;;
        *)
            if [[ "$TARGET_REPO" != "." ]]; then
                die "Unexpected extra argument: $1"
            fi
            TARGET_REPO="$1"
            shift
            ;;
    esac
done

TARGET_REPO="$(cd "$TARGET_REPO" && pwd)"

git -C "$TARGET_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "Target is not a Git repository: $TARGET_REPO"

git_dir_raw="$(git -C "$TARGET_REPO" rev-parse --git-dir)"
if [[ "$git_dir_raw" = /* ]]; then
    GIT_DIR="$git_dir_raw"
else
    GIT_DIR="$TARGET_REPO/$git_dir_raw"
fi

WORKFLOW_ROOT="$TARGET_REPO/$WORKFLOW_DIR_NAME"
[[ -d "$WORKFLOW_ROOT" ]] || die "Target workflow directory not found: $WORKFLOW_ROOT"

resolve_source_root
timestamp="$(date -u +"%Y%m%dT%H%M%SZ")"
EXCLUDE_RESULT="kept"

note "Target repository: $TARGET_REPO"
note "Workflow directory: $WORKFLOW_ROOT"
note "Using scaffold source: $SOURCE_ROOT"
[[ "$DRY_RUN" -eq 1 ]] && note "Dry run enabled; no files will be changed."

print_state_warning

for rel_path in "${RULE_FILES[@]}"; do
    copy_synced_file "$rel_path"
done

for rel_path in "${BOOTSTRAP_IF_MISSING[@]}"; do
    copy_if_missing "$rel_path"
done

ensure_exclude_pattern

if [[ "$DRY_RUN" -eq 0 ]]; then
    for rel_path in "${EXECUTABLE_FILES[@]}"; do
        if [[ -f "$WORKFLOW_ROOT/$rel_path" ]]; then
            chmod +x "$WORKFLOW_ROOT/$rel_path"
        fi
    done
fi

printf '\n'
note "Upgrade summary"
note "  synced language: $RESOLVED_LANG"
note "  updated files: ${#UPDATED_FILES[@]}"
note "  created files: ${#CREATED_FILES[@]}"
note "  bootstrapped missing files: ${#BOOTSTRAPPED_FILES[@]}"
note "  unchanged files: ${#UNCHANGED_FILES[@]}"
note "  .git/info/exclude entry: $EXCLUDE_RESULT"
if [[ -n "$backup_root" ]]; then
    note "  backups written under: $backup_root"
fi

for rel_path in "${UPDATED_FILES[@]}"; do
    note "  updated: $rel_path"
done

for rel_path in "${CREATED_FILES[@]}"; do
    note "  created: $rel_path"
done

for rel_path in "${BOOTSTRAPPED_FILES[@]}"; do
    note "  bootstrapped: $rel_path"
done

printf '\n'
note "Preserved state/history files were not touched, including:"
note "  docs/stage.lock, docs/blockers.md, docs/plan/current.md, docs/plan/archive/*,"
note "  docs/progress.md, docs/decisions.md, results/"

printf '\n'
note "Manual review is still recommended for project-specific docs:"
for rel_path in "${MANUAL_REVIEW_FILES[@]}"; do
    note "  template: $SOURCE_ROOT/$rel_path"
    note "  target:   $WORKFLOW_ROOT/$rel_path"
done

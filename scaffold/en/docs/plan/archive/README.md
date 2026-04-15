# Archive

This directory stores completed issue plans and reflection records.

`run_log.md` records whole-run goals, work, and results; `results/.../SUMMARY.md` records experiment setup, outcomes, and analysis; this directory keeps only per-issue archives and reflections.

## File Naming

- `<issue_id>.md` — archived `current.md` for a completed issue
- `REFLECT-<issue_id>.md` — Stage 5 reflection record for a completed issue

## Retention Policy

Archive files are retained permanently. They serve as a historical reference for decision context, workflow patterns, and regression coverage.

When archiving a completed issue, also record the local commit hash, verification conclusion, and the next human step when needed. If an issue actually executed result-producing experiments, evaluations, benchmarks, or exploratory smoke tests, the archive should also record the result directory `results/issue<issue_id>/` and the `SUMMARY.md` path.

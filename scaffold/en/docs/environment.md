# Environment

> This document answers: Where does this project usually run, and what environment prerequisites must be satisfied first?

## Execution Environment Summary (to be filled)

- Default runtime environment: `local / slurm / docker / k8s / cloud VM / other`
- Package management: `conda / venv / poetry / uv / other`
- Primary execution entrypoint: `python / bash / make / sbatch / srun / other`
- Typical execution location: `local terminal / login node / compute node / inside container`

## Resource and System Constraints (to be filled)

- OS / distribution:
- Python / runtime version:
- GPU / CUDA requirements:
- Storage constraints (shared disk / local disk / temp dirs):
- Network constraints (internet / intranet only / offline):

## Required Preparation Steps (to be filled)

1. Activate environment, e.g. `conda activate agent`
2. Load modules or dependencies, e.g. `module load cuda`
3. Switch execution location, e.g. "training must run on Slurm compute nodes"
4. Other prerequisites: env vars, credentials, mounted directories

## Scheduler and Job Conventions (to be filled)

- Must jobs go through a scheduler:
- Scheduler type: `slurm / k8s / other / currently not configured`
- Submit command:
- Interactive command:
- How to inspect logs:

## Minimum Verification Command (to be filled)

```bash
# Example: confirm the current environment can run the minimum check
<command>
```

## Known Limitations (to be filled)

- Example: login nodes must not run long jobs directly
- Example: only specific queues can request GPU
- Example: dependencies are missing unless the conda environment is activated first

## Maintenance Rules

1. Any environment fact that changes how work must be executed belongs here instead of only in chat context.
2. If a later run discovers that reality differs from this document, update this file immediately and append to `.agent-workflow/docs/decisions.md` when needed.
3. If a fact is not yet confirmed, write `to be confirmed` or `currently not configured` explicitly; never rely on hidden assumptions.

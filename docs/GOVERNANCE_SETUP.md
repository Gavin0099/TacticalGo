# Governance setup (ai-governance-framework)

Status: **adopted as a pinned submodule; full_candidate by the framework's own report. Runtime enforcement is not proven.**
Decision record: `docs/DECISIONS.md` ("full governance adoption").

## What is in the repository (travels with `git clone`)

- `additional/ai-governance-framework` — submodule, pinned to a specific commit (see `git submodule status`).
- `.gitmodules`, `.governance/baseline.yaml`, `AGENTS.base.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `contract.yaml`,
  `governance/`, `memory/`, `validators/golden_fixture_validator.py`, `.github/workflows/governance-drift.yml`,
  `.github/hooks/` and `.github/copilot-instructions.md` (framework-managed blocks are marked BEGIN/END).

## What is NOT in the repository (each clone must set it up)

Git hooks live in `.git/hooks` and are never cloned. After cloning:

```bash
git clone --recurse-submodules https://github.com/Gavin0099/TacticalGo.git
cd TacticalGo
# if you forgot --recurse-submodules:
git submodule update --init --recursive
# install the local, advisory pre-commit / pre-push hooks
cd additional/ai-governance-framework
python -m governance_tools.hook_installer --repo ../.. --framework-root . --hooks-only
```

Without this step `external_repo_readiness.py` reports `hooks_ready = False` (expected on a fresh clone).

## Checks you can run

```bash
FW=additional/ai-governance-framework
python $FW/governance_tools/governance_drift_checker.py --repo . --framework-root $FW           # expect severity = ok
python $FW/governance_tools/external_repo_readiness.py --repo . --framework-root $FW --format human   # expect ready = True
python validators/golden_fixture_validator.py .                                                # golden fixtures vs engine vocabulary
```

## Updating the framework

The submodule pointer is this repository's decision. Use the framework's governed path, not a manual `git checkout`:

```bash
cd additional/ai-governance-framework
python governance_tools/f7_full_update.py --repo ../.. --framework-root . \
  --submodule-path additional/ai-governance-framework --format human        # dry run
# add --apply only after reviewing the dry run, with a clean index
```

## Known limits (do not over-claim)

- Hooks are local and advisory (a memory-workflow warning does not block a commit).
- The drift workflow runs only manually or on pull requests touching governance files. PR #1 at `761af5d` was observed successful on GitHub on 2026-10-08: https://github.com/Gavin0099/TacticalGo/actions/runs/37741378903/job/113192626883 . This is not CI evidence for the local R1 branch.
- `readiness` still shows three `framework_version` warnings: a submodule consumer does not write `framework.lock.json`.
- `.governance/baseline.yaml` and `governance/.update-receipt.json` are tool-generated and contain this machine's absolute paths.
- Governance does not prove domain correctness, runtime enforcement, memory completeness or release readiness.

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

### Clones vs linked worktrees (read before installing hooks)

Hooks and `ai-governance-framework-root` live in the Git *common* directory, which every linked worktree of one clone
shares (unless `core.hooksPath` or worktree-specific config says otherwise). So:

- Install hooks once per **clone**, not once per worktree. Check the real location first:
  `git rev-parse --git-path hooks` and `git config --get core.hooksPath`.
- A linked worktree of a clone that already has hooks needs no install; verify with `external_repo_readiness.py`
  (expect `hooks_ready = True`) instead of re-running the installer.
- F-7 `--apply` refuses to run from a linked worktree. Run it from the primary worktree of a clone; if that worktree has
  uncommitted work, use a separate clone.

## Checks you can run

```bash
FW=additional/ai-governance-framework
python $FW/governance_tools/governance_drift_checker.py --repo . --framework-root $FW           # expect severity = ok
python $FW/governance_tools/external_repo_readiness.py --repo . --framework-root $FW --format human   # expect ready = True
python validators/golden_fixture_validator.py .                                                # golden fixtures vs engine vocabulary + action arguments
python -m unittest discover -s validators -p "test_*.py"                                       # validator negative tests
python validators/hook_wiring_check.py .                                                       # VS Code Stop must not close out a session
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

- **GitHub Actions had been disabled at repository level** (API `actions/permissions` returned `enabled=false` on
  2026-10-14, so PR #7 showed 0 checks). A `pull_request` run of `governance-drift.yml` did succeed on 2026-10-08, so it
  was switched off afterwards. It was re-enabled on 2026-10-14 with `allowed_actions=selected` (GitHub-owned actions
  only) and read-only default workflow permissions. Evidence: `artifacts/governance/ci-run-38574137791.json`.
- **The managed VS Code `Stop` hook is deliberately not shipped** (`.github/hooks/ai-governance-vscode.json` removed,
  manifest entry dropped). VS Code documents `Stop` as "the current agent execution is about to stop" and lists no
  session-end event, but the framework template maps it to `session_end`, which would close out a session after every
  agent response. This is an interim local measure: until the framework template is fixed, a later F-7 may redeploy
  the file, so re-check after any framework update. Closeout stays manual, at the real end of a work session:
  `python -m governance_tools.session_end_hook --project-root . --format human` (run with the framework root on
  `PYTHONPATH`). The Copilot `sessionEnd` hook is a genuine session event and is unchanged.
- **Hook installation boundary (interim, until the framework template is fixed).** Verified in the pinned framework
  source: `hook_installer` with no flag, `--copilot-only` and `--copilot-vscode-only`, and `f7_full_update --apply`
  (it calls `install_governance_hooks` with its default `include_copilot=True`) can all deploy
  `ai-governance-vscode.json`, i.e. the wrong Stop wiring. `--hooks-only` does not. So: keep the current framework pin,
  initialise hooks with `--hooks-only`, and treat any F-7 apply or Copilot-surface install as a change that must be
  followed by `git status .github/hooks` and `python validators/hook_wiring_check.py .`.
  CI detects a re-deployed file; it cannot stop a local installer from writing it first, so "check after the update"
  leaves a window. Close it with isolation: do not run F-7 apply in a working directory where agent hooks are loaded.
  Run the update in an isolated clone that loads no agent hooks, confirm `.github/hooks` has no Stop wiring
  (`hook_wiring_check.py`), and only then promote the change to working clones. CI runs the same check on any
  PR that touches `.github/hooks/**`, so a re-deployed file fails the PR instead of relying on memory. This is a guard
  against regression, not a fix of the framework template.
- **Golden validator is a structure pre-check, not a replay.** Review still lists two gaps that were deliberately not
  closed: it does not check the value types of `config` entries or of `expect` entries (e.g. `{"ok": "true"}`);
  `GoldenReplayTests` is the authority. Adding more strictness only moves the line; it does not make `ok=True` mean
  "replayable". Decide strictness by whether a claim changes, not by review count.
- **Candidate head vs the SHA the job actually checked out.** A `pull_request` run is reported against the PR head,
  but the job checks out the PR *merge ref* by default. Observed on run 38595511730: checked-out HEAD
  `4455508` (a merge commit, parents `cdab133` = main and `7b81332` = PR head) while the PR head was `7b81332`. The
  workflow's first step now logs `git rev-parse HEAD`, `github.sha` and the PR head SHA. When the base is already an
  ancestor of the head the two trees are identical (checked for this PR), but evidence must still name which SHA was
  tested instead of saying "CI passed on the head".
- **Do not turn a CI run into a success receipt on exit code alone.** `gh run view --exit-status` exits 0 for a run
  that is still queued or in progress. Use `scripts/ci_evidence_receipt.py`, which requires `completed`, `success`, the
  expected head SHA, at least one named expected step that succeeded, and that the producing checkout's local HEAD is
  the commit under test (the framework writer binds `linked_commit` to the local HEAD); it reads the receipt back and
  deletes it on mismatch.
- `session_end_hook` fails on Python 3.9 (`X | None` annotations in `claim_enforcement_checker.py`) although the
  framework README states 3.9+; use Python 3.10 or newer.
- Memory-guard warnings that remain are attributed, not resolved: `test_evidence_provenance_not_found` is the
  `memory/2026-10-08.md` entry whose test evidence has no parsable artifact reference; `missing_canonical_memory` is
  date 2026-10-09, which has git commits but no `memory/2026-10-09.md` on this branch (that file exists only in
  uncommitted worktrees).

- Hooks are local and advisory (a memory-workflow warning does not block a commit).
- The drift workflow runs only manually or on pull requests touching governance files or the golden-fixture validator's inputs, and has run on GitHub only for the 2026-10-08 and 2026-10-14 runs recorded in `artifacts/governance/`.
- `readiness` still shows three `framework_version` warnings: a submodule consumer does not write `framework.lock.json`.
- `.governance/baseline.yaml` and `governance/.update-receipt.json` are tool-generated and contain this machine's absolute paths.
- Governance does not prove domain correctness, runtime enforcement, memory completeness or release readiness.

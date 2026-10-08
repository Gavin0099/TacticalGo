# Third-party notices

## ai-governance-framework (Apache License 2.0)

Source: <https://github.com/Gavin0099/ai-governance-framework>
Licence text: [`licenses/ai-governance-framework-LICENSE.txt`](licenses/ai-governance-framework-LICENSE.txt)

Used in two ways:

1. **Git submodule** at `additional/ai-governance-framework`, pinned to a specific commit (the pointer is
   recorded in this repository; the framework's files are not copied into this history by the submodule itself).
2. **Copied files**, made by the framework's own `governance_tools/adopt_governance.py`: `AGENTS.base.md`,
   `governance/` (documents and `governance/rules/` rule packs), and scaffolds for `AGENTS.md`, `contract.yaml`,
   `memory/` and the workflow. `AGENTS.md`, `CLAUDE.md`, `GEMINI.md` and `.github/copilot-instructions.md` contain a
   framework-managed block (marked BEGIN/END); the rest of those files is this project's.

Governance here is an audit/advisory layer: local Git hooks and a path-limited CI check. Runtime enforcement is not
claimed or proven.

## Project licence

This repository's own code and documents do not yet carry a licence. That decision is still open;
until it is made, no licence is granted for the project's own files.

## Art assets

Character/board art candidates are developed on a separate branch and are intentionally not part of
this repository's history yet. Their provenance and licensing must be reviewed before they are added.

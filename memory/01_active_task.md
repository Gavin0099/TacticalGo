# Active Task

## Current Status

- Adopted governance baseline (2026-10-08, `adopt_governance.py`, copy-based = audit-only class).
- Tech route chosen: iOS native Swift/SwiftUI (`docs/TECH_DECISION.md`).
- Rules Draft v0.2 (Owner decisions 2026-10-08, see `docs/DECISIONS.md`): first-turn 1 AP default (2 AP baseline kept), no hero resummon, hero summoned next to any friendly piece.
- C# reference engine + 3 skills; 75 tests pass incl. 23 hand-authored golden fixtures in `tests/golden` (shared with the future Swift package).
- S0 AP probe in `docs/S0_AP_GATE.md` (heuristic bots only, not a balance sign-off).
- Next gate: `docs/NEXT_GATE.md` — do classes change board strategy? Needs a text UI, skill-aware bots, representative positions; S3 human playtest is the first product stop point.

## Next Steps

- Owner reviews the remaining pending items in `docs/RULES_DRAFT.md` §8 one by one (not auto-approved).
- Build C# text UI + skill-aware bots + 3-4 fixed positions for the next gate.
- Swift Package + manual-trigger macOS workflow only once Package.swift exists; it must pass `tests/golden`.

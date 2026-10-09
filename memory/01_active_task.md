# Active Task

## Current Status

- Adopted governance baseline (2026-10-08, `adopt_governance.py`, copy-based = audit-only class).
- Tech route chosen: iOS native Swift/SwiftUI (`docs/TECH_DECISION.md`).
- Rules Draft v0.2 (Owner decisions 2026-10-08, see `docs/DECISIONS.md`): first-turn 1 AP default (2 AP baseline kept), no hero resummon, hero summoned next to any friendly piece.
- C# reference engine + 3 skills; 75 tests pass incl. 23 hand-authored golden fixtures in `tests/golden` (shared with the future Swift package).
- S0 AP probe in `docs/S0_AP_GATE.md` (heuristic bots only, not a balance sign-off).
- UI-1 delivered (commit cdf2bf9): Windows WinForms board `src/TacticalGo.Play` over the C# engine (see `docs/ui/UI1_README.md`); isolated `TacticalGo.Windows.sln`. Awaiting Owner hands-on check before UI-2.
- Next gate: `docs/NEXT_GATE.md` — do classes change board strategy? Order: UI-1 -> UI-2 (three classes) -> PLAY-1 (fixed positions) -> PLAY-2 (human playtest); bots paused.

## Next Steps

- Owner tries UI-1 and reports feel/clarity problems; then decide UI-2 details (hero summon, skill select with legal targets, reasons and expected effect shown after selection, not hover).
- Before any push of the public repo: resolve `governance/MEMORY_PROTOCOL.md` (framework working tree has an uncommitted edit that was copied) and add Apache-2.0 attribution for copied framework files.
- Owner reviews the remaining pending items in `docs/RULES_DRAFT.md` section 8 one by one.
- Swift Package + manual-trigger macOS workflow only once Package.swift exists; it must pass `tests/golden`.

- Cozy-02/ANIM-01/AUDIO-01 engineering candidate installed separately on iPhone and iPad; phone physical gesture automation and human art/hearing remain HOLD/BLOCK; no commit/push/merge, BGM HOLD. <!-- memory_record_projection:active-task-summary:43596922f2a2dc9c0b72d42df61dac93cb332ec399b1cbfc83c8805173fd5ba9 -->

- GAME-FEEL-10H-v2 on codex/game-feel-voice-01; S0 committed, S1 voice engineering PASS; continue S2/S3/S6/S7, no merge/TestFlight/release. <!-- memory_record_projection:active-task-summary:8fe4c6325d5229659deae83aa0825a4924cf1bce44a946cbbedfe8ec3c9b3c57 -->

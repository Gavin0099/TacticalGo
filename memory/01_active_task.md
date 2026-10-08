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

- R1 Domain and bounded probe locally complete at 191347d; handoff/rules on docs/handoff e3a78fc. G0 Pending, G1 waits, no G3/UI/push/merge. <!-- memory_record_projection:active-task-summary:98009da933e66272fdb1bea63446c8dc087a950c592c4f1efd3639ab6031f777 -->

- R1 review fixed five liberties and custom-5x5 classification at 00a2675; standard-9x9 cooperative replay has a prior-turn counter. 7c7abec allows both sides ordinary soldiers; 128 Domain / 47 Windows / 37 Golden, 2 focused mutants killed. Seal default; replacement HOLD; G0 Pending; no G1/G3/push/merge. <!-- memory_record_projection:active-task-summary:425e072c87be9f9adb3b10d498c2f3070c62bfce506559e5a865c7f204f8e68a -->

- Owner selected Magic Hand default at fede3ce; explicit Seal baseline retained. R1 research closed, no UI integration. Domain 129 / Windows 47 / Golden 38 pass. G0 Pending; four development slices G1-G4 to complete 7x7 local play, then G5 human gate and G6 feedback fixes. No new Slice/push/merge. <!-- memory_record_projection:active-task-summary:01b31e5382dc455e584bf8dcbf1c7be743b9351f6ed31c0081291e8b7b89d67c -->

- Current PLAN baseline is authoritative: Magic Hand default, 7x7 Windows G4 target, G0 rogue tutorial Pending with five manual checks, G1-G4 ordered without new research gates. Old P0/S0-S5 and R1 HOLD are historical. R1/UI-3c remain unintegrated. Owner authorized this R1 branch push after documentation checks; no merge or new Slice. <!-- memory_record_projection:active-task-summary:3333009fb9a37ff7b448509dd89ad1cc5547f1a2297446e1171f6df30c36a00a -->

- Owner revised integration timing: after G2, integrate R1 Domain into Gameplay baseline and rerun Domain/Windows/Golden before G3 UI; G3 uses real CastMagicHand, G4 verifies complete 7x7 play end to end. No new Slice or Gate. G0 remains Pending; no actual integration, new rules or search. Documentation follows existing R1 push authority; no merge. <!-- memory_record_projection:active-task-summary:f7b3b25c259e14f9b57289c30c810b5f871cf157400541822635419c3d3a0d20 -->

- Owner authorized G1-G4 with G0 unaccepted, starts (3,5)/(3,1), and six VIS-FEEL-01 candidates. Gameplay code 64ff4bb completes four slices with R1 integrated before G3; integrated Domain 129, Windows 91, Golden 38, validator 5, nine specified mutants and binary smoke validated. G0/G5 Pending; local trial package only, no Gameplay push/PR/main merge or new rules/search. <!-- memory_record_projection:active-task-summary:7670ce32b3a970f6fd6f2ce99efc9793bc8f79e8ef6e185ede3b3422b0418f5c -->

- Owner authorized saving and pushing the Swift/2.5D plan on codex/gameplay-g1-g4. PLAN section 7.1 orders V1 with SW1, then SW2, V2 and A1-A5; all unimplemented. G0/G5 Pending; no PR/main merge. Windows remains the reference prototype; Swift/iOS execution needs macOS/Xcode. <!-- memory_record_projection:active-task-summary:5090902dbd870d7eedd6bdc1869f9a605bb0115c59478269f0d453d4de4360c6 -->

- Swift/2.5D roadmap saved in PLAN section 7.1: V1 with SW1, then SW2, V2, A1-A5. Documentation checks have durable receipts; all implementation and G0/G5 acceptance remain pending. Owner authorized this plan commit/push only, with no PR/main merge. <!-- memory_record_projection:active-task-summary:93b2270bda275b802bd23cb76e43b3abfad2d19672c1131aa81a1585af05fa48 -->

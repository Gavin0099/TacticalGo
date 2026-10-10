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

- GAME-FEEL-10H-v2 engineering candidate delivered in isolated codex/game-feel-voice-01. S0-S6 PASS with current V3 native simulation; S7 commit/push/report in progress. True iPhone0.8.0(802) installed separate Hero Voice app; foreground/hearing Pending due Locked. No new gameplay/Domain/Bot/second skill; formalBGM HOLD. Stop adding work after S7; Owner acceptance Pending. <!-- memory_record_projection:active-task-summary:eb7ed6ec58355e6ecd4caf3611b0413098d41ca05d73deb78b6bd547dd25ae0a -->

- GAME-FEEL-10H-v2 S0-S7 engineering delivery complete; sourcec9f86c6 pushed isolated codex/game-feel-voice-01, maincdab133 unchanged. Final evidence commit to follow. Owner product/art/voice and physical V3 foreground Pending; iPhone Hero Voice802 installed, Locked launch; iPad simulated only. Current seeded Piper TTS no Apple generated clips in pushed history. FormalBGM HOLD; no merge/release/new work. <!-- memory_record_projection:active-task-summary:a1bb7527a87cb8b184eb6c4b6c2204606907729f9360f30b5572051b14549498 -->

- Hero Voice V3 product performance FAIL after Owner listening: rigid reading, lacks warrior firmness/mage playfulness. Preserve engineering delivery branch c5cde5d and wiring. New local review/brief only; no regenerated audio, code changes, paid service or push. Next actual two-line performance Gate before full recasting; formal BGM/art and physical V3 hearing Pending. <!-- memory_record_projection:active-task-summary:5c925fcf8460b524933975dcd26044d47334c209a8a02ff39adc0a15b868fe16 -->

- VO-PERF-01 two-line dry pilot ready on local codex/hero-voice-performance-01; warriorA/B mageA2/B3, independent words4/4 and PCM4/4, seven generated takes with3 prior held experiments retained. Owner audition preference/acting acceptance Pending. No App/Domain/Bot or BGM change; no push/merge/release in this slice. Original VoiceV3 performance FAIL remains until replacement accepted. <!-- memory_record_projection:active-task-summary:1691a57f3dc78f21574036872386ce3d48bdb78d8358a1ce12aff550b6013847 -->

- ANIM-M1/M2法師本體候選工程已交付，本地未提交；演技/美術與真機動態Pending。iPad903已裝但Locked，手機unavailable。VO新素材未整合、BGM HOLD；Domain/Bot不變。 <!-- memory_record_projection:active-task-summary:0017307175297158e5a53f22fa10f249a29b9b586d2d4a5c1c864d317070ec6d -->

- ANIM-M1/M2法師本體候選工程交付，本地未提交；演技/美術/真機動態Pending。162項結果與97/97 audit、正常速度錄影有可追溯receipt；iPad903已裝但Locked，手機unavailable，Domain/Bot不變。 <!-- memory_record_projection:active-task-summary:95fc212d4527f41ad3c0c34b7935f15b480e745e04fec73341642f8bb584b9de -->

- ANIM-M3 isolated codex/anim-mage-m3 candidate: engineering evidence PASS; Owner visual/acting and physical dynamic gates Pending. Necessary commits/push authorized; merge/release prohibited. <!-- memory_record_projection:active-task-summary:00b75600385cb7804cbcb7d4d8d6d7b0d28767110fadfa83da7c47802f6eb947 -->

# TG12 implementation contract — 2026-10-22

Base 31ac5413; branch codex/tg12-tactical-expedition. Owner authorized continuous implementation,
commit/push/Draft PR and memory curation. No main merge/release/billing-policy change.

## Boundaries
Content owns objectives and replay; Core exclusively owns legality, capture, costs and victory.
UI owns clocks/export and task cancellation. Existing 1.0/1.1 journals and admission remain unchanged.
New expedition has a distinct catalog ID namespace and journal. No save migration.

## Candidate
Build three short scenarios on the existing legally replayed border positions, with a new requirement:
finish two own turns for rescue, three for capture/timing, AND survive the final state-dependent enemy reply. This deliberately removes
the old instant objective completion before the final counterattack. Rescue, capture and timing goals
use different opponent priorities. These are prototype extensions, not proof of novel or fun content.
At least two complete plans for the rescue must replay with different resource/frontier outcomes.
Validate pass-only failure, illegal action atomicity, corrupted journals, mid-reply restore,
undo/retry and chapter isolation. Add outcome resource/board review and per-action replay text.

## Work and evidence
- TG12-00: optional local observation journal (duration excluding background, hints, retries, exits),
  exported by tester; no account, network, paid-ledger bypass or retention claim.
- TG12-01: inspect first-tap Menu and rogue skill availability; fix only supported defects;
  native regression test remains NOT RUN on Linux.
- TG12-02: expedition catalog/controller + UI route, replay witnesses and negative controls.
- TG12-03: isolated priest affordability experiment using existing cost-4 mechanics and a one-mana
  counterfactual; explicitly NOT a complete cost-3 game/balance result. Check all fixture geometries.
- TG12-04: factual final summary and timeline, retry/next-stage entry; no invented causal best-move claims.
- TG12-05: conditional research only; no new endgame rule without human stalemate evidence.

## Validation and stop conditions
Swift baseline and changed package; targeted mutation on expedition final-reply guard.
Existing old challenges must replay unchanged. No fabricated Xcode/device results.
3–5 independent testers, unprompted retries and explanation of choices remain a human gate.
The three-stage candidate may ship for internal evaluation only after native verification;
if alternative strategy witnesses fail, revise the scenario or report No-Go, not manufactured success.

## Engineering outcome
Three stages implemented; six complete witnesses; full Swift suite 464 tests, one known-defect skip, zero failures. See REPORT.md and artifacts/tg12/validation.json. Native and human acceptance remain open.

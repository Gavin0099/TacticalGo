---
name: tacticalgo-cutout-animation
description: Animate existing TacticalGo hero art as articulated 2D cutouts in SwiftUI, with small-board faction readability and successful-event playback. Use for hero summons and class skills; not new character design, 3D modeling, gameplay rules or voice production.
---

# TacticalGo 原畫角色動畫

Turn identity-pinned hero art into readable native board performance. Mage M3 is an engineering example whose presentation direction may be accepted separately from final art/acting. Read the current Owner brief before choosing artwork, timing or delivery scope.

## Preserve and inspect

- Inspect actual worktree, dirty changes, source pins and previous delivery; preserve the baseline and original portrait. User authority determines commit/push/merge/release; the skill grants none of these actions.
- View the individual identity image and actual native board. Measure pitch, painted area, ground anchor, crop and marker overlap. A 64px sample does not prove a 28px board character is readable.
- Use current B-v02 when it is the Owner baseline; never silently substitute v01 or redesign face, wardrobe, equipment hand or emblem. Read [native-contract.md](references/native-contract.md) before adapting receipt and timing surfaces.

## Make the body perform

- Use purposeful head/body, held hand plus prop, cloth and hidden-area backing layers. Keep gripping hand and prop in one transform hierarchy with reviewed pivots. Faction base stays at its board anchor.
- Compare rest, anticipation and release at32/48/64px and actual390pt/7×7 and320pt/9×9 boards before decoration. Require silhouette and weight differences; whole-token bounce or particles do not replace body articulation.
- Reuse original pixels. For unavailable backing, make a minimal traceable clean plate or pose frame; use imagegen when generating/editing raster art. Retain prompt/reference/output hashes and mask out changed identity pixels. A head-and-chest portrait does not define unseen full-body anatomy.
- Place team identity on thin base and outer shape cue, not over face/hand/prop. Dark solid versus light hollow shapes supplement color; omit unreadable badges and retain role information in HUD/selection. Keep commander/soldier/hero distinct.
- Align the strongest contact pose with the actual target landing; do not let a shield rebound before the summoned soldiers arrive. Keep anticipation, impact and recoil distinct at board size.
- Body/prop settles before cloth follows through. Do not freeze the last pose when the clock pauses. A fixed portrait may limit target-facing gestures: disclose it or author a supported pose, rather than rotating the entire image.

## Integrate one successful receipt

- Presentation consumes immutable before/action/outcome/after. Preview never creates success animation, charges resources or really moves pieces. Captures and wins require actual event payloads.
- Use one reviewed timeline for body release, movement, landing, capture, recovery, unlock and existing SFX. Mage950/760ms are examples, not mandatory class timings.
- Reuse cancellation/stale-work protections. Never apply rules, charge resources or infer a winner in animation completion. Verify secondAP, Bot, undo, new match, exit, background and Reduced Motion.
- Preview ghosts retain original source and empty destination. Art/hints/hit mapping keep the same fitted projection rectangle.

## Verify and deliver

Use [review-and-delivery.md](references/review-and-delivery.md). Start body-only, voice/effects off; add sparse direction effects after the body is readable. This review mode does not replace audio/art approvals.

Deliver normal-speed full-board clips before closeups, same-fixture old/new comparison, real-size black/white samples, code/assets/timeline/source changes, fresh relevant tests and defects. Separate Simulator, physical execution and human art/acting acceptance. Pixel movement, hashes, recorder clocks or tests cannot pass Owner Gates.

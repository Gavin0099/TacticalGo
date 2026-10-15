# Native contract: inspect before adapting

Repo-relative lookup anchors, observed at mage M3 c13f23e. Re-check live code; existing interfaces may change.

| Surface | Inspect |
|---|---|
| ios/TacticalGo/GameStore.swift | Successful confirm and Bot apply produce receipts; visual duration locks input; cancelPresentation clears pending work/sound |
| ios/TacticalGo/BoardPlayback.swift | before/action/outcome/id, shared clock, plan and visualDuration |
| ios/TacticalGo/CozyBoard.swift | Fitted Anim01Geometry, BoardProjection art/hit, original Magic Hand and generic drop/swap/capture sprites |
| ios/TacticalGo/CozyStyle.swift | Thin hero base/exterior team/class cues; separate soldier/commander |
| ios/TacticalGo/MageBodyView.swift | Original-pixel masks, clean plate pin, nested grip transforms, prop tip |
| swift/TacticalGoCore/Sources/TacticalGoMotion/MagePerformance.swift | Retained M2/M3, shared950/760ms timing, continuity/final rest |
| swift/TacticalGoCore/Sources/TacticalGoMotion/MotionPlan.swift | Placement/bastion/swap/capture/win cues |
| ios/TacticalGo/HeroBodyView.swift | Warrior shield/held hand and rogue hood/held dagger original-pixel cutouts; union hole masks and original-alpha-limited cloth backing |
| swift/TacticalGoCore/Sources/TacticalGoMotion/HeroPerformance.swift | Success adapter for W1/R1; release precedes drops/swap; align capture, draw, turn and SFX to shared timing |
| swift/TacticalGoCore/Sources/TacticalGoMotion/CombatFeedbackPlan.swift | Existing SFX times: audit if movement timing changes |

Warrior castBastion uses real piecePlaced; rogue castSwap uses piecesSwapped; original mage castMagicHand uses exactly one piecePushed. Candidate redeploy must not accidentally use one-cell push. Inspect live types, do not invent event/resource names.

M3 example: base0.74pitch×0.36pitch, mage canvas0.92pitch, source ground448/512.390pt board382×429.75pt/pitch46.56;320pt board312×351pt/pitch28.52. These are one viewport, not fixed universal numbers.

Mage masks/backing are mage-specific. Inspect new hero identity and derive actual pivots/backing. Warrior shield and weapon differ from mage hand/staff. Rogue must travel with the swapped hero rather than remain a static caster at the source square.

W1/R1 engineering example: warrior release280ms→two drops300–540ms→capture600ms→body rest820ms; rogue release200ms→two-way swap220–420ms→capture480ms→body rest720ms. Result/turn feedback must follow actual landing/capture, including final-AP draws. Before delayed drops begin, hide their after-state destinations rather than showing floating soldiers during charge. Treat examples as reviewed class timings, not universal skill rules.

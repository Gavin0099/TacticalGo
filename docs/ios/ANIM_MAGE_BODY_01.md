# ANIM-M1 / M2 — Mage body-first candidate

Owner authorized the next two mage-only animation slices. Review criteria: with voice, particles and light rings disabled, the mage must visibly anticipate, release and recover. Original one-cell Magic Hand only. R3 friendly redeployment does not borrow this push performance. No Domain/Bot/rules/second skills, new 3D or voice generation. Formal BGM remains HOLD. No merge/public release authorized.

## Editable art contract

Original identity master is `ios/TacticalGo/Cozy/B-mage-v02.png`, SHA-256 `6980751a325e51156e56f14b38171a435bd54f4ef7d509433e94d6e3b9061a33`, 512×512. Immutable original supplies the face, most hair/hat, main torso, hand and staff. MageBodyView masks/pivots are editable code in this coordinate system. Head/torso, shoulder sleeve, elbow/hand+staff and cape are separate transforms. The hand and staff share a transform, so a wrist cannot drift independently of its grip. This is cutout articulation, not frame-by-frame drawing, a full anatomical arm model or a 3D mesh.

One built-in image_gen occlusion-reconstruction clean plate supplies masked hidden garment and a small hat backing region where the old prop occluded it. Its generated face is not displayed. Original and generated plate preserved under `assets/candidates/anim-mage-body-01/`, with full prompt, actual 1254×1254 dimensions, file/decoded RGBA SHA and independent approval/rights metadata. The original master is not replaced. Pose seams and identity acceptance remain human review items.

## Single clock

| Cue | Full | Compact |
|---|---:|---:|
| anticipation end | 180ms | 120ms |
| visible release / mage SFX | 280ms | 200ms |
| soldier begins moving | 300ms | 220ms |
| soldier arrives / landing SFX | 540ms | 420ms |
| capture begins when receipt contains captures | 660ms | 510ms |
| recovery / input lock ends | 950ms | 760ms |
| mage summon ends | 720ms | 600ms |

MageTempo/MageTiming is a presentation-only contract in TacticalGoMotion. BoardPlayback pins it per receipt. Character curves, soldier position, sprite-frame progress, capture fade, sound start, input lock and debug phase trace consume it. VFX frame sampling uses normalized receipt phases rather than the historical 80/220/100ms clock. The casting pose arrives before the soldier moves; no independent timer applies the action again. Sound offsets identify actual player start scheduling, not measured acoustic latency.

Mage summon keeps the base/shadow at the grid intersection, with a short character descent, torso grounding, separate hand stabilization and delayed cape settling. It bypasses whole-token scaling for the mage. Warrior/rogue presentation unchanged.

## Safety and review

GameStore still applies once. Preview has no performance receipt, no displacement or payment. Failed actions have no success animation. Duplicate confirm cannot submit during playback. Undo/cancel/restart/leave/background/interruption cancel pending playback and sound. Reduce Motion presents committed state and neutral pose immediately, while retaining essential SFX. Input stays locked through the finite recovery; no overlapping next action is admitted merely because the soldier arrived.

Native review flags (Debug):

- `--mage-body-review` disables existing VO and BGM; no new voice files.
- `--mage-no-effects` removes performance particles/rings, preserving soldiers, faction bases and tactical information.
- `--mage-compact` compares the shorter performance on the same Domain action.
- `--summon-demo --hero mage` / `--cozy-demo --cozy-no-capture` / `--cozy-demo` provide real-action summon / push / actual commander capture.
- `--mage-dense --cozy-nine --cozy-320 --white-caster` is a fixed live-group 9×9 stress fixture. It is not claimed as a naturally reached competitive position.
- `--mage-pose-review` is a labelled art-inspection screen, not game settlement; exports native 32/48/64/128/512px key poses.
- `--mage-body-audit` runs the visible screen's actual GameStore/CombatAudio cancellation and resource checks.

Evidence and device status: `artifacts/ios/anim-mage-body-01/REPORT.md`. Native checkpoint images use successful real receipts but are frozen inspection views, separate from actual normal-speed input recording. Simulator evidence cannot establish physical iPhone operation, acting quality or final art acceptance. Source records retain failed experiments.

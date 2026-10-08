# Reference-led prompt

Keep the common rendering specification stable; deliberately change subject, action or one concrete defect.

```text
Use case: stylized-concept
Asset type: TacticalGo full-body / simplified board token / avatar candidate.
Input images: Image 1: [individual identity or style reference; state its role].
Primary request: ONE original [class] cute fantasy tabletop RPG adventurer.
Identity: [face, hair, wardrobe, expression, anatomical prop hand].
Style: supplied reference's matte hand-painted 2.5D, warm brown contours, broad
colors, subtle paper grain, upper-left light, expressive eyes, compact anatomy.
Class cue: [large primary cue and one secondary cue].
Composition: [usage-specific framing]; avoid clipping; true transparency.
Preserve: [same-hero identity invariants].
Change only: [pose / representation / targeted repair].
Constraints: no floor/shadow/matte, extra character, lettering, particle noise.
```

For a new hero request, explicitly use STYLE references and request a distinct face. For a pose or representation of an existing hero, preserve its actual identity. Supply local reference paths; keep originals and full prompts. Check generated output against the actual references, not just the intended wording.

The tested sequence was warrior from text, mage referenced to warrior, rogue referenced to warrior/mage, board referenced to all three. The resulting party is stylistically close but one small batch does not guarantee future consistency. Complete prompts are retained in the project's candidate pack.

A simplified board token should reduce garment detail and prioritize silhouette/prop; an avatar should retain the face plus a class cue. Neither representation has yet been authored. Board concept and QA montages are not identity seeds.

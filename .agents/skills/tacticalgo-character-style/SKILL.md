---
name: tacticalgo-character-style
description: Generate consistent cute fantasy tabletop RPG hero candidates for TacticalGo using fixed character references and 32/48/64 px review. Use for warrior, mage, rogue, or new heroes in this visual world; gameplay implementation and animation production are separate tasks.
---

# TacticalGo Character Style

Create original friendly medieval fantasy adventurers with strong class silhouettes. The user's template is the adventuring-party vocabulary of Dungeons & Dragons, expressed as cute Soft Handmade 2.5D tabletop miniatures.

## Fixed style and references

Read [style-v0.1.md](references/style-v0.1.md). Inspect applicable individual PNGs with `view_image` and verify their SHA-256 against [reference-set.json](assets/reference-set.json).

- `assets/warrior-v01.png`: shared rendering key; shield guardian.
- `assets/mage-v01.png`: mage identity; pointed hat/crystal staff.
- `assets/rogue-v01.png`: rogue identity; rounded hood/short blade.

This is a candidate reference set. The Owner gave positive direction feedback on the board concept; exact production-master approval and rights acceptance have not been recorded.

For a new identity, label the warrior as STYLE reference and request a new face. For another pose of an existing hero, use its individual image as IDENTITY reference and lock face, hair, wardrobe, prop hand and anatomy. Never seed generation with a contact sheet, board concept or silhouette QA sheet.

## Generate and preserve

Use built-in `image_gen` with [prompt-template.md](references/prompt-template.md). Use `referenced_image_paths` for inspected local references. Request true transparency for isolated characters, no floor/shadow/matte/baked faction base.

Keep exact originals in a versioned project candidate directory, full prompt, source/reference SHA-256, actual dimensions, output file and decoded RGBA hashes. Unavailable model/tool-version metadata is `unknown`. Never overwrite approved references.

Record `approval`, `availability`, `rights` and `qa` separately. New art defaults to candidate, pending exact-file approval, unavailable for production, rights pending. Successful generation or file validation does not change these statuses.

Complete only the requested batch. For a specific defect, make one targeted repair and re-check; report remaining failures instead of unbounded retries. Read the current Owner direction before generating. The VIS-FEEL-01 checkpoint uses existing A board tokens and B cards, defaults the Mage visual to Magic Hand, and starts animation design with Clash Royale as a volume and prop reference. Full-party regeneration, sprite production and gameplay integration remain separate requests; see the project's visual checkpoint for current scope.

## Readability and usage

Use large shield / pointed hat and staff / rounded hood and short blade as class cues. Team identity belongs in an external base ring, shape and marker; preserve class colors on both teams. Commander uses a distinctive crown plus outer ring. Danger uses a separate warning, never a character recolor.

Compare native art, light/dark backgrounds, grayscale, silhouettes and real 32/48/64 px samples. Full portraits, board tokens and avatars are different representations: do not call a reduced portrait a finished token or icon. If separately requested, author simplified token and avatar candidates from the same identity references.

For the initial three v01 PNGs:
```text
node scripts/review_assets.cjs <originals-dir> <qa-dir>
```
Requires Node.js and `sharp`; Codex desktop can locate bundled paths through `load_workspace_dependencies` and command-scoped `NODE_PATH`. Input names are `warrior-v01.png`, `mage-v01.png`, `rogue-v01.png`. For other assets, review equivalent samples using their actual filenames instead of silently substituting v01.

The helper preserves originals, verifies transparency, records hashes and creates a common canvas scale. Its 1024 previews are QA only; semantic ground anchors are not measured and KCK production delivery is not certified. Current portraits lose details at 32 px; player recognition and consumer UI acceptance remain untested.

For board experiments, prioritize hero miniatures plus simple black/ivory soldier stones. Compare 7×7 and 9×9 with fixed near-overhead 2.5D and flat 2D alternatives using the same positions. Distinguish legal placement, skill targets, shared survival spaces and danger with shape/text as well as color. Keep unit bases aligned to intersections, art and hit regions within their cells, and hints outside artwork. A mockup is not rule-engine or iPhone-device acceptance.

## Boundaries and finish

KCK owns truly shared identities, portraits and animation. TacticalGo owns its class candidates, board, UI and effects. An actual KCK asset import must pin source repo commit, character ID, version, exact path and SHA-256 while retaining source approval/availability/rights. Reading KCK specifications does not import its art or transfer its approvals.

Return images, scale review, exact prompts/provenance, observed limits and the next visual decision. Do not modify Gameplay, Domain or existing Windows UI without a separate request. This skill does not authorize GitHub writes, PR merges, KCK promotion or animations.

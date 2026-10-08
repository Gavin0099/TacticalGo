# Golden replay fixtures

Language-neutral rule fixtures. Every implementation of the rules (C# reference engine today, Swift package later)
must replay each file and match every expectation. Expected values were reasoned by hand from `docs/RULES_DRAFT.md`,
not exported from an engine, so a bug that exists in one engine cannot silently become "expected".

## File shape

```jsonc
{
  "name": "capture_basic",
  "description": "...",
  "config": { "apPerTurn": 2, "firstTurnAp": null },   // overrides on top of the Draft defaults; null = same as apPerTurn
  "setup":  { ... },                                    // see below
  "expectInitial": { ... },                             // optional; checked before step 1 (no ok/reason/events)
  "steps": [ { "action": { ... }, "expect": { ... } } ]
}
```

Config keys: `boardSize`, `apPerTurn`, `firstTurnAp`, `maxPlies`, `manaCap`, `allowResummon`, `mageSkill` (`Seal` or `MagicHand`), `magicHandRange`. Anything not listed uses the Draft default
(9×9, mana start 3 / +1 per own turn start / cap 6, skill 2 Mana, summon 2/3/2, seal and Magic Hand range 2, **Mage skill Seal**, `maxPlies` 100, `firstTurnAp` **1**).

Setup is either `{"newGame": true, "classes": ["None","None"]}` (standard commanders at (4,7) and (4,1), first-turn mana gain applied)
or a mid-game scenario (mana and AP are taken literally, **no** start-of-turn mana gain):

```jsonc
{ "diagram": ["xo", "", "..H"], "classes": ["Warrior","None"], "current": "One",
  "mana": [6,3], "ap": 2, "heroSummoned": [false,false] }
```

Diagram: rows top (Y=0) to bottom, whitespace ignored, each row right-padded with `.` to the board size, missing rows are empty.
`. empty | x soldier, X commander, H hero (Player One) | o soldier, O commander, Q hero (Player Two)`.
A hero standing in the diagram counts as already summoned.

## Actions

`{"type":"PlaceSoldier","at":[x,y]}` · `SummonHero` (`at`) · `CastBastion` (`first`,`second`) · `CastSeal` (`at`) · `CastSwap` (`target`) · `EndTurn`.
R1: `{"type":"CastMagicHand","target":[x,y],"direction":"Up"}`; direction is `Up`, `Right`, `Down`, or `Left` (Y increases down).
Coordinates are `[x, y]`, x to the right, y downward.

## Expectations (every key optional; absent = not checked)

`ok` · `reason` (IllegalReason name, only when `ok:false`) · `cells` (`"x,y": char`) · `current` (`One`/`Two`) · `ply` · `ap` · `mana` `[one,two]`
· `status` (`Ongoing`/`Won`/`Drawn`) · `winner` (`One`/`Two`/`null`) · `seals` (`[[x,y],…]`, order-insensitive)
· `events` (exact ordered list of event type names). Expectations are checked on the state **after** the step, so a rejected step
also proves the state did not change.

R1 adds `skillUsed` (boolean), `liberties` (`"x,y": count`), and `groups` (`"x,y": [[x,y],…]`, order-insensitive).
The replay harness also asserts that the input fingerprint never changes and a rejected action returns the same state object
(including its shared position history) with zero events. These are rollback invariants, not extra game rules.

The `magic_hand_*.json` files were hand-authored from the Owner's R1 specification, the vacated-source liberty invariant,
and explicit board-coordinate reasoning. They cover the second-action capture, split groups, commander relief,
suicide, older-board superko, target/cost restrictions, event order and the unchanged Seal default.
`magic_hand_range_two_decapitation` is also reached by an actual legal `NewGame` replay in `MagicHandReplayTests`;
other diagram fixtures are isolated rule tests, not reachability claims.

Illegal reasons: `GameOver NoActionPoints OutOfBounds Occupied Sealed Suicide Ko NotEnoughMana NoHeroClass HeroAlreadyOnBoard
NotAdjacentToFriend HeroAlreadySummoned WrongClass NoHeroOnBoard SkillAlreadyUsed OutOfRange InvalidTarget DuplicateTarget
SkillNotSelected InvalidDirection`.

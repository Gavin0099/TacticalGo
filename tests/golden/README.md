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

Config keys: `boardSize`, `apPerTurn`, `firstTurnAp`, `maxPlies`, `manaCap`, `allowResummon`. Anything not listed uses the Draft default
(9×9, mana start 3 / +1 per own turn start / cap 6, skill 2 Mana, summon 2/3/2, seal range 2, `maxPlies` 100, `firstTurnAp` **1**).

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
Coordinates are `[x, y]`, x to the right, y downward.

## Expectations (every key optional; absent = not checked)

`ok` · `reason` (IllegalReason name, only when `ok:false`) · `cells` (`"x,y": char`) · `current` (`One`/`Two`) · `ply` · `ap` · `mana` `[one,two]`
· `status` (`Ongoing`/`Won`/`Drawn`) · `winner` (`One`/`Two`/`null`) · `seals` (`[[x,y],…]`, order-insensitive)
· `events` (exact ordered list of event type names). Expectations are checked on the state **after** the step, so a rejected step
also proves the state did not change.

Illegal reasons: `GameOver NoActionPoints OutOfBounds Occupied Sealed Suicide Ko NotEnoughMana NoHeroClass HeroAlreadyOnBoard
NotAdjacentToFriend HeroAlreadySummoned WrongClass NoHeroOnBoard SkillAlreadyUsed OutOfRange InvalidTarget DuplicateTarget`.

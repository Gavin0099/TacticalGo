# TG12 P0 observation tool

This standalone Swift package observes the existing game and Standard/Baseline
Bot. It is not linked into the app and changes no rules, costs, Bot policy,
admission, journals or release settings. It has no third-party dependencies.

```sh
swift test -c release --package-path scripts/tg12-p0-research
swift run -c release --package-path scripts/tg12-p0-research P0Runner cohort /tmp/tg12-p0
swift run -c release --package-path scripts/tg12-p0-research P0Runner verify /tmp/tg12-p0/b7-Warrior-Mage
swift run -c release --package-path scripts/tg12-p0-research P0Runner probe /tmp/tg12-p0/b7-Warrior-Mage 2
swift run -c release --package-path scripts/tg12-p0-research P0Runner audit /tmp/tg12-p0/b7-Warrior-Mage 75
python3 scripts/tg12-p0-research/summarize.py artifacts/tg12/gameplay-p0-20261023 --check
```

Published synthetic records and serialized receipts live in
`artifacts/tg12/gameplay-p0-20261023/complete-games/`. Use `verify` on each game
directory to check before/after snapshots and ordered events; use `verify-record`
on its `record.json` for the existing record reader. The Python command checks
the committed aggregates and five capped-cohort prefixes without rerunning Bot
games. `probe-selection.json` indexes future comparisons; it does not claim that
P1 reply safety or strategic advantage has been established for those samples.

`cohort` runs Warrior/Mage, Mage/Warrior, Rogue/Priest and Priest/Rogue on
both 7x7 and 9x9 boards. Each starts from official `GameSetup.newGame`, with
`TacticalHints.updatedConfig`, cost 4 advanced skills and no monsters. There is
no random or hand-placed opening. Only actual Core terminal statuses count as
wins/draws. A runner-truncated ongoing game fails rather than becoming a draw.
Already completed games are independently verified before being reused.

Each game retains an `ExpansionMatchRecord`, per-action before/after snapshots,
ordered event strings, turn observations and a completion summary. Verification
reads the serialized actions and receipts and replays them from the official
opening. The collector also compares the full in-memory GameState, including
superko history, against that independent replay.

`verify-record <file.json>` validates a published standalone record using the
existing record reader. `reobserve <game-directory>` recalculates availability
from the same recorded actions, preserving the original trace and leaving the
record bytes unchanged. This allows a measurement correction without rerunning
the Bot or inventing a new opening.

The action set matches the existing human UI and Bot: updated expansion Mage
uses Redeploy rather than compatibility-only Magic Hand. Original and
non-expansion experimental modes keep their original repertoire. Core still
accepts old actions for record compatibility; this tool does not change that.

Availability is checked at actual decision points. Basic action enumeration is
complete. An advanced action found within the first 256 generated candidates
is a positive witness; when no witness is found despite sufficient resources,
the observer enumerates uncapped actions before reporting absence. Advanced
witness counts remain lower bounds, not the size of the complete action set.
After a first action, new skills can become available; turn-start availability
and whole-turn skill use therefore have different meanings.

`probe` exports the planner-retained complete own turns, observable immediate
effects and the planner's own-turn scores. These are bounded heuristic
comparisons, not complete enemy-response searches or dominance proofs.

`audit` examines an actual pure-pass position away from the turn-cap boundary.
It preserves the complete opening history, enumerates uncapped current-mode
actions without merging different superko histories, and checks one complete
enemy reply. It stops after finding a safe non-pass witness or after proving all
active choices lose immediately. A limit of 60,000 explicit apply calls or
30 seconds produces **unknown**, not a stalemate conclusion. Internal work in
legal enumeration is not included in the explicit-apply count. A safe witness
does not prove an improvement over waiting, and one-reply safety is not a
permanent stalemate or game-theoretic result.

The cohort contains one deterministic path per selected pairing/size. It cannot
establish population win rates, class balance, human understanding, fun or a
willingness to replay. Observed Mac elapsed times are not iPhone latency
acceptance. Handwritten unit fixtures test reporting invariants only and never
enter the natural-game dataset.

# R1 Magic Hand bounded comparison

From repository root:

```powershell
dotnet run -c Release --project tools/probes/magic-hand -- artifacts/r1-review/search-current.json
python tools/probes/magic-hand/check-mutations.py
python tools/probes/magic-hand/check-mutations.py --friendly-only
dotnet run -c Release --project tools/probes/magic-hand -- --review-supplement artifacts/r1-review/supplement-current.json
```

The probe is outside both solution files. It uses the real Domain engine, no new packages and no UI.
The search has four hand-selected 5×5 cases, three strategies, at most two own atomic actions and two opponent actions.
Its fixed total budget is 50,000 apply attempts and 30 seconds. A budget overrun writes `incomplete_budget` and exits 2;
no retry or extension is automatic. JSON includes exact actions, boards, root resources, setup replays and source SHA256.

Every root is reached from `NewGame` using actual legal moves, summons and passes, preserving superko history.
Mage and Rogue use the same board placements and AP but their existing summon costs differ, so root Mana differs;
both have enough for one skill. Replays use custom 5×5 commander starts and cooperative setup, not the normal 9×9 opening.

A = Magic Hand then placement; B = two placements; C = Rogue swap then placement. An early commander capture terminates
the line without an invented extra action. A/C omit lines without the named first skill; B omits skills and early pass.
All own candidate placements are tried. The representative line is selected by immediate commander win, then captured
enemy soldiers, then own commander liberties, then ordinal action text. White has no hero class; **all** legal placements
and voluntary pass in its next turn are enumerated for that representative only. This is not full minimax over all own plans.

Counts are ordered action sequences, not distinct final positions. A terminal win needs no opponent response. A branch with
no legal skill has zero plans; that does not establish the class's overall strength. There is no next-turn continuation,
opponent skill search, random sampling, player test, balance claim or G3/UI acceptance. The Seal probe is not rerun.

The mutation script temporarily changes seven focused source conditions, runs real tests, and restores exact original bytes
in `finally`. A runner/build failure is not accepted as a killed mutant. Test logs/TRX remain in `artifacts/r1-validation/mutations`;
the committed report contains changes, counters and failing test names. It never edits golden expectations.

The review supplement audits the five initial liberties of `connector_range_two` without changing its board.
It classifies that custom 5×5 root as a mechanism demonstration, unreachable under the immobile standard commanders.
The separate 9×9 experiment uses the existing default commander starts, one cooperative setup, and exactly two selected
previous-turn opponent choices (pass; block both push destinations). It enumerates A/B/C immediate plans after each choice.
Its independent fixed cap is 20,000 Apply attempts / 30 seconds; no retry, budget extension, exhaustive opponent search,
balance inference or UI work. The committed review result is from the enemy-only baseline, before friendly push expansion.
Historical `search.json` counters/hashes are preserved with a review annotation. Re-running writes new evidence for the
current code and must use a different output path to preserve those historical runs.

`--friendly-only` runs exactly two additional mutants (restore the old friendly rejection; omit friendly action candidates)
against `MagicHandFriendlyTests`. It preserves the old seven-mutant report and writes `friendly-mutations.json`, with logs
in `artifacts/r1-review/mutations`. Current Magic Hand targets soldiers of either player; historical search counts describe
the former enemy-only rule. No tactical search was repeated for the expanded rule.

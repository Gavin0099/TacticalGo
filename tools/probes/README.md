# Probes (scratch evidence tools)

These are **throw-away research probes**, not product code. They are not part of `TacticalGo.sln` or `TacticalGo.Windows.sln`
and are not covered by the test suites. They exist so a reported number can be reproduced.

## `seal-search/`

Question: is there a 7x7, 2 AP, responsive-opponent position where the Mage's seal ("stone + seal") beats every plain alternative?

```bash
dotnet run -c Release --project tools/probes/seal-search -- <seconds> <seed>
# the 2026-10-08 run: -- 660 7
```

Result of that run (476 random focused positions, 11 minutes): **0** positions winnable only with the seal, 195 winnable without it,
281 not winnable. The SURVIVE branch tested **0** positions (its focus filter excluded every position where black is threatened), so
the defensive use of the seal is **untested**.

Known limits (do not over-read the result): white has no class and only plays plain moves; positions are random and rule-valid but not
checked for reachability from a real game; the focus filter (white commander group with 2-4 liberties, black commander with >= 3) biases
toward dangerous defensive positions; candidate stones are limited to points around the commanders' liberties; it asks only "forced win in two
black turns", not "does the skill create new choices"; it is a sample, not a proof of absence.
# Research probes

`magic-hand/` is the R1 bounded Domain comparison and sensitivity harness. See its README and `docs/R1_MAGIC_HAND.md`.
It is outside both solutions; test-suite success does not claim this program ran.

The historical Seal probe remains on `docs/handoff` at `c55a2e1` in `tools/probes/seal-search`.
This branch starts from `chore/governance-full`, so that probe and the UI branch are not imported.
The previous report is 476 positions with zero Seal-only wins; its defense branch tested zero positions.
Those numbers are historical, cited from the handoff/probe README, and were not rerun or independently reproduced in R1.

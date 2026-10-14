# 1.0 + 1.1 integration result (branch `integration/1.0-1.1`)

Date: 2026-10-15. Inputs (fixed): 1.0/1025 source snapshot `d13fdfa`, 1.1/1112 source snapshot `8c80ceb`.
Strategy: INTEG-DESIGN-01 / C0 - keep the 1.0 shell and its metering semantics, open the 1.1 expansion shell from an
explicit lobby entry behind the same access ledger. Nothing here changes the commercial rules.

## What is integrated

| Layer | Result |
|---|---|
| Rules / records / content / bot / motion / visuals (Swift package) | Both lines merged; the original rules stay the default (`expansionSkills` off) |
| App shell | 1.0 `PlayableGameView` kept byte-for-byte except: `HeroClass` gains the priest, one switch gains two cases, one new lobby entry and one full-screen cover |
| Expansion shell | 1.1's whole interface as `ExpansionGameView`, opened from the lobby entry "擴充玩法" |
| Access gate | The expansion start asks the same `PlayAccess` (`canStartMatch` for what to show, `authorizeNewMatch` as the permission) before any state changes; terminal states are reported to the ledger |
| Expansion match identity (C0 S4) | `ExpansionMatchRecord.matchID` (optional, generated once per started match, kept across saves/resume); legacy files stay unregistered and are never given an identity while decoding |
| Project file | Merged object by object; 13 colliding ids renumbered; no undefined references |
| Name collisions | `MageBodyView` / `MageBodyAssets` exist in both lines; the three 1.1-only files use `PresentationMageBody*` |
| Shared mage clock | `MageTempo` keeps 1.0's tuned timings; the 1.1 `r2` contact cast reads the same clock (see "Needs a human look") |

## What is deliberately NOT changed

- **Release configuration and Release asset script**: a Release build of this branch is the 1.0 product (the
  expansion entry is compiled out, the expansion presentation assets are excluded). Enabling it for shipping is
  prepared in `RELEASE_ENABLE_EXPANSION.md` and not applied.
- No metering policy change: trial is consumed at completion, a reward credit is reserved at start, restart is a new
  match with a new identity, there is no step threshold, no single-match limit and no resign.

## Verification (this machine; simulator; unsigned)

| Check | Result |
|---|---|
| Swift package, all targets | 424 tests (405 from the union of both lines + 5 identity + 7 pending-admission + 7 continuation), 0 failures |
| App build, Debug / iOS Simulator | succeeded |
| App build, Beta (V11 flag, expansion assets) / iOS Simulator | succeeded |
| New `IntegrationUITests` on iPhone 16 simulator | 7 / 7 passed (two are the R1 recovery cases, one is the M6 copy case); the first four: explicit entry and return, expansion start gated by the same ledger when the trial is exhausted, start admitted while a trial remains, original shell still starts the original match |
| Existing `MonetizationUITests` (1.0 paywall) | 9 / 9 passed |
| Existing `RewardedAdNetworkUITests` | 2 / 2 passed |
| 1.1 `MonsterLabTests` / `PresentationLabTests` | 7 / 7 and 8 / 8 passed |
| 1.1 `ExpansionLabTests` (driven against `ExpansionGameView`) | 26 passed, 7 skipped by the tests themselves (DEBUG-only fixtures), 1 failed: `testIntegratedCastingMuteReducedMotionAndBackgroundCancelPlayers`, which fails identically on the 1.1 snapshot `8c80ceb` (same missing `audioSettings` element) - pre-existing |
| Existing `PlayableGameTests` / `AdvancedChallengeUITests` / `BoardInteractionTests` (119 run) | 37 failed on the first run. The same 34 that exist in 1.0 were re-run on the clean 1.0 snapshot (`d13fdfa`, same simulator): 32 fail there too (pre-existing, e.g. tablet-sized tests on an iPhone simulator, stale expectations) and 2 passed there but failed here - both were real integration defects, fixed (below). The 3 remaining failures were 1.1-only tests that need the 1.1 shell: routed to `ExpansionGameView` via the DEBUG-only `--integrated-*` launch arguments, 3 / 3 now pass |

## Defects found by the regression run (fixed on this branch)

1. `GameStore.resume` called `leaveMatch()` (which re-saves the previous record). Creating a candidate copy then made the
   original newer than its copy, so "resume" after a relaunch restored the original rules instead of the copy. The 1.0
   behaviour is restored: only a live expansion match is dropped there.
2. The merged test file had taken three lines of the 1.1 interface (`mageOperation` as a menu, `resultReplay`) for tests
   that drive the 1.0 shell; reverted to the 1.0 interface. The three 1.1-only audit tests now start the expansion shell.

## Known pre-existing failures (same on the 1.0 snapshot, not caused by the integration)

32 UI tests (tablet / landscape tests run on an iPhone simulator, tests of 1.1-era UI that the 1.0 source tree itself no
longer matches, `testNineBoardAccessibleGridWinAndDraw`, ...). They are listed so a later cleanup can decide; the
integration neither fixes nor worsens them. No iPad simulator run was made.

## Match copies (C0 M6, option (a) as recommended by the owner; not yet formally decided)

A playable "new-version-skills" copy keeps its own match identity but continues its parent's single admission:
creating it uses no allowance and no reward, finishing it settles the parent's admission exactly once, a copy of a
copy collapses to the original admission, and a copy of a never-registered match stays unmetered. Implemented in the
access ledger as an optional `continuationOf` link (same ledger schema version; an entry without it reads exactly as
before). The link is written before the copy file exists, so a stop leaves at most an unused ledger entry.
If the owner chooses option (b) instead (a copy is a new full match) this is the one place to change.

## Not verified / known gaps

- C# replay and C#/Swift step-by-step equivalence were not re-run (no `dotnet` on this machine). The Swift side of the
  shared Golden fixtures passes in both lines and the fixture trees are identical.
- The 1.1-only tests were not re-run on the 1.1 snapshot as a baseline (they pass here).
- No physical device, no iPad, no signed archive, no TestFlight, no App Store action.
- The expansion single save slot: starting a new expansion match replaces an unfinished saved expansion match (existing
  1.1 behaviour). The replaced match was never charged because the trial is consumed at completion.
- A copy made while the player owns the unlock is not linked (nothing is metered for owners); if the entitlement is later
  revoked, such a copy is treated like an unregistered legacy match.
- Real 1.0-produced save files (S5) have not been obtained; compatibility is covered at unit level only.
- C0 R1 (the crash window between "record saved" and "ledger written" for ORIGINAL matches) is handled by a sidecar
  marker (`<id>.pending`, `PendingAdmissionJournal`) instead of a new field in the match record, so the 1.0 save schema
  is unchanged. After a stop in that window the unplayed, never-authorized record is removed at the next launch (it is
  not charged and not kept as a free match); a record that already has moves, or any record the ledger knows, is left
  alone. Covered by 7 package tests and 2 UI tests. Not covered: a stop inside the ledger file write itself (that file
  is written atomically), and the expansion single-slot save (authorization happens before its save, so there is no
  window).

## Needs a human look (cannot be decided by tests)

1. Two visual systems coexist (1.0 Cozy shell, 1.1 GameInterface shell). Unifying them is decision D1.
2. The 1.1 mage animation `r2` now runs on 1.0's shared mage timing (release 0.26 / moveStart 0.38 / arrival 0.60
   instead of 0.28 / 0.30 / 0.54). Looks slightly different from the TestFlight 1.1 candidate; confirm by eye.
3. English hero voices: not shipped in Release by policy; their listening review is still open (D5).
4. Whether the expansion should be on in the shipping build and under which version (D3/D4/D6).

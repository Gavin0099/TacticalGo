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
| Swift package, all targets | 405 tests (union of both lines) + 5 new identity tests, 0 failures |
| App build, Debug / iOS Simulator | succeeded |
| App build, Beta (V11 flag, expansion assets) / iOS Simulator | succeeded |
| New `IntegrationUITests` on iPhone 16 simulator | 4 / 4 passed: explicit entry and return, expansion start gated by the same ledger when the trial is exhausted, start admitted while a trial remains, original shell still starts the original match |
| Existing `MonetizationUITests` (1.0 paywall) | see the result recorded in the pull request |

## Not verified / known gaps

- C# replay and C#/Swift step-by-step equivalence were not re-run (no `dotnet` on this machine). The Swift side of the
  shared Golden fixtures passes in both lines and the fixture trees are identical.
- The full existing UI suites (`PlayableGameTests`, `AdvancedChallengeUITests`, `ExpansionLabTests`, ...) were not run
  end to end; only the monetization suite and the new integration tests were.
- No physical device, no iPad, no signed archive, no TestFlight, no App Store action.
- The expansion single save slot: starting a new expansion match replaces an unfinished saved expansion match (existing
  1.1 behaviour). The replaced match was never charged because the trial is consumed at completion.
- Real 1.0-produced save files (S5) have not been obtained; compatibility is covered at unit level only.
- C0 R1 (the crash window between "record saved" and "admission written" for ORIGINAL matches) is not implemented;
  it is the existing 1.0 behaviour and unchanged by this integration.

## Needs a human look (cannot be decided by tests)

1. Two visual systems coexist (1.0 Cozy shell, 1.1 GameInterface shell). Unifying them is decision D1.
2. The 1.1 mage animation `r2` now runs on 1.0's shared mage timing (release 0.26 / moveStart 0.38 / arrival 0.60
   instead of 0.28 / 0.30 / 0.54). Looks slightly different from the TestFlight 1.1 candidate; confirm by eye.
3. English hero voices: not shipped in Release by policy; their listening review is still open (D5).
4. Whether the expansion should be on in the shipping build and under which version (D3/D4/D6).

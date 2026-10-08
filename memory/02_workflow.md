# Tech Stack

## Repo Facts

- Product target: iPhone native app, Swift + SwiftUI (decision record: `docs/TECH_DECISION.md`, 2026-10-08).
- Rules engine to be an independent Swift Package; UI consumes engine events only.
- Current code: C# (.NET 9) reference engine `src/TacticalGo.Domain`, xUnit tests `tests/TacticalGo.Domain.Tests`, simulator `src/TacticalGo.Sim`. This is the spec-reference implementation, not shipped code.
- Single source of rules text: `docs/RULES_DRAFT.md` (Draft; `【補】` marks assumptions awaiting Owner review).
- Dev machine is Windows 11 with no Swift/Xcode; iOS build needs macOS (physical or cloud CI).
- Commands: `dotnet test` (all tests), `dotnet run --project src/TacticalGo.Sim -c Release -- ap 1000` (S0 AP comparison).

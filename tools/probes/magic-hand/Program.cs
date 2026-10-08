using System.Diagnostics;
using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Serialization;
using TacticalGo.Domain;

if (args.Length == 2 && args[0] == "--review-supplement")
{
    ReviewSupplement.Run(args[1]);
    return;
}

// Fixed, deliberately small experiment. No random generator, background loop or automatic budget extension.
const int NodeLimit = 50_000;
const int SecondsLimit = 30;
var output = args.Length == 1 ? args[0] : "docs/evidence/r1-magic-hand/search.json";
var clock = Stopwatch.StartNew();
var nodes = 0;
var cases = new List<object>();
var rows = new List<(string Name, int A, int B, int C)>();

var connector = new GameAction[] {
    new PlaceSoldier(new(1, 4)), new PlaceSoldier(new(1, 1)), new PlaceSoldier(new(2, 1)),
    new PlaceSoldier(new(0, 0)), new PlaceSoldier(new(0, 2)), new EndTurn(),
};
var definitions = new[] {
    new Case("connector_range_two", new(4,4), new(0,1),
        [.. connector, new SummonHero(new(1,3)), new EndTurn(), new EndTurn()]),
    new Case("connector_adjacent", new(4,4), new(0,1),
        [.. connector, new SummonHero(new(1,0)), new EndTurn(), new EndTurn()]),
    new Case("corner_soldier_capture", new(3,3), new(3,1),
        [new PlaceSoldier(new(0,1)), new PlaceSoldier(new(1,0)), new EndTurn(),
         new PlaceSoldier(new(2,1)), new SummonHero(new(2,0)), new EndTurn()]),
    new Case("commander_relief", new(0,0), new(3,3),
        [new PlaceSoldier(new(2,1)), new PlaceSoldier(new(1,0)), new EndTurn(),
         new SummonHero(new(1,1)), new EndTurn(), new EndTurn()]),
};

try
{
    foreach (var definition in definitions)
    {
        var variants = new List<object>();
        var wins = new List<int>();
        var sameBoard = "";
        foreach (var strategy in new[] { "A", "B", "C" })
        {
            var heroClass = strategy == "C" ? HeroClass.Rogue : HeroClass.Mage;
            var config = new RuleConfig { BoardSize = 5, MageSkill = MageSkill.MagicHand,
                CommanderOneStart = definition.One, CommanderTwoStart = definition.Two };
            // Keep the complete legal history. FromDiagram would erase superko evidence.
            var session = GameSession.Replay(config, heroClass, HeroClass.None, definition.Replay);
            var root = session.State;
            if (root.Current != Player.One || root.ApRemaining != 2 || root.Status != GameStatus.Ongoing)
                throw new InvalidOperationException("A root must start a complete Black turn.");
            AssertLiveGroups(root);
            if (strategy != "A" && root.Board.ToString() != sameBoard)
                throw new InvalidOperationException("Comparison board placements differ.");
            sameBoard = root.Board.ToString();

            var plans = OwnPlans(root, strategy);
            var ordered = plans.OrderByDescending(p => p.State.Winner == Player.One)
                .ThenByDescending(p => p.CapturedSoldiers).ThenByDescending(p => CommanderLiberties(p.State))
                .ThenBy(p => string.Join(';', p.Actions.Select(a => a.ToString())), StringComparer.Ordinal).ToList();
            var best = ordered.FirstOrDefault();
            var winCount = plans.Count(p => p.State.Winner == Player.One);
            wins.Add(winCount);
            variants.Add(new {
                strategy, label = strategy switch { "A" => "Magic Hand + placement", "B" => "placement + placement", _ => "Rogue swap + placement" },
                heroClass, config, replayFromNewGame = definition.Replay.Select(ActionDto),
                reachability = "custom_5x5_replay_only_not_standard_9x9_reachable", initialBoard = root.Board.ToString(),
                evidenceClassification = "mechanism_demonstration",
                rootEnemyCommanderLiberties = BoardRuleEngine.CountLiberties(root.Board, definition.Two),
                rootEnemyCommanderLibertyPoints = BoardRuleEngine.GetLiberties(root.Board,
                    BoardRuleEngine.GetGroup(root.Board, definition.Two)).OrderBy(p => p.Y).ThenBy(p => p.X),
                rootPly = root.Ply, rootAp = root.ApRemaining,
                rootMana = new[] { root.ManaOf(Player.One), root.ManaOf(Player.Two) },
                rootCommanderLiberties = CommanderLiberties(root), legalPlans = plans.Count,
                immediateCommanderWins = winCount,
                maxEnemySoldiersCaptured = plans.Count == 0 ? (int?)null : plans.Max(p => p.CapturedSoldiers),
                best = best is null ? null : new {
                    actions = best.Actions.Select(ActionDto), events = best.Events.Select(e => e.GetType().Name),
                    boardAfterOurTurn = best.State.Board.ToString(), best.State.Status, best.State.Winner,
                    capturedSoldiers = best.CapturedSoldiers, commanderLiberties = CommanderLiberties(best.State),
                    response = Respond(best.State),
                },
            });
        }
        rows.Add((definition.Name, wins[0], wins[1], wins[2]));
        cases.Add(new { name = definition.Name, variants });
    }
    // Independently hand-reasoned experiment expectations, not output copied into a golden fixture.
    if (rows[0].A == 0 || rows[0].B != 0 || rows[0].C != 0 || rows[1].C == 0)
        throw new InvalidOperationException("Known tactical controls disagree; do not publish a successful search result.");
    WriteReport("completed", null);
    foreach (var row in rows) Console.WriteLine($"{row.Name}: commander-win plans A={row.A} B={row.B} C={row.C}");
    Console.WriteLine($"Completed {definitions.Length} positions / 3 strategies; {nodes} apply attempts. Report: {output}");
}
catch (BudgetExceeded e)
{
    WriteReport("incomplete_budget", e.Message);
    Console.Error.WriteLine(e.Message);
    Environment.ExitCode = 2;
}

void Guard()
{
    if (++nodes > NodeLimit || clock.Elapsed.TotalSeconds >= SecondsLimit)
        throw new BudgetExceeded("Fixed search budget reached; no automatic extension. Partial results are not exhaustive.");
}

ActionOutcome Apply(GameState s, GameAction a)
{
    Guard();
    return GameEngine.Apply(s, a);
}

List<Plan> OwnPlans(GameState root, string strategy)
{
    var plans = new List<Plan>();
    IEnumerable<GameAction> first = strategy switch {
        "A" => root.Board.AllPoints().SelectMany(p => Enum.GetValues<PushDirection>().Select(d => (GameAction)new CastMagicHand(p, d))),
        "B" => root.Board.AllPoints().Select(p => (GameAction)new PlaceSoldier(p)),
        _ => root.Board.AllPoints().Select(p => (GameAction)new CastSwap(p)),
    };
    foreach (var a in first)
    {
        var one = Apply(root, a);
        if (!one.Success) continue;
        if (one.State.Status != GameStatus.Ongoing)
        {
            plans.Add(new([a], one.State, one.Events)); // Count an early win; don't invent a second action after game over.
            continue;
        }
        foreach (var p in root.Board.AllPoints())
        {
            var b = new PlaceSoldier(p);
            var two = Apply(one.State, b);
            if (two.Success) plans.Add(new([a, b], two.State, [.. one.Events, .. two.Events]));
        }
    }
    return plans;
}

object Respond(GameState after)
{
    if (after.Status != GameStatus.Ongoing)
        return new { status = "terminal_no_response", lines = 0, ownCommanderLosses = 0, counterexample = (object?)null };
    var lines = 0;
    var losses = 0;
    object? counterexample = null;
    foreach (var (leaf, actions) in OpponentLines(after, []))
    {
        lines++;
        if (leaf.Winner == Player.Two)
        {
            losses++;
            counterexample ??= new { actions = actions.Select(ActionDto), board = leaf.Board.ToString() };
        }
    }
    return new { status = "exhaustive_for_selected_witness_only", lines, ownCommanderLosses = losses, counterexample };
}

IEnumerable<(GameState State, GameAction[] Actions)> OpponentLines(GameState state, GameAction[] actions)
{
    if (state.Status != GameStatus.Ongoing || state.Current != Player.Two)
    {
        yield return (state, actions);
        yield break;
    }
    // White has no class. All board placements + voluntary EndTurn are considered, with actual legality/superko.
    foreach (var a in state.Board.AllPoints().Select(p => (GameAction)new PlaceSoldier(p)).Append(new EndTurn()))
    {
        var outcome = Apply(state, a);
        if (!outcome.Success) continue;
        foreach (var leaf in OpponentLines(outcome.State, [.. actions, a])) yield return leaf;
    }
}

int CommanderLiberties(GameState s) => s.Board.FindCommander(Player.One) is { } p
    ? BoardRuleEngine.CountLiberties(s.Board, p) : 0;

void AssertLiveGroups(GameState s)
{
    foreach (var p in s.Board.AllPoints())
        if (s.Board[p] is not null && BoardRuleEngine.CountLiberties(s.Board, p) == 0)
            throw new InvalidOperationException("A replayed root has a dead group.");
}

object ActionDto(GameAction a) => a switch {
    PlaceSoldier p => new { type = "PlaceSoldier", at = new[] { p.At.X, p.At.Y } },
    SummonHero p => new { type = "SummonHero", at = new[] { p.At.X, p.At.Y } },
    CastMagicHand p => new { type = "CastMagicHand", target = new[] { p.Target.X, p.Target.Y }, direction = p.Direction.ToString() },
    CastSwap p => new { type = "CastSwap", target = new[] { p.Target.X, p.Target.Y } },
    EndTurn => new { type = "EndTurn" },
    _ => throw new NotSupportedException(a.ToString()),
};

void WriteReport(string status, string? limitation)
{
    var sources = Directory.GetFiles("src/TacticalGo.Domain", "*.cs").Order(StringComparer.Ordinal)
        .Append("tools/probes/magic-hand/Program.cs").ToDictionary(p => p.Replace('\\', '/'),
            p => Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(p))).ToLowerInvariant());
    var report = new {
        status, limitation, boardSize = 5, intendedPositions = definitions.Length, strategiesPerPosition = 3,
        ourMaxAtomicDepth = 2, opponentMaxAtomicDepth = 2, totalMaxAtomicDepth = 4,
        nodeLimit = NodeLimit, secondsLimit = SecondsLimit, applyAttempts = nodes,
        opponent = "None class; every legal placement and EndTurn for its next turn; no skills; no moves after terminal win",
        witnessSelection = "immediate commander win, then captured enemy soldiers, then own commander liberties, then ordinal action text",
        responseScope = "all replies to one selected witness per strategy; not minimax across all own plans",
        reachability = "all roots replayed from NewGame with custom 5x5 commander starts and legal cooperative moves",
        comparability = "identical board, AP and histories of board placements; Mage and Rogue use their existing summon costs, so root Mana differs; both can afford one skill",
        notCovered = new[] { "7x7 or 9x9", "uncooperative setup opponent", "opponent hero skills", "multi-turn continuation",
            "other hero deployments", "Seal defensive search", "balance", "fun", "G0/G1/G3/G5 acceptance" },
        sourceSha256 = sources, cases,
    };
    Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(output))!);
    File.WriteAllText(output, JsonSerializer.Serialize(report, new JsonSerializerOptions {
        WriteIndented = true, Converters = { new JsonStringEnumConverter() },
    }) + "\n");
}

sealed record Case(string Name, Point One, Point Two, GameAction[] Replay);
sealed record Plan(GameAction[] Actions, GameState State, IReadOnlyList<ActionEvent> Events)
{
    public int CapturedSoldiers => Events.OfType<PiecesCaptured>().SelectMany(e => e.Pieces)
        .Count(c => c.Piece.Owner == Player.Two && c.Piece.Kind == PieceKind.Soldier);
}
sealed class BudgetExceeded(string message) : Exception(message);

using System.Diagnostics;
using System.Security.Cryptography;
using System.Text.Json;
using System.Text.Json.Serialization;
using TacticalGo.Domain;

// Two hand-selected previous-turn choices, not a search for an unanswerable attack.
internal static class ReviewSupplement
{
    public static void Run(string output)
    {
        const int NodeLimit = 20_000, SecondsLimit = 30;
        var clock = Stopwatch.StartNew();
        var nodes = 0;
        var standard = new RuleConfig { MageSkill = MageSkill.MagicHand };
        if (standard.BoardSize != 9 || standard.CommanderOneStart != new Point(4, 7) ||
            standard.CommanderTwoStart != new Point(4, 1))
            throw new InvalidOperationException("This supplement requires the existing standard commander starts.");
        GameAction[] customReplay = [new PlaceSoldier(new(1,4)), new PlaceSoldier(new(1,1)),
            new PlaceSoldier(new(2,1)), new PlaceSoldier(new(0,0)), new PlaceSoldier(new(0,2)),
            new EndTurn(), new SummonHero(new(1,3)), new EndTurn(), new EndTurn()];
        var custom = GameSession.Replay(standard with { BoardSize = 5,
            CommanderOneStart = new(4,4), CommanderTwoStart = new(0,1) },
            HeroClass.Mage, HeroClass.None, customReplay).State;
        Point[] expected = [new(1,0), new(2,0), new(3,1), new(1,2), new(2,2)];
        var liberties = BoardRuleEngine.GetLiberties(custom.Board, BoardRuleEngine.GetGroup(custom.Board, new(0,1)))
            .OrderBy(p => p.Y).ThenBy(p => p.X).ToArray();
        if (!liberties.SequenceEqual(expected)) throw new InvalidOperationException("Reviewed five liberties disagree.");

        GameAction[] setup = [new PlaceSoldier(new(3,4)), new PlaceSoldier(new(4,2)),
            new PlaceSoldier(new(4,3)), new PlaceSoldier(new(4,0)), new PlaceSoldier(new(3,1)),
            new EndTurn(), new PlaceSoldier(new(5,1)), new SummonHero(new(3,3))];
        var previous = GameSession.Replay(standard, HeroClass.Mage, HeroClass.None, setup).State;
        if (previous.Current != Player.Two || previous.ApRemaining != 2)
            throw new InvalidOperationException("Opponent must see the deployed mage before deciding its two actions.");
        var cases = new List<object>();
        var status = "completed";
        string? limitation = null;
        try
        {
            foreach (var (name, reply) in new[] {
                ("opponent_passes", new GameAction[] { new EndTurn() }),
                ("opponent_blocks_both_push_destinations", new GameAction[] {
                    new PlaceSoldier(new(3,2)), new PlaceSoldier(new(5,2)) }) })
            {
                var variants = new List<object>();
                foreach (var strategy in new[] { "A", "B", "C" })
                {
                    var hero = strategy == "C" ? HeroClass.Rogue : HeroClass.Mage;
                    var root = GameSession.Replay(standard, hero, HeroClass.None, setup.Concat(reply)).State;
                    var wins = new List<object>();
                    var legal = 0;
                    IEnumerable<GameAction> first = strategy switch {
                        "A" => root.Board.AllPoints().SelectMany(p => Enum.GetValues<PushDirection>()
                            .Select(d => (GameAction)new CastMagicHand(p,d))),
                        "B" => root.Board.AllPoints().Select(p => (GameAction)new PlaceSoldier(p)),
                        _ => root.Board.AllPoints().Select(p => (GameAction)new CastSwap(p)),
                    };
                    foreach (var a in first)
                    {
                        var one = Apply(root, a);
                        if (!one.Success) continue;
                        if (one.State.Status != GameStatus.Ongoing)
                        {
                            Record(one, [a]);
                            continue;
                        }
                        foreach (var p in root.Board.AllPoints())
                        {
                            var b = new PlaceSoldier(p);
                            var two = Apply(one.State, b);
                            if (two.Success) Record(two, [a,b]);
                        }
                    }
                    variants.Add(new { strategy, heroClass = hero, config = standard,
                        replayFromNewGame = setup.Concat(reply).Select(ActionDto), board = root.Board.ToString(),
                        root.Ply, root.ApRemaining, mana = new[] { root.ManaOf(Player.One), root.ManaOf(Player.Two) },
                        enemyCommanderLiberties = BoardRuleEngine.CountLiberties(root.Board, new(4,1)),
                        legalPlans = legal, immediateCommanderWins = wins.Count, winningLines = wins });
                    void Record(ActionOutcome result, GameAction[] actions)
                    {
                        legal++;
                        if (result.State.Winner == Player.One) wins.Add(new {
                            actions = actions.Select(ActionDto), board = result.State.Board.ToString(), result.State.Winner });
                    }
                }
                cases.Add(new { name, previousOpponentActions = reply.Select(ActionDto), variants });
            }
        }
        catch (InvalidOperationException e) when (e.Message.StartsWith("Fixed supplement budget"))
        {
            status = "incomplete_budget";
            limitation = e.Message;
            Environment.ExitCode = 2;
        }
        var sources = Directory.GetFiles("src/TacticalGo.Domain", "*.cs")
            .Concat(Directory.GetFiles("tools/probes/magic-hand", "*.cs"))
            .Order(StringComparer.Ordinal).ToDictionary(p => p.Replace('\\','/'),
                p => Convert.ToHexString(SHA256.HashData(File.ReadAllBytes(p))).ToLowerInvariant());
        var report = new { status, limitation, nodeLimit = NodeLimit, secondsLimit = SecondsLimit,
            applyAttempts = nodes, rules = "See sourceSha256 for exact target rules; use a new output path when rerunning a later version.",
            customAudit = new { caseName = "connector_range_two", initialBoard = custom.Board.ToString(),
                enemyCommander = new Point(0,1), libertyCount = liberties.Length, libertyPoints = liberties,
                classification = "mechanism_demonstration_custom_5x5_only",
                standard9x9Reachability = "impossible_commander_is_immobile_and_starts_at_4_1",
                sevenBySevenReachability = "not_established_commander_starts_undecided" },
            standard9x9 = new { config = standard, setupToOpponentsPreviousTurn = setup.Select(ActionDto),
                previousOpponentBoard = previous.Board.ToString(), previous.Current, previous.ApRemaining,
                classification = "legally_replayable_standard_9x9_cooperative_setup",
                ourMaxAtomicDepth = 2, selectedPreviousOpponentDepth = 2,
                previousOpponentStrategy = "Two hand-selected choices: pass, or occupy both lateral connector destinations. All A/B/C immediate plans checked after each selected choice; no exhaustive prior-turn opponent search.",
                cases }, sourceSha256 = sources,
            notCovered = new[] { "forced setup", "all opponent previous-turn choices", "opponent hero skills",
                "future turns", "7x7", "friendly push rule extension", "Seal defensive search", "balance", "fun", "UI or Gate acceptance" } };
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(output))!);
        File.WriteAllText(output, JsonSerializer.Serialize(report, new JsonSerializerOptions {
            WriteIndented = true, Converters = { new JsonStringEnumConverter() } }) + "\n");
        Console.WriteLine($"{status}: custom liberties={liberties.Length}; {cases.Count} selected 9x9 roots / 3 strategies; {nodes} Apply attempts; {output}");

        ActionOutcome Apply(GameState state, GameAction action)
        {
            if (++nodes > NodeLimit || clock.Elapsed.TotalSeconds >= SecondsLimit)
                throw new InvalidOperationException("Fixed supplement budget reached; no extension or retry.");
            return GameEngine.Apply(state, action);
        }
    }

    private static object ActionDto(GameAction action) => action switch {
        PlaceSoldier a => new { type = "PlaceSoldier", at = new[] { a.At.X, a.At.Y } },
        SummonHero a => new { type = "SummonHero", at = new[] { a.At.X, a.At.Y } },
        CastMagicHand a => new { type = "CastMagicHand", target = new[] { a.Target.X, a.Target.Y }, direction = a.Direction.ToString() },
        CastSwap a => new { type = "CastSwap", target = new[] { a.Target.X, a.Target.Y } },
        EndTurn => new { type = "EndTurn" },
        _ => throw new NotSupportedException(action.ToString()),
    };
}

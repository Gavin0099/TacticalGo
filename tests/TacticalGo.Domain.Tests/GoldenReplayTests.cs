using System.Text.Json;
using TacticalGo.Domain;

namespace TacticalGo.Domain.Tests;

/// <summary>
/// Runs the language-neutral fixtures in tests/golden (format: tests/golden/README.md). The same files are meant to be
/// replayed by the Swift port; expected values were authored by hand, not exported from this engine.
/// </summary>
public class GoldenReplayTests
{
    public static IEnumerable<object[]> Fixtures() =>
        Directory.GetFiles(Path.Combine(AppContext.BaseDirectory, "golden"), "*.json")
            .OrderBy(f => f, StringComparer.Ordinal)
            .Select(f => new object[] { Path.GetFileNameWithoutExtension(f) });

    [Fact]
    public void Fixture_set_is_not_empty()
    {
        Assert.True(Fixtures().Count() >= 20);
    }

    [Theory]
    [MemberData(nameof(Fixtures))]
    public void Replay_matches_expected(string name)
    {
        using var doc = JsonDocument.Parse(File.ReadAllText(Path.Combine(AppContext.BaseDirectory, "golden", name + ".json")));
        var root = doc.RootElement;
        var config = ParseConfig(root.GetProperty("config"));
        var state = BuildInitialState(config, root.GetProperty("setup"));

        if (root.TryGetProperty("expectInitial", out var initial))
            Check(initial, state, null, $"{name} initial");

        var step = 0;
        foreach (var stepJson in root.GetProperty("steps").EnumerateArray())
        {
            step++;
            var action = ParseAction(stepJson.GetProperty("action"));
            var before = state;
            var fingerprint = state.Fingerprint();
            var outcome = GameEngine.Apply(state, action);
            Assert.Equal(fingerprint, before.Fingerprint());
            if (!outcome.Success)
            {
                Assert.Same(before, outcome.State); // Includes the shared position history, absent from Fingerprint.
                Assert.Empty(outcome.Events);
            }
            state = outcome.State;
            Check(stepJson.GetProperty("expect"), state, outcome, $"{name} step {step} ({action})");
        }
    }

    private static RuleConfig ParseConfig(JsonElement c)
    {
        var config = new RuleConfig();
        foreach (var prop in c.EnumerateObject())
        {
            config = prop.Name switch
            {
                "boardSize" => config with { BoardSize = prop.Value.GetInt32() },
                "apPerTurn" => config with { ApPerTurn = prop.Value.GetInt32() },
                "firstTurnAp" => config with { FirstTurnAp = prop.Value.ValueKind == JsonValueKind.Null ? null : prop.Value.GetInt32() },
                "maxPlies" => config with { MaxPlies = prop.Value.GetInt32() },
                "manaCap" => config with { ManaCap = prop.Value.GetInt32() },
                "allowResummon" => config with { AllowResummon = prop.Value.GetBoolean() },
                "mageSkill" => config with { MageSkill = Enum.Parse<MageSkill>(prop.Value.GetString()!) },
                "magicHandRange" => config with { MagicHandRange = prop.Value.GetInt32() },
                _ => throw new NotSupportedException($"Unknown config key '{prop.Name}'."),
            };
        }
        return config;
    }

    private static GameState BuildInitialState(RuleConfig config, JsonElement setup)
    {
        var classes = setup.GetProperty("classes").EnumerateArray().Select(e => Enum.Parse<HeroClass>(e.GetString()!)).ToArray();
        if (setup.TryGetProperty("newGame", out var isNew) && isNew.GetBoolean())
            return GameSetup.NewGame(config, classes[0], classes[1]);

        var rows = setup.GetProperty("diagram").EnumerateArray()
            .Select(r => new string(r.GetString()!.Where(c => !char.IsWhiteSpace(c)).ToArray())).ToList();
        while (rows.Count < config.BoardSize) rows.Add("");
        var diagram = string.Join('\n', rows.Select(r => r.PadRight(config.BoardSize, '.')));
        var mana = setup.GetProperty("mana").EnumerateArray().Select(e => e.GetInt32()).ToArray();
        var summoned = setup.GetProperty("heroSummoned").EnumerateArray().Select(e => e.GetBoolean()).ToArray();
        return GameSetup.FromDiagram(config, diagram, classes[0], classes[1],
            Enum.Parse<Player>(setup.GetProperty("current").GetString()!),
            mana[0], mana[1], setup.GetProperty("ap").GetInt32(), 1, summoned[0], summoned[1]);
    }

    private static Point At(JsonElement e) => new(e[0].GetInt32(), e[1].GetInt32());

    private static GameAction ParseAction(JsonElement a) => a.GetProperty("type").GetString() switch
    {
        "PlaceSoldier" => new PlaceSoldier(At(a.GetProperty("at"))),
        "SummonHero" => new SummonHero(At(a.GetProperty("at"))),
        "CastBastion" => new CastBastion(At(a.GetProperty("first")), At(a.GetProperty("second"))),
        "CastSeal" => new CastSeal(At(a.GetProperty("at"))),
        "CastSwap" => new CastSwap(At(a.GetProperty("target"))),
        "CastMagicHand" => new CastMagicHand(At(a.GetProperty("target")), Enum.Parse<PushDirection>(a.GetProperty("direction").GetString()!)),
        "EndTurn" => new EndTurn(),
        var other => throw new NotSupportedException($"Unknown action type '{other}'."),
    };

    private static void Check(JsonElement expect, GameState state, ActionOutcome? outcome, string where)
    {
        foreach (var prop in expect.EnumerateObject())
        {
            var v = prop.Value;
            switch (prop.Name)
            {
                case "ok":
                    Assert.True(outcome is not null, $"{where}: 'ok' only valid on steps");
                    Assert.True(v.GetBoolean() == outcome!.Success,
                        $"{where}: expected ok={v.GetBoolean()} but got ok={outcome.Success} ({outcome.Validation.Reason}: {outcome.Validation.Message})");
                    break;
                case "reason":
                    Assert.Equal(v.GetString(), outcome!.Validation.Reason.ToString());
                    break;
                case "cells":
                    foreach (var cell in v.EnumerateObject())
                    {
                        var xy = cell.Name.Split(',');
                        var actual = BoardText.ToChar(state.Board[new Point(int.Parse(xy[0]), int.Parse(xy[1]))]);
                        Assert.True(cell.Value.GetString() == actual.ToString(), $"{where}: cell {cell.Name} expected '{cell.Value.GetString()}' got '{actual}'");
                    }
                    break;
                case "current": Assert.Equal(v.GetString(), state.Current.ToString()); break;
                case "ply": Assert.Equal(v.GetInt32(), state.Ply); break;
                case "ap": Assert.Equal(v.GetInt32(), state.ApRemaining); break;
                case "status": Assert.Equal(v.GetString(), state.Status.ToString()); break;
                case "winner":
                    Assert.Equal(v.ValueKind == JsonValueKind.Null ? null : v.GetString(), state.Winner?.ToString());
                    break;
                case "mana":
                    Assert.Equal([v[0].GetInt32(), v[1].GetInt32()], [state.ManaOf(Player.One), state.ManaOf(Player.Two)]);
                    break;
                case "seals":
                    Assert.Equal(v.EnumerateArray().Select(s => At(s).ToString()).OrderBy(s => s),
                        state.Seals.Select(s => s.At.ToString()).OrderBy(s => s));
                    break;
                case "events":
                    Assert.Equal(v.EnumerateArray().Select(e => e.GetString()!),
                        outcome!.Events.Select(e => e.GetType().Name));
                    break;
                case "skillUsed": Assert.Equal(v.GetBoolean(), state.SkillUsedThisTurn); break;
                case "liberties":
                    foreach (var cell in v.EnumerateObject())
                    {
                        var xy = cell.Name.Split(',');
                        Assert.Equal(cell.Value.GetInt32(), BoardRuleEngine.CountLiberties(state.Board,
                            new Point(int.Parse(xy[0]), int.Parse(xy[1]))));
                    }
                    break;
                case "groups":
                    foreach (var cell in v.EnumerateObject())
                    {
                        var xy = cell.Name.Split(',');
                        Assert.Equal(cell.Value.EnumerateArray().Select(At).OrderBy(p => p.Y).ThenBy(p => p.X),
                            BoardRuleEngine.GetGroup(state.Board, new Point(int.Parse(xy[0]), int.Parse(xy[1])))
                                .OrderBy(p => p.Y).ThenBy(p => p.X));
                    }
                    break;
                default:
                    throw new NotSupportedException($"{where}: unknown expect key '{prop.Name}'.");
            }
        }
    }
}

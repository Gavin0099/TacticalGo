using TacticalGo.Domain;
using static TacticalGo.Domain.Tests.TestKit;

namespace TacticalGo.Domain.Tests;

/// <summary>
/// S0 Gate evidence, deterministic part: if BOTH sides ignore defence and only fill the enemy commander's liberties,
/// who wins the race and on which ply? This documents the tempo arithmetic behind the 1 AP vs 2 AP question.
/// It is NOT a claim about real play, where defence exists.
/// </summary>
public class TempoRaceTests
{
    private static (Player? Winner, int Ply) PureRace(RuleConfig config)
    {
        var g = GameSetup.NewGame(config, HeroClass.None, HeroClass.None);
        while (g.Status == GameStatus.Ongoing)
        {
            var enemy = g.Current.Opponent();
            var commander = g.Board.FindCommander(enemy)!.Value;
            var target = BoardRuleEngine.GetLiberties(g.Board, BoardRuleEngine.GetGroup(g.Board, commander))
                .OrderBy(p => p.Y).ThenBy(p => p.X).First();
            g = Play(g, new PlaceSoldier(target));
        }
        return (g.Winner, g.Ply);
    }

    [Fact]
    public void Two_ap_pure_race_player_one_kills_on_ply_three()
    {
        Assert.Equal((Player.One, 3), PureRace(RuleConfig.TwoApBaseline));
    }

    [Fact]
    public void One_ap_pure_race_player_one_still_wins_one_tempo_ahead()
    {
        // 4 liberties -> player one places stone #4 on ply 7, player two would on ply 8.
        Assert.Equal((Player.One, 7), PureRace(new RuleConfig { ApPerTurn = 1 }));
    }

    [Fact]
    public void Two_ap_with_one_ap_first_turn_flips_the_pure_race_to_player_two()
    {
        // P1: 1 + 2 stones by ply 3, #4 on ply 5. P2: 2 + 2 stones, #4 on ply 4 -> P2 wins the race.
        Assert.Equal((Player.Two, 4), PureRace(new RuleConfig { ApPerTurn = 2, FirstTurnAp = 1 }));
    }
}

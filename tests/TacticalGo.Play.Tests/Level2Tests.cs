using TacticalGo.Domain;
using TacticalGo.Play;
using Xunit.Abstractions;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

/// <summary>
/// Level 2 (Rogue swap) position checks. These prove properties of the POSITIONS under the real engine and a passive opponent:
/// the intended skill route is legal and wins, a skill-free route also exists (the skill is never mandatory), and the skill is
/// strictly faster. They say nothing about whether a new player understands or enjoys it.
/// </summary>
public class Level2Tests(ITestOutputHelper output)
{
    private static LevelDefinition Level => LevelCatalog.Level2();

    private static GameState Start(int stage) => Level.Stages[stage].CreateState();

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    public void Positions_are_valid_and_the_player_is_a_Rogue_with_the_hero_on_the_board(int stage)
    {
        var state = Start(stage);
        Assert.Equal(7, state.Board.Size);
        Assert.Equal(GameStatus.Ongoing, state.Status);
        Assert.Equal(HeroClass.Rogue, state.HeroClassOf(Player.One));
        Assert.NotNull(state.Board.FindHero(Player.One));
        Assert.True(state.ManaOf(Player.One) >= state.Config.SkillManaCost);
        Assert.Equal(Level.Stages[stage].ActionsPerTurn, state.ApRemaining);
        Assert.NotNull(state.Board.FindCommander(Player.Two));
        Assert.True(BoardRuleEngine.CountLiberties(state.Board, state.Board.FindCommander(Player.One)!.Value) >= 3);
    }

    [Fact]
    public void Stage1_swap_wins_in_one_action_and_is_the_only_one_round_win()
    {
        var state = Start(0);
        var withSkill = LevelSearch.WinningFirstTurnSequences(state, allowSkill: true, wide: true);
        output.WriteLine("stage 1 winning first-turn sequences: " + string.Join(" | ", withSkill));
        Assert.Equal(["Swap (3,2)"], withSkill);

        Assert.Equal(1, LevelSearch.MinRoundsToWin(state, allowSkill: true, maxRounds: 3));
    }

    [Fact]
    public void Stage1_without_the_skill_still_wins_but_needs_more_rounds()
    {
        var state = Start(0);
        var plain = LevelSearch.MinRoundsToWin(state, allowSkill: false, maxRounds: 6);
        output.WriteLine($"stage 1 plain route: {plain} rounds");
        Assert.NotNull(plain);                                 // the skill is never mandatory
        Assert.True(plain > 1);

        // cross-check with a wider candidate set: no faster skill-free route hides outside the narrow search
        Assert.Null(LevelSearch.MinRoundsToWin(state, allowSkill: false, maxRounds: plain.Value - 1, wide: true));
    }

    [Fact]
    public void Stage2_needs_both_the_skill_and_a_stone_for_a_one_round_win_in_either_order()
    {
        var state = Start(1);
        var withSkill = LevelSearch.WinningFirstTurnSequences(state, allowSkill: true, wide: true);
        output.WriteLine("stage 2 winning first-turn sequences: " + string.Join(" | ", withSkill));
        Assert.Equal(2, withSkill.Count);
        Assert.Contains("Swap (3,2) → Place (4,1)", withSkill);
        Assert.Contains("Place (4,1) → Swap (3,2)", withSkill);

        // neither the swap alone nor stones alone win in the first turn
        Assert.Empty(LevelSearch.WinningFirstTurnSequences(state, allowSkill: false, wide: true));
        Assert.Equal(1, LevelSearch.MinRoundsToWin(state, allowSkill: true, maxRounds: 3));
    }

    [Fact]
    public void Stage2_without_the_skill_still_wins_but_needs_more_rounds()
    {
        var state = Start(1);
        var plain = LevelSearch.MinRoundsToWin(state, allowSkill: false, maxRounds: 6);
        output.WriteLine($"stage 2 plain route: {plain} rounds");
        Assert.NotNull(plain);
        Assert.True(plain > 1);
        Assert.Null(LevelSearch.MinRoundsToWin(state, allowSkill: false, maxRounds: plain.Value - 1, wide: true));
    }

    [Fact]
    public void Level2_stages_complete_through_the_session_with_the_intended_routes()
    {
        var play = new PlayController(new RuleConfig());
        var session = new LevelSession(play, LevelCatalog.Level2());

        play.BeginSkill(); play.ClickPoint(new Point(3, 2)); play.Confirm();
        Assert.True(session.StageComplete);
        Assert.Contains("一步就破了陣", session.Learned);
        Assert.False(session.IsLastStage);

        session.NextStage();
        Assert.Equal(1, session.StageIndex);
        Assert.Equal(2, play.State.ApRemaining);
        Assert.False(play.ShowMana);
    }
}

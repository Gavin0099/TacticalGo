using TacticalGo.Domain;
using TacticalGo.Play;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

/// <summary>
/// Level 1 stages are small engine positions. These tests prove the positions are valid, that the intended solution works,
/// that obvious wrong moves do not accidentally complete a stage, and that the scripted opponent only ever passes.
/// They do NOT show that a new player understands anything: that needs people.
/// </summary>
public class LevelTests
{
    private static Point P(int x, int y) => new(x, y);

    private static LevelSession Start(int stage = 0)
    {
        var play = new PlayController(new RuleConfig());
        var session = new LevelSession(play, LevelCatalog.Level1());
        if (stage > 0) session.StartStage(stage);
        return session;
    }

    private static void Place(LevelSession s, int x, int y)
    {
        s.Play.ClickPoint(P(x, y));
        s.Play.Confirm();
    }

    [Fact]
    public void Level1_has_three_stages_with_one_then_two_actions_per_turn()
    {
        var level = LevelCatalog.Level1();
        Assert.Equal([1, 1, 2], level.Stages.Select(s => s.ActionsPerTurn).ToArray());
    }

    [Theory]
    [InlineData(0)]
    [InlineData(1)]
    [InlineData(2)]
    public void Every_stage_starts_valid_and_not_yet_complete(int stage)
    {
        var s = Start(stage);
        var state = s.Play.State;
        Assert.Equal(7, state.Board.Size);
        Assert.Equal(GameStatus.Ongoing, state.Status);
        Assert.Equal(Player.One, state.Current);
        Assert.Equal(s.Stage.ActionsPerTurn, state.ApRemaining);
        Assert.NotNull(state.Board.FindCommander(Player.One));
        Assert.NotNull(state.Board.FindCommander(Player.Two));
        Assert.False(s.StageComplete);
        Assert.False(s.Play.ShowMana);                       // no Mana/skills in level 1
        Assert.True(s.Play.Commander(Player.One).Liberties >= 3);   // the player's own commander is never in danger here
    }

    [Fact]
    public void Stage1_capture_the_surrounded_stone_and_the_board_shows_what_was_taken()
    {
        var s = Start(0);
        var lone = s.Play.State.Board[P(3, 3)]!.Value;
        Assert.Equal(1, BoardRuleEngine.CountLiberties(s.Play.State.Board, P(3, 3)));   // the "red 1" the stage talks about
        Assert.Equal(Player.Two, lone.Owner);

        s.Play.ClickPoint(P(3, 4));
        Assert.False(s.StageComplete);                       // preview alone completes nothing
        Assert.Null(s.Play.State.Board[P(3, 4)]);
        s.Play.Confirm();

        Assert.True(s.StageComplete);
        Assert.Null(s.Play.State.Board[P(3, 3)]);
        Assert.Equal([P(3, 3)], s.Play.LastCaptured.ToArray());
        Assert.Contains("提走", s.Learned);
        Assert.True(s.Play.Locked);
    }

    [Fact]
    public void Stage1_a_wrong_move_does_not_complete_and_the_passive_opponent_just_passes()
    {
        var s = Start(0);
        Place(s, 0, 0);
        Assert.False(s.StageComplete);
        Assert.NotNull(s.Play.State.Board[P(3, 3)]);
        Assert.Equal(Player.One, s.Play.State.Current);       // opponent passed, back to the player
        Assert.Contains("沒有動作", s.Play.Feedback);
        Assert.All(s.Play.Log.Where(l => l.StartsWith("白方")), l => Assert.Contains("結束回合", l));
    }

    [Fact]
    public void Stage2_commander_looks_surrounded_but_shares_spaces_with_its_soldier()
    {
        var s = Start(1);
        var board = s.Play.State.Board;
        var commander = board.FindCommander(Player.Two)!.Value;
        Assert.DoesNotContain(board.Neighbors(commander), n => board.IsEmpty(n));        // no empty point touches the commander...
        Assert.Equal(2, s.Play.Commander(Player.Two).Liberties);                         // ...yet the connected pair still has 2
        Assert.Equal(2, s.Play.Commander(Player.Two).Group.Count);

        Place(s, 4, 2);
        Assert.False(s.StageComplete);
        Assert.True(s.Play.Commander(Player.Two).InDanger);
        Place(s, 3, 3);

        Assert.True(s.StageComplete);
        Assert.Equal(GameStatus.Won, s.Play.State.Status);
        Assert.Contains("相連", s.Learned);
    }

    [Fact]
    public void Stage3_two_actions_in_one_turn_finish_it()
    {
        var s = Start(2);
        Assert.Equal(2, s.Play.State.ApRemaining);

        Place(s, 3, 1);
        Assert.Equal(1, s.Play.State.ApRemaining);            // still the player's turn
        Assert.Equal(Player.One, s.Play.State.Current);
        Assert.Contains("還能行動 1 次", s.Play.Feedback);
        Assert.False(s.StageComplete);

        Place(s, 3, 3);
        Assert.True(s.StageComplete);
        Assert.True(s.LevelComplete);
        Assert.Equal(1, s.Play.State.Ply);                    // finished within the very first turn
        Assert.Contains("一回合連下兩子", s.Learned);
    }

    [Fact]
    public void Stage3_one_action_at_a_time_also_works_and_says_so()
    {
        var s = Start(2);
        Place(s, 3, 1);
        s.Play.EndTurn();                                      // spend only one action this turn
        Assert.Equal(Player.One, s.Play.State.Current);        // passive opponent passed
        Assert.Equal(2, s.Play.State.ApRemaining);
        Place(s, 3, 3);
        Assert.True(s.StageComplete);
        Assert.DoesNotContain("一回合連下兩子", s.Learned);
        Assert.True(s.Play.State.Ply > 1);
    }

    [Fact]
    public void A_completed_stage_locks_placing_but_inspecting_still_works_and_next_stage_resets()
    {
        var s = Start(0);
        Place(s, 3, 4);
        Assert.True(s.StageComplete);

        var fingerprint = s.Play.State.Fingerprint();
        s.Play.ClickPoint(P(0, 0));                            // placing is ignored
        s.Play.Confirm();
        s.Play.EndTurn();
        Assert.Equal(fingerprint, s.Play.State.Fingerprint());

        s.Play.ClickPoint(P(3, 6));                            // inspecting a piece is fine
        Assert.NotNull(s.Play.Inspect);

        s.NextStage();
        Assert.Equal(1, s.StageIndex);
        Assert.False(s.StageComplete);
        Assert.False(s.Play.Locked);
        Assert.False(s.Play.CanUndo);
    }

    [Fact]
    public void Restart_stage_restores_the_starting_position_exactly()
    {
        var s = Start(1);
        var start = s.Play.State.Fingerprint();
        Place(s, 4, 2);
        Assert.NotEqual(start, s.Play.State.Fingerprint());
        s.RestartStage();
        Assert.Equal(start, s.Play.State.Fingerprint());
        Assert.False(s.StageComplete);
    }

    [Fact]
    public void Leaving_the_tutorial_stops_the_session_from_touching_free_play()
    {
        var s = Start(0);
        s.Active = false;
        s.Play.OpponentPolicy = null;
        s.Play.NewGame(new RuleConfig());
        s.Play.ClickPoint(P(2, 2));
        s.Play.Confirm();
        Assert.False(s.Play.Locked);
        Assert.NotNull(s.Play.State.Board[P(2, 2)]);
    }
}

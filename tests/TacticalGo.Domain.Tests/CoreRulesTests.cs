using TacticalGo.Domain;
using static TacticalGo.Domain.Tests.TestKit;

namespace TacticalGo.Domain.Tests;

public class CoreRulesTests
{
    [Fact]
    public void Group_connects_commander_hero_and_soldier_and_shares_liberties()
    {
        var board = BoardText.Parse(Pad(9, "XHx.."));
        var group = BoardRuleEngine.GetGroup(board, P(0, 0));
        Assert.Equal(3, group.Count);
        // corner-ish row 0: libs are (3,0) plus (0,1),(1,1),(2,1)
        Assert.Equal(4, BoardRuleEngine.GetLiberties(board, group).Count);
    }

    [Fact]
    public void Enemy_pieces_do_not_join_a_group()
    {
        var board = BoardText.Parse(Pad(9, "xo"));
        Assert.Single(BoardRuleEngine.GetGroup(board, P(0, 0)));
        Assert.Equal(1, BoardRuleEngine.CountLiberties(board, P(0, 0))); // (0,1) only
    }

    [Fact]
    public void Filling_last_liberty_captures_immediately_and_emits_event()
    {
        var s = Scenario(["xo.", "...", "..."], ap: 2);
        // o at (1,0): neighbors (0,0)=x,(2,0),(1,1). Fill both.
        var after = Play(s, new PlaceSoldier(P(2, 0)));
        Assert.Equal('o', BoardText.ToChar(after.Board[P(1, 0)]));
        var outcome = GameEngine.Apply(after, new PlaceSoldier(P(1, 1)));
        Assert.True(outcome.Success);
        Assert.Null(outcome.State.Board[P(1, 0)]);
        var captured = Assert.Single(outcome.Events.OfType<PiecesCaptured>());
        Assert.Equal(P(1, 0), Assert.Single(captured.Pieces).At);
    }

    [Fact]
    public void Placement_without_liberties_that_captures_is_legal()
    {
        // (0,0) has no liberty of its own, but filling it removes the last liberty of both o stones.
        var s = Scenario([". o x", "o x .", "x"]);
        var outcome = GameEngine.Apply(s, new PlaceSoldier(P(0, 0)));
        Assert.True(outcome.Success, outcome.Validation.Message);
        Assert.Null(outcome.State.Board[P(1, 0)]);
        Assert.Null(outcome.State.Board[P(0, 1)]);
        Assert.NotNull(outcome.State.Board[P(0, 0)]);
    }

    [Fact]
    public void Suicide_is_illegal_and_leaves_state_untouched()
    {
        var s = Scenario([". o", "o"], ap: 2);
        AssertRejected(s, new PlaceSoldier(P(0, 0)), IllegalReason.Suicide);
    }

    [Fact]
    public void Occupied_and_off_board_are_rejected_without_spending_resources()
    {
        var s = Scenario(["x"]);
        AssertRejected(s, new PlaceSoldier(P(0, 0)), IllegalReason.Occupied);
        AssertRejected(s, new PlaceSoldier(P(9, 0)), IllegalReason.OutOfBounds);
        AssertRejected(s, new PlaceSoldier(P(-1, 3)), IllegalReason.OutOfBounds);
    }

    [Fact]
    public void Ko_recapture_is_illegal_until_the_board_changes()
    {
        // Classic ko around (1,1)/(2,1). P1 captures at (2,1); P2 may not immediately retake at (1,1).
        var s = Scenario([". x o", "x o . o", ". x o"]);
        s = Play(s, new PlaceSoldier(P(2, 1)));                    // captures o(1,1)
        Assert.Null(s.Board[P(1, 1)]);
        s = Play(s, new EndTurn());
        Assert.Equal(Player.Two, s.Current);
        AssertRejected(s, new PlaceSoldier(P(1, 1)), IllegalReason.Ko);

        // After a ko threat elsewhere the position differs, so the retake becomes legal.
        s = Play(s, new PlaceSoldier(P(8, 8)), new PlaceSoldier(P(8, 7)));
        s = Play(s, new PlaceSoldier(P(7, 8)), new EndTurn());
        s = Play(s, new PlaceSoldier(P(1, 1)));
        Assert.Null(s.Board[P(2, 1)]);
    }

    [Fact]
    public void Capturing_the_commander_wins_immediately_and_freezes_the_game()
    {
        var s = Scenario(["O x", "."], ap: 2);
        var outcome = GameEngine.Apply(s, new PlaceSoldier(P(0, 1)));
        Assert.True(outcome.Success);
        Assert.Equal(GameStatus.Won, outcome.State.Status);
        Assert.Equal(Player.One, outcome.State.Winner);
        Assert.Contains(outcome.Events, e => e is GameWon { Winner: Player.One });
        AssertRejected(outcome.State, new PlaceSoldier(P(5, 5)), IllegalReason.GameOver);
        AssertRejected(outcome.State, new CastSeal(P(5, 5)), IllegalReason.GameOver);
    }

    [Fact]
    public void Commander_group_with_soldiers_is_captured_together()
    {
        var s = Scenario(["Oox", "x."], ap: 1); // group {O,o} has exactly one liberty: (1,1)
        var outcome = GameEngine.Apply(s, new PlaceSoldier(P(1, 1)));
        Assert.Equal(GameStatus.Won, outcome.State.Status);
        Assert.Null(outcome.State.Board[P(0, 0)]);
        Assert.Null(outcome.State.Board[P(1, 0)]);
    }

    [Fact]
    public void Two_ap_lets_one_turn_fill_two_liberties_but_one_ap_does_not()
    {
        // The S0 balance question in miniature: a commander with exactly two liberties.
        var rows = new[] { "O" };
        var two = Scenario(rows, config: new RuleConfig { ApPerTurn = 2 });
        two = Play(two, new PlaceSoldier(P(1, 0)), new PlaceSoldier(P(0, 1)));
        Assert.Equal(GameStatus.Won, two.Status);

        var one = Scenario(rows, config: new RuleConfig { ApPerTurn = 1 });
        one = Play(one, new PlaceSoldier(P(1, 0)));
        Assert.Equal(GameStatus.Ongoing, one.Status);
        Assert.Equal(Player.Two, one.Current); // defender gets to answer
    }

    [Fact]
    public void Fresh_game_has_symmetric_commanders_and_player_one_to_move()
    {
        var g = GameSetup.NewGame(new RuleConfig(), HeroClass.None, HeroClass.None);
        Assert.Equal(P(4, 7), g.Board.FindCommander(Player.One));
        Assert.Equal(P(4, 1), g.Board.FindCommander(Player.Two));
        Assert.Equal(Player.One, g.Current);
        Assert.Equal(1, g.ApRemaining);        // Draft default: first player's first turn is 1 AP
        Assert.Equal(4, g.ManaOf(Player.One)); // 3 initial + 1 start-of-turn gain (first turn included)
        Assert.Equal(3, g.ManaOf(Player.Two));
    }
}

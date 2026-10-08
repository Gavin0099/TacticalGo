using TacticalGo.Domain;
using TacticalGo.Play;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

/// <summary>
/// Few, targeted tests: they guard the promise that selecting/previewing never touches the official game state
/// and that undo restores everything. Rules themselves are tested in TacticalGo.Domain.Tests.
/// </summary>
public class PlayControllerTests
{
    private static Point P(int x, int y) => new(x, y);

    private static PlayController Fresh(RuleConfig? config = null) => new(config ?? new RuleConfig());

    [Fact]
    public void Selecting_a_point_previews_but_does_not_change_the_official_state()
    {
        var play = Fresh();
        var before = play.State;
        var fingerprint = before.Fingerprint();

        play.ClickPoint(P(0, 8));

        Assert.NotNull(play.Preview);
        Assert.True(play.CanConfirm);
        Assert.Same(before, play.State);
        Assert.Equal(fingerprint, play.State.Fingerprint());
        Assert.NotEqual(fingerprint, play.Preview!.State.Fingerprint()); // the preview is a different object/state
    }

    [Fact]
    public void Suicide_selection_is_reported_with_a_reason_and_confirm_does_nothing()
    {
        // Black stones on (1,0) and (0,1) leave white's corner point (0,0) without any liberty: a suicide for white.
        var play = Fresh(RuleConfig.TwoApBaseline);
        play.ClickPoint(P(1, 0)); play.ClickPoint(P(1, 0));   // black (1,0)
        play.ClickPoint(P(0, 1)); play.ClickPoint(P(0, 1));   // black (0,1) -> turn passes to white
        var fingerprint = play.State.Fingerprint();

        play.ClickPoint(P(0, 0));                              // white tries the dead corner
        Assert.False(play.CanConfirm);
        Assert.True(play.MessageIsError);
        Assert.Contains("(0,0)", play.Message);
        Assert.False(play.SelectionResult!.IsLegal);
        Assert.Equal(IllegalReason.Suicide, play.SelectionResult.Reason);

        play.Confirm();
        Assert.Equal(fingerprint, play.State.Fingerprint());
    }

    [Fact]
    public void Second_tap_on_the_same_point_confirms()
    {
        var play = Fresh();
        play.ClickPoint(P(2, 2));
        Assert.Null(play.State.Board[P(2, 2)]);
        play.ClickPoint(P(2, 2));
        Assert.NotNull(play.State.Board[P(2, 2)]);
        Assert.Null(play.Selected);
    }

    [Fact]
    public void Undo_restores_board_ap_mana_turn_and_log_exactly()
    {
        var play = Fresh(RuleConfig.TwoApBaseline);
        var start = play.State.Fingerprint();
        var startLog = play.Log.Count;

        play.ClickPoint(P(2, 2)); play.Confirm();              // 1 AP spent
        play.ClickPoint(P(3, 2)); play.Confirm();              // turn passes: white gains Mana
        play.EndTurn();                                        // white passes: black gains Mana
        Assert.NotEqual(start, play.State.Fingerprint());

        play.Undo(); play.Undo(); play.Undo();
        Assert.Equal(start, play.State.Fingerprint());
        Assert.Equal(startLog, play.Log.Count);
        Assert.False(play.CanUndo);
    }

    [Fact]
    public void Undo_after_a_capture_brings_the_captured_stone_back()
    {
        var play = Fresh(RuleConfig.TwoApBaseline);
        // black (1,0),(0,1) then white (0,0)? use a simple capture: surround a white stone placed by white.
        play.ClickPoint(P(8, 8)); play.Confirm();               // black
        play.ClickPoint(P(8, 7)); play.Confirm();               // black -> white's turn
        play.ClickPoint(P(0, 0)); play.Confirm();               // white corner stone
        play.ClickPoint(P(5, 5)); play.Confirm();               // white -> black's turn
        play.ClickPoint(P(1, 0)); play.Confirm();
        var beforeCapture = play.State.Fingerprint();
        play.ClickPoint(P(0, 1));
        Assert.Contains("提掉 1 子", play.Message);             // preview announces the capture before it happens
        Assert.NotNull(play.State.Board[P(0, 0)]);              // ...but the official board still has the stone
        play.Confirm();
        Assert.Null(play.State.Board[P(0, 0)]);

        play.Undo();
        Assert.Equal(beforeCapture, play.State.Fingerprint());
        Assert.NotNull(play.State.Board[P(0, 0)]);
    }

    [Fact]
    public void Inspect_reports_group_liberties_without_changing_state()
    {
        var play = Fresh();
        var fingerprint = play.State.Fingerprint();
        play.ClickPoint(P(4, 7));                               // black commander, 4 liberties
        Assert.NotNull(play.Inspect);
        Assert.Equal(4, play.Inspect!.Liberties.Count);
        Assert.Contains("4 氣", play.Message);
        Assert.Equal(fingerprint, play.State.Fingerprint());
    }

    [Fact]
    public void New_game_applies_the_chosen_ap_rule_and_clears_history()
    {
        var play = Fresh();
        Assert.Equal(1, play.State.ApRemaining);                // Draft default
        play.ClickPoint(P(2, 2)); play.Confirm();
        play.NewGame(RuleConfig.TwoApBaseline);
        Assert.Equal(2, play.State.ApRemaining);
        Assert.False(play.CanUndo);
        Assert.Null(play.State.Board[P(2, 2)]);
    }

    [Fact]
    public void Board_tap_pixels_map_to_the_nearest_intersection()
    {
        // 700x700 view, 9x9 board: cell = 700/10 = 70, point (0,0) is drawn at pixel (70,70).
        using var view = new BoardView(Fresh()) { Width = 700, Height = 700 };
        Assert.Equal(P(0, 0), view.HitTest(new System.Drawing.Point(70, 70)));
        Assert.Equal(P(4, 7), view.HitTest(new System.Drawing.Point(350, 560)));
        Assert.Equal(P(4, 7), view.HitTest(new System.Drawing.Point(350 + 30, 560 - 30))); // inside the stone
        Assert.Equal(P(8, 8), view.HitTest(new System.Drawing.Point(630, 630)));
        Assert.Null(view.HitTest(new System.Drawing.Point(5, 5)));       // margin, off the board
        Assert.Null(view.HitTest(new System.Drawing.Point(690, 350)));
    }
}

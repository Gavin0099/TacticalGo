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

    /// <summary>What a player does: tap the point (preview), then press "✔ 放這裡".</summary>
    private static void Place(PlayController play, int x, int y)
    {
        play.ClickPoint(P(x, y));
        play.Confirm();
    }

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
        Place(play, 1, 0);   // black (1,0)
        Place(play, 0, 1);   // black (0,1) -> turn passes to white
        var fingerprint = play.State.Fingerprint();

        play.ClickPoint(P(0, 0));                              // white tries the dead corner
        Assert.False(play.CanConfirm);
        Assert.Equal(FeedbackKind.Error, play.FeedbackKind);
        Assert.Contains("(0,0)", play.Feedback);
        Assert.False(play.SelectionResult!.IsLegal);
        Assert.Equal(IllegalReason.Suicide, play.SelectionResult.Reason);

        play.Confirm();
        Assert.Equal(fingerprint, play.State.Fingerprint());
    }

    [Fact]
    public void Tapping_only_previews_and_only_the_place_here_button_places()
    {
        var play = Fresh();
        var ap = play.State.ApRemaining;
        play.ClickPoint(P(2, 2));
        Assert.Null(play.State.Board[P(2, 2)]);
        Assert.Equal(ap, play.State.ApRemaining);             // previewing spends no action

        play.ClickPoint(P(2, 2));                              // tapping the same point again does NOT place
        Assert.Null(play.State.Board[P(2, 2)]);
        Assert.NotNull(play.Preview);

        play.ClickPoint(P(5, 5));                              // choosing another point just moves the preview
        Assert.Equal(P(5, 5), play.Selected);
        Assert.Null(play.State.Board[P(5, 5)]);

        play.Confirm();                                        // "✔ 放這裡"
        Assert.NotNull(play.State.Board[P(5, 5)]);
        Assert.Null(play.State.Board[P(2, 2)]);
        Assert.Null(play.Selected);
    }

    [Fact]
    public void Cancel_leaves_everything_unchanged()
    {
        var play = Fresh();
        var fingerprint = play.State.Fingerprint();
        play.ClickPoint(P(2, 2));
        play.Cancel();
        Assert.Null(play.Selected);
        Assert.False(play.CanConfirm);
        Assert.Equal(fingerprint, play.State.Fingerprint());
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
        Assert.Contains("提掉 1 子", play.Feedback);             // preview announces the capture before it happens
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
        Assert.Contains("4 個生存空格", play.Feedback);
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

    // ---- UI-1.1: what can I do now / did my click work / commander status ----

    [Fact]
    public void Commander_status_is_computed_from_the_live_engine_state()
    {
        var play = Fresh(RuleConfig.TwoApBaseline);
        Assert.Equal(4, play.Commander(Player.One).Liberties);
        Assert.Equal(4, play.Commander(Player.Two).Liberties);

        // black fills three of white commander (4,1)'s neighbours over two turns
        Place(play, 3, 1);
        Place(play, 5, 1);    // black's 2 AP used -> white
        play.EndTurn();                                        // white passes -> black
        Assert.Equal(2, play.Commander(Player.Two).Liberties);
        Assert.False(play.Commander(Player.Two).InDanger);

        Place(play, 4, 2);
        var enemy = play.Commander(Player.Two);
        Assert.Equal(1, enemy.Liberties);
        Assert.True(enemy.InDanger);
        Assert.Equal([P(4, 0)], enemy.LibertyPoints.ToArray());
    }

    [Fact]
    public void Hint_tells_the_player_what_to_do_in_every_state()
    {
        var play = Fresh();
        Assert.Contains("輪到黑方", play.Hint);
        Assert.Contains("點一個空交叉點", play.Hint);

        play.ClickPoint(P(2, 2));                              // legal selection
        Assert.Contains("✔ 放這裡", play.Hint);
        Assert.Equal("預覽（還沒落子）", play.Callout);

        play.Cancel();
        Assert.Null(play.Callout);
        Assert.Contains("點一個空交叉點", play.Hint);
    }

    [Fact]
    public void Refused_click_is_visibly_explained_with_callout_and_related_stones()
    {
        var play = Fresh(RuleConfig.TwoApBaseline);
        Place(play, 1, 0);
        Place(play, 0, 1);    // white to move
        play.ClickPoint(P(0, 0));                              // suicide for white

        Assert.StartsWith("✕", play.Callout);
        Assert.Contains("自殺", play.Callout);
        Assert.Contains("這個點不能下", play.Hint);
        Assert.Equal(new[] { P(1, 0), P(0, 1) }.OrderBy(p => p.X), play.RelatedPoints.OrderBy(p => p.X));
    }

    [Fact]
    public void Success_feedback_confirms_the_click_and_names_the_next_state()
    {
        var play = Fresh(RuleConfig.TwoApBaseline);
        Place(play, 2, 2);
        Assert.Equal(FeedbackKind.Success, play.FeedbackKind);
        Assert.Contains("已在 (2,2) 落子", play.Feedback);
        Assert.Contains("還能行動 1 次", play.Feedback);

        Place(play, 3, 2);
        Assert.Contains("換白方", play.Feedback);
    }

    [Fact]
    public void Mana_is_hidden_until_someone_has_a_class_and_round_keeps_the_engine_ply()
    {
        var none = Fresh();
        Assert.False(none.ShowMana);
        Assert.True(new PlayController(new RuleConfig(), HeroClass.Mage, HeroClass.None).ShowMana);

        var play = Fresh(RuleConfig.TwoApBaseline);
        Assert.Equal("第 1 輪・黑方回合", play.TurnTitle);
        play.EndTurn();
        Assert.Equal("第 1 輪・白方回合", play.TurnTitle);        // still round 1: black and white each take one ply per round
        Assert.Equal(2, play.State.Ply);
        play.EndTurn();
        Assert.Equal("第 2 輪・黑方回合", play.TurnTitle);
        Assert.Equal(3, play.State.Ply);
    }

    [Fact]
    public void Game_over_shows_a_clear_result_and_blocks_further_input()
    {
        var rows = new[] { "Ox......." }.Concat(Enumerable.Repeat(".........", 8));
        var state = GameSetup.FromDiagram(new RuleConfig(), string.Join(Environment.NewLine, rows));
        var play = new PlayController(state, "測試");
        Place(play, 0, 1);
        Assert.True(play.GameOver);
        Assert.Contains("黑方獲勝", play.ResultText);
        Assert.True(play.Commander(Player.Two).Captured);
        var fingerprint = play.State.Fingerprint();
        play.ClickPoint(P(5, 5));
        Assert.Equal(fingerprint, play.State.Fingerprint());
    }

    [Fact]
    public void Help_pages_are_real_engine_positions_with_the_promised_outcomes()
    {
        var pages = HelpScenarios.Pages(new RuleConfig());
        Assert.Equal(5, pages.Count);

        var win = new PlayController(pages[0].Position!, "示意");        // 1: surround the commander
        win.ClickPoint(pages[0].Click!.Value);
        Assert.NotNull(win.Preview);
        Assert.Contains("包含敵方主將", win.Feedback);

        var libs = new PlayController(pages[1].Position!, "示意");       // 2: liberties of a connected group
        libs.ClickPoint(pages[1].Click!.Value);
        Assert.Equal(2, libs.Inspect!.Group.Count);
        Assert.Equal(5, libs.Inspect.Liberties.Count);

        Assert.Null(pages[2].Position);                                  // 3: AP page has no board

        var two = new PlayController(pages[3].Position!, "示意");        // 4: select first, confirm second
        two.ClickPoint(pages[3].Click!.Value);
        Assert.Equal("預覽（還沒落子）", two.Callout);
        Assert.Null(two.State.Board[pages[3].Click!.Value]);

        var bad = new PlayController(pages[4].Position!, "示意");        // 5: refused placement
        bad.ClickPoint(pages[4].Click!.Value);
        Assert.Equal(IllegalReason.Suicide, bad.SelectionResult!.Reason);
    }
}

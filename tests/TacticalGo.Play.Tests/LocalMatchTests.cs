using TacticalGo.Domain;
using TacticalGo.Play;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

public class LocalMatchTests
{
    [Theory]
    [InlineData(HeroClass.Warrior)]
    [InlineData(HeroClass.Mage)]
    [InlineData(HeroClass.Rogue)]
    public void Approved_opening_two_human_summons_skill_and_capture_replay(HeroClass hero)
    {
        var play = new PlayController(LocalMatch.Config(), hero, HeroClass.Rogue);
        Assert.Equal(7, play.State.Board.Size);
        Assert.Equal(new Point(3, 5), play.State.Board.FindCommander(Player.One));
        Assert.Equal(new Point(3, 1), play.State.Board.FindCommander(Player.Two));
        Assert.Equal(1, play.State.ApRemaining);
        Assert.Null(play.OpponentPolicy);
        var initial = play.State.Fingerprint();
        Summon(play, 3, 4);
        Assert.Equal(Player.Two, play.State.Current); // no tutorial auto-pass
        Assert.Equal(2, play.State.ApRemaining);
        play.Undo(); Assert.Equal(initial, play.State.Fingerprint());
        Summon(play, 3, 4);
        Summon(play, 4, 1); Place(play, 3, 3);
        Assert.Equal(Player.One, play.State.Current);
        Assert.True(play.BeginSkill());
        var beforeSkill = play.State.Fingerprint();
        switch (hero)
        {
            case HeroClass.Warrior: play.ClickPoint(new(2, 4)); play.ClickPoint(new(4, 4)); break;
            case HeroClass.Mage: play.ClickPoint(new(3, 3)); play.ChoosePushDirection(PushDirection.Left); break;
            case HeroClass.Rogue: play.ClickPoint(new(3, 3)); break;
        }
        Assert.True(play.CanConfirm, play.Feedback);
        Assert.Equal(beforeSkill, play.State.Fingerprint());
        play.Confirm();
        Assert.Equal(1, play.State.ApRemaining);
        Assert.True(play.State.SkillUsedThisTurn);
        Assert.False(play.BeginSkill());
        Place(play, 2, 1);
        Assert.Equal(Player.Two, play.State.Current);
        Place(play, 0, 6); Place(play, 0, 5);
        Assert.False(play.State.SkillUsedThisTurn);
        Place(play, 3, 0); Place(play, 3, 2);
        Place(play, 0, 4); Place(play, 0, 3);
        Place(play, 4, 0); Place(play, 4, 2);
        Place(play, 0, 2); Place(play, 0, 1);
        // Commander (3,1) + white hero (4,1) now share only (5,1).
        Assert.Equal(1, play.Commander(Player.Two).Liberties);
        var beforeWin = play.State.Fingerprint();
        Place(play, 5, 1);
        Assert.Equal(GameStatus.Won, play.State.Status);
        Assert.Equal(Player.One, play.State.Winner);
        Assert.Contains("對局已結束", play.ActionBarInfo);
        Assert.Null(play.State.Board.FindCommander(Player.Two));
        Assert.Null(play.State.Board.FindHero(Player.Two));
        var won = play.State.Fingerprint();
        play.ClickPoint(new(6, 6)); play.Confirm(); play.EndTurn();
        Assert.Equal(won, play.State.Fingerprint());
        play.Undo(); Assert.Equal(beforeWin, play.State.Fingerprint());
        Assert.False(play.GameOver);
    }

    internal static void Place(PlayController play, int x, int y)
    {
        play.UsePlaceMode(); play.ClickPoint(new(x, y));
        Assert.True(play.CanConfirm, play.Feedback); play.Confirm();
    }
    internal static void Summon(PlayController play, int x, int y)
    {
        Assert.True(play.BeginSummon(), play.Feedback); play.ClickPoint(new(x, y));
        Assert.True(play.CanConfirm, play.Feedback); play.Confirm();
    }

    [Theory]
    [InlineData(HeroClass.Warrior)]
    [InlineData(HeroClass.Mage)]
    [InlineData(HeroClass.Rogue)]
    public void White_player_can_summon_and_cast_own_class_without_using_black_resources(HeroClass hero)
    {
        var play = new PlayController(LocalMatch.Config(), HeroClass.Rogue, hero);
        Place(play, 0, 0);
        Summon(play, 3, 2); Place(play, 4, 3);
        Place(play, 2, 2); Place(play, 0, 1);
        Assert.Equal(Player.Two, play.State.Current);
        Assert.True(play.BeginSkill());
        var blackMana = play.State.ManaOf(Player.One);
        var whiteMana = play.State.ManaOf(Player.Two);
        switch (hero)
        {
            case HeroClass.Warrior: play.ClickPoint(new(3, 3)); play.ClickPoint(new(4, 2)); break;
            case HeroClass.Mage: play.ClickPoint(new(4, 3)); play.ChoosePushDirection(PushDirection.Down); break;
            case HeroClass.Rogue: play.ClickPoint(new(2, 2)); break;
        }
        Assert.True(play.CanConfirm, play.Feedback);
        play.Confirm();
        Assert.Equal(Player.Two, play.State.Current);
        Assert.Equal(1, play.State.ApRemaining);
        Assert.Equal(whiteMana - 2, play.State.ManaOf(Player.Two));
        Assert.Equal(blackMana, play.State.ManaOf(Player.One));
        if (hero == HeroClass.Mage)
        {
            Assert.Null(play.State.Board[new Point(4, 3)]);
            Assert.Equal(Player.Two, play.State.Board[new Point(4, 4)]!.Value.Owner);
        }
    }

    [Fact]
    public void Tutorial_to_free_clears_script_lock_and_resources_are_visible_then_can_return_to_tutorial()
    {
        var play = new PlayController(new RuleConfig());
        var level = new LevelSession(play, LevelCatalog.Level2());
        Assert.NotNull(play.OpponentPolicy);
        play.Locked = true;
        level.Active = false;
        play.NewGame(LocalMatch.Config(), HeroClass.Mage, HeroClass.Warrior);
        Assert.False(play.Locked);
        Assert.Null(play.OpponentPolicy);
        Assert.True(play.ShowMana);
        Place(play, 0, 0);
        Assert.Equal(Player.Two, play.State.Current);
        Assert.Equal(2, play.State.ApRemaining);
        level.LoadLevel(LevelCatalog.Level2());
        Assert.True(level.Active && play.HideMana);
        Assert.NotNull(play.OpponentPolicy);
        Assert.Equal(HeroClass.Rogue, play.State.HeroClassOf(Player.One));
    }

    [Fact]
    public void Dialog_keeps_7x7_positions_with_each_comparison_and_explicit_seal()
    {
        ClassPickTests.OnSta(() =>
        {
            using var dialog = new NewGameDialog(false);
            var combos = ClassPickTests.All(dialog).OfType<ComboBox>().ToArray();
            var ap = combos.Single(c => c.Items.Count == 3);
            var mage = combos.Single(c => c.Items.Count == 2);
            Assert.Equal(MageSkill.MagicHand, dialog.Config.MageSkill);
            for (var i = 0; i < 3; i++)
            {
                ap.SelectedIndex = i; mage.SelectedIndex = 1;
                Assert.Equal(7, dialog.Config.BoardSize);
                Assert.Equal(new Point(3, 5), dialog.Config.CommanderOneStart);
                Assert.Equal(new Point(3, 1), dialog.Config.CommanderTwoStart);
                Assert.Equal(MageSkill.Seal, dialog.Config.MageSkill);
                Assert.Equal(i == 2 ? 1 : 2, dialog.Config.ApPerTurn);
                Assert.Equal(i == 1 ? 2 : 1, dialog.Config.FirstTurnApResolved);
            }
            // Engine's historical reference defaults are unchanged.
            Assert.Equal(9, new RuleConfig().BoardSize);
        });
    }

    [Fact]
    public void Actual_push_motion_is_presentation_only_undo_cancels_it_and_art_is_embedded()
    {
        ClassPickTests.OnSta(() =>
        {
            foreach (var hero in new[] { HeroClass.Warrior, HeroClass.Mage, HeroClass.Rogue })
            {
                Assert.NotNull(HeroArt.Token(hero)); Assert.NotNull(HeroArt.Portrait(hero));
            }
            Assert.Equal(6, typeof(MainForm).Assembly.GetManifestResourceNames().Count(n => n.StartsWith("TacticalGo.Play.HeroArt.")));
            var play = MagicHandControllerTests.Position();
            using var board = new BoardView(play) { Size = new Size(420, 420) };
            var before = play.State.Fingerprint();
            play.BeginSkill(); play.ClickPoint(new(2, 1)); play.ChoosePushDirection(PushDirection.Up);
            Assert.False(board.IsAnimating);
            play.Confirm();
            Assert.True(board.IsAnimating);
            var after = play.State.Fingerprint();
            using var bitmap = new Bitmap(420, 420);
            board.DrawToBitmap(bitmap, new Rectangle(0, 0, 420, 420));
            Assert.Equal(after, play.State.Fingerprint());
            play.Undo();
            Assert.False(board.IsAnimating);
            Assert.Equal(before, play.State.Fingerprint());
        });
    }
}

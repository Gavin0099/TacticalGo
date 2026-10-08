using TacticalGo.Domain;
using TacticalGo.Play;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

public class BastionControllerTests
{
    internal static PlayController Position() => new(GameSetup.FromDiagram(
        new RuleConfig { BoardSize = 5, FirstTurnAp = null }, "....O\n.....\n..H..\n.....\nX....", HeroClass.Warrior, HeroClass.Rogue, manaOne: 4, ap: 2));

    [Fact]
    public void Two_selections_preview_without_spending_then_confirm_both_atomically_and_undo()
    {
        var play = Position();
        var before = play.State.Fingerprint();
        Assert.True(play.BeginSkill());
        Assert.Contains("築壘", play.Skill.Text);
        play.ClickPoint(new Point(1, 2));
        Assert.False(play.CanConfirm);
        Assert.Contains("第二", play.Callout);
        Assert.Equal(before, play.State.Fingerprint());
        play.Confirm();
        Assert.Equal(before, play.State.Fingerprint());
        play.ClickPoint(new Point(2, 1));
        Assert.True(play.CanConfirm);
        Assert.Equal(before, play.State.Fingerprint());
        Assert.Equal(2, play.Preview!.Events.OfType<PiecePlaced>().Count());
        play.Confirm();
        Assert.Equal(1, play.State.ApRemaining);
        Assert.Equal(2, play.State.ManaOf(Player.One));
        Assert.Equal(new Piece(Player.One, PieceKind.Soldier), play.State.Board[new Point(1, 2)]);
        Assert.Equal(new Piece(Player.One, PieceKind.Soldier), play.State.Board[new Point(2, 1)]);
        Assert.True(play.State.SkillUsedThisTurn);
        Assert.Null(play.BastionFirst);
        Assert.False(play.BeginSkill());
        play.Undo();
        Assert.Equal(before, play.State.Fingerprint());
        Assert.True(play.BeginSkill());
    }

    [Fact]
    public void Duplicate_or_distant_second_target_is_refused_and_can_be_reselected()
    {
        var play = Position();
        var before = play.State.Fingerprint();
        play.BeginSkill(); play.ClickPoint(new Point(1, 2));
        foreach (var p in new[] { new Point(1, 2), new Point(0, 0), new Point(2, 2) })
        {
            play.ClickPoint(p);
            Assert.False(play.CanConfirm);
            play.Confirm();
            Assert.Equal(before, play.State.Fingerprint());
        }
        play.ClickPoint(new Point(2, 1));
        Assert.True(play.CanConfirm);
        play.Cancel();
        Assert.Null(play.BastionFirst);
        Assert.False(play.CanConfirm);
        Assert.Equal(before, play.State.Fingerprint());
    }

    [Fact]
    public void Partial_and_complete_bastion_previews_paint_and_the_real_button_confirms()
    {
        ClassPickTests.OnSta(() =>
        {
            var play = Position();
            using var form = new MainForm(play) { Location = new System.Drawing.Point(-3000, 40), StartPosition = FormStartPosition.Manual, ShowInTaskbar = false };
            form.Show(); Application.DoEvents();
            var skill = ClassPickTests.All(form).OfType<Button>().Single(b => b.Text == "技能：築壘");
            skill.PerformClick();
            foreach (var p in new[] { new Point(1, 2), new Point(2, 1) })
            {
                play.ClickPoint(p);
                using var bmp = new Bitmap(form.Width, form.Height);
                form.DrawToBitmap(bmp, new Rectangle(0, 0, form.Width, form.Height));
            }
            var confirm = ClassPickTests.All(form).OfType<Button>().Single(b => b.Text == "✔ 確定築壘");
            Assert.True(confirm.Visible && confirm.Enabled);
            confirm.PerformClick();
            Assert.Equal(2, play.State.Board.AllPoints().Count(p => play.State.Board[p] is { Owner: Player.One, Kind: PieceKind.Soldier }));
        });
    }
}

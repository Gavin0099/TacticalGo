using TacticalGo.Domain;
using TacticalGo.Play;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

public class MagicHandControllerTests
{
    internal static PlayController Position(string diagram = "....O\n..o..\n..H..\n.....\nX....", MageSkill skill = MageSkill.MagicHand) => new(
        GameSetup.FromDiagram(new RuleConfig { BoardSize = 5, FirstTurnAp = null, MageSkill = skill }, diagram, HeroClass.Mage, HeroClass.Rogue, manaOne: 4, ap: 2));

    [Theory]
    [InlineData('x', Player.One)]
    [InlineData('o', Player.Two)]
    public void Target_then_direction_then_confirmation_preserve_ownership_and_resources(char soldier, Player owner)
    {
        var play = Position($"....O\n..{soldier}..\n..H..\n.....\nX....");
        var before = play.State.Fingerprint();
        Assert.True(play.BeginSkill());
        play.ClickPoint(new Point(2, 1));
        Assert.False(play.CanConfirm);
        Assert.Contains("方向", play.Callout);
        Assert.Equal(before, play.State.Fingerprint());
        play.ChoosePushDirection(PushDirection.Up);
        Assert.Equal(before, play.State.Fingerprint());
        Assert.Equal([new Point(2, 1), new Point(2, 0)], play.SkillPreviewPoints.ToArray());
        Assert.Equal(owner, play.Preview!.State.Board[new Point(2, 0)]!.Value.Owner);
        Assert.Null(play.Preview.State.Board[new Point(2, 1)]);
        Assert.True(play.CanConfirm);
        play.Confirm();
        Assert.Equal(2, play.State.ManaOf(Player.One));
        Assert.Equal(1, play.State.ApRemaining);
        Assert.Equal(owner, play.State.Board[new Point(2, 0)]!.Value.Owner);
        Assert.True(play.State.SkillUsedThisTurn);
        Assert.Contains(play.Log, line => line.Contains("魔法之手") && line.Contains("(2,1) → (2,0)"));
        play.Undo();
        Assert.Equal(before, play.State.Fingerprint());
        Assert.Null(play.SelectedDirection);
    }

    [Fact]
    public void Invalid_targets_and_blocked_directions_cannot_spend_or_leave_stale_preview()
    {
        var play = Position("x...O\n..ox.\n..H..\n.....\nX....");
        var before = play.State.Fingerprint();
        play.BeginSkill();
        foreach (var target in new[] { new Point(4, 0), new Point(2, 2), new Point(0, 0), new Point(0, 2) })
        {
            play.ClickPoint(target); play.ChoosePushDirection(PushDirection.Up);
            Assert.False(play.CanConfirm);
            play.Confirm();
            Assert.Equal(before, play.State.Fingerprint());
        }
        play.ClickPoint(new Point(2, 1));
        Assert.False(play.PushDirections.Single(d => d.Direction == PushDirection.Right).Result.IsLegal);
        play.ChoosePushDirection(PushDirection.Right);
        Assert.Equal(IllegalReason.Occupied, play.SelectionResult!.Reason);
        Assert.False(play.CanConfirm);
        play.ChoosePushDirection(PushDirection.Up);
        Assert.True(play.CanConfirm);
        play.ClickPoint(new Point(3, 1)); // selecting another target clears the old direction
        Assert.False(play.CanConfirm);
        Assert.Null(play.SelectedDirection);
        Assert.Equal(before, play.State.Fingerprint());
    }

    [Fact]
    public void Friendly_suicide_and_repeated_history_are_refused_without_partial_changes()
    {
        var suicide = Position("....O\n.H...\n.....\noo...\nX....");
        var before = suicide.State.Fingerprint();
        suicide.BeginSkill(); suicide.ClickPoint(new Point(1, 3)); suicide.ChoosePushDirection(PushDirection.Down);
        Assert.Equal(IllegalReason.Suicide, suicide.SelectionResult!.Reason);
        suicide.Confirm();
        Assert.Equal(before, suicide.State.Fingerprint());

        var ko = Position();
        ko.BeginSkill(); ko.ClickPoint(new Point(2, 1)); ko.ChoosePushDirection(PushDirection.Up); ko.Confirm();
        ko.EndTurn(); ko.EndTurn();
        var koBefore = ko.State.Fingerprint();
        var log = ko.Log.ToArray();
        ko.BeginSkill(); ko.ClickPoint(new Point(2, 0)); ko.ChoosePushDirection(PushDirection.Down);
        Assert.Equal(IllegalReason.Ko, ko.SelectionResult!.Reason);
        Assert.False(ko.CanConfirm);
        ko.Confirm();
        Assert.Equal(koBefore, ko.State.Fingerprint());
        Assert.Equal(log, ko.Log);
    }

    [Fact]
    public void Push_then_place_uses_real_domain_and_can_capture_commander_on_second_action()
    {
        // Custom 5x5 mechanism regression; this test is not a normal-opening/balance claim.
        var play = Position("x....\nOoo..\nx....\n.H...\n.x..X");
        play.BeginSkill(); play.ClickPoint(new Point(1, 1)); play.ChoosePushDirection(PushDirection.Down);
        Assert.True(play.CanConfirm);
        play.Confirm();
        Assert.False(play.GameOver);
        Assert.Equal(1, play.State.ApRemaining);
        play.ClickPoint(new Point(1, 1));
        Assert.Equal(GameStatus.Won, play.Preview!.State.Status);
        Assert.False(play.GameOver);
        play.Confirm();
        Assert.Equal(Player.One, play.State.Winner);
        play.Undo();
        Assert.False(play.GameOver);
        Assert.NotNull(play.State.Board[new Point(0, 1)]);
    }

    [Fact]
    public void Explicit_seal_baseline_remains_operable_without_push_directions()
    {
        var play = Position(skill: MageSkill.Seal);
        play.BeginSkill(); play.ClickPoint(new Point(1, 2));
        Assert.True(play.CanConfirm);
        Assert.Equal("✔ 確定封印", play.ConfirmLabel);
        Assert.Empty(play.PushDirections);
        play.Confirm();
        Assert.Contains(play.State.Seals, s => s.At == new Point(1, 2));
        Assert.Equal(2, play.State.ManaOf(Player.One));
    }

    [Fact]
    public void Real_direction_and_confirm_buttons_preview_push_and_render_without_changing_official_state()
    {
        ClassPickTests.OnSta(() =>
        {
            var play = Position();
            using var form = new MainForm(play) { Location = new System.Drawing.Point(-3000, 40), StartPosition = FormStartPosition.Manual, ShowInTaskbar = false };
            form.Show(); Application.DoEvents();
            ClassPickTests.All(form).OfType<Button>().Single(b => b.Text == "技能：魔法之手").PerformClick();
            play.ClickPoint(new Point(2, 1));
            var before = play.State.Fingerprint();
            var up = ClassPickTests.All(form).OfType<Button>().Single(b => b.Text == "↑ 上");
            Assert.True(up.Visible && up.Enabled);
            up.PerformClick();
            Assert.Equal(before, play.State.Fingerprint());
            using var bmp = new Bitmap(form.Width, form.Height);
            form.DrawToBitmap(bmp, new Rectangle(0, 0, form.Width, form.Height));
            var confirm = ClassPickTests.All(form).OfType<Button>().Single(b => b.Text == "✔ 確定魔法之手");
            Assert.True(confirm.Enabled);
            confirm.PerformClick();
            Assert.Null(play.State.Board[new Point(2, 1)]);
            Assert.NotNull(play.State.Board[new Point(2, 0)]);
        });
    }
}

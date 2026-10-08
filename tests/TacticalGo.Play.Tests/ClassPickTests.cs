using System.Runtime.ExceptionServices;
using TacticalGo.Domain;
using TacticalGo.Play;

namespace TacticalGo.Play.Tests;

public class ClassPickTests
{
    internal static void OnSta(Action body)
    {
        Exception? error = null;
        var thread = new Thread(() => { try { body(); } catch (Exception ex) { error = ex; } });
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start(); thread.Join();
        if (error is not null) ExceptionDispatchInfo.Capture(error).Throw();
    }

    internal static IEnumerable<Control> All(Control root) => root.Controls.Cast<Control>().SelectMany(c => new[] { c }.Concat(All(c)));

    [Fact]
    public void Public_choices_are_sequential_can_match_and_costs_come_from_config()
    {
        OnSta(() =>
        {
            using var dialog = new ClassPickDialog(new RuleConfig { SummonCostMage = 5, SkillManaCost = 4 });
            Assert.Contains(All(dialog).OfType<Button>(), b => b.Text.Contains("召喚 5 Mana") && b.Text.Contains("4 Mana"));
            dialog.Choose(HeroClass.Mage);
            Assert.Equal(HeroClass.Mage, dialog.ClassOne);
            Assert.Equal(HeroClass.None, dialog.ClassTwo);
            Assert.NotEqual(DialogResult.OK, dialog.DialogResult);
            Assert.Contains(All(dialog).OfType<Label>(), l => l.Text.Contains("黑方已選：法師"));
            dialog.Choose(HeroClass.Mage);
            Assert.Equal(HeroClass.Mage, dialog.ClassTwo);
            Assert.Equal(DialogResult.OK, dialog.DialogResult);
        });
    }

    [Fact]
    public void Summon_button_and_confirmation_are_visible_and_drive_actual_controller()
    {
        OnSta(() =>
        {
            var play = new PlayController(new RuleConfig { FirstTurnAp = null }, HeroClass.Rogue, HeroClass.Mage);
            using var form = new MainForm(play) { Location = new System.Drawing.Point(-3000, 40), StartPosition = FormStartPosition.Manual, ShowInTaskbar = false };
            form.Show(); Application.DoEvents();
            var summon = All(form).OfType<Button>().Single(b => b.Text == "召喚英雄");
            Assert.True(summon.Visible && summon.Enabled);
            summon.PerformClick();
            Assert.Equal(PlayMode.Summon, play.Mode);
            play.ClickPoint(new TacticalGo.Domain.Point(3, 7));
            var confirm = All(form).OfType<Button>().Single(b => b.Text == "✔ 確定召喚");
            Assert.True(confirm.Enabled);
            Assert.True(form.ClientRectangle.Contains(form.RectangleToClient(confirm.RectangleToScreen(confirm.ClientRectangle))));
            confirm.PerformClick();
            Assert.NotNull(play.State.Board.FindHero(Player.One));
            Assert.False(summon.Enabled);
            using var bmp = new Bitmap(form.Width, form.Height);
            form.DrawToBitmap(bmp, new Rectangle(0, 0, form.Width, form.Height));
        });
    }
}

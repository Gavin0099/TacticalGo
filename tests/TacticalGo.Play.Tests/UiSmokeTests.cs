using System.Reflection;
using System.Runtime.ExceptionServices;
using TacticalGo.Domain;
using TacticalGo.Play;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

/// <summary>
/// Smoke tests that build the REAL window (off-screen, on an STA thread) and drive it through the controller. They catch
/// layout and paint regressions that the pure-logic tests cannot: a clipped action bar, a paint exception in a new mode,
/// buttons that vanish. They do not judge whether the screen is clear to a new player.
/// </summary>
public class UiSmokeTests
{
    private static Point P(int x, int y) => new(x, y);

    private static void OnSta(Action body)
    {
        Exception? error = null;
        var thread = new Thread(() =>
        {
            try { body(); }
            catch (Exception e) { error = e; }
        });
        thread.SetApartmentState(ApartmentState.STA);
        thread.Start();
        thread.Join();
        if (error is not null) ExceptionDispatchInfo.Capture(error).Throw();
    }

    private static (MainForm Form, PlayController Play, LevelSession Session) Open(LevelDefinition level)
    {
        var play = new PlayController(new RuleConfig());
        var session = new LevelSession(play, level);          // before the form, as Program does
        var form = new MainForm(play, session)
        {
            StartPosition = FormStartPosition.Manual,
            Location = new System.Drawing.Point(-3000, 40),   // off-screen: tests must not flash windows at the Owner
            ShowInTaskbar = false,
        };
        form.Show();
        Application.DoEvents();
        form.PerformLayout();
        return (form, play, session);
    }

    private static IEnumerable<Control> All(Control root)
    {
        foreach (Control child in root.Controls)
        {
            yield return child;
            foreach (var nested in All(child)) yield return nested;
        }
    }

    private static T Find<T>(Control root, Func<T, bool> where) where T : Control =>
        All(root).OfType<T>().First(where);

    private static Button ConfirmButton(Form form) => Find<Button>(form, b => b.Text.StartsWith("✔"));

    private static bool InsideClientArea(Form form, Control c)
    {
        var onForm = form.RectangleToClient(c.RectangleToScreen(c.ClientRectangle));
        return form.ClientRectangle.Contains(onForm);
    }

    private static void AssertRendersSomething(Form form)
    {
        using var bmp = new Bitmap(form.Width, form.Height);
        form.DrawToBitmap(bmp, new Rectangle(0, 0, form.Width, form.Height));
        var colours = new HashSet<int>();
        for (var x = 0; x < bmp.Width; x += 23)
            for (var y = 0; y < bmp.Height; y += 23)
                colours.Add(bmp.GetPixel(x, y).ToArgb());
        Assert.True(colours.Count > 6, "the window painted (almost) nothing");
    }

    [Fact]
    public void Action_bar_stays_fully_inside_the_window_in_every_mode_of_level_two()
    {
        OnSta(() =>
        {
            var (form, play, session) = Open(LevelCatalog.Level2());
            try
            {
                void Check(string where)
                {
                    form.PerformLayout();
                    Application.DoEvents();
                    var confirm = ConfirmButton(form);
                    Assert.True(InsideClientArea(form, confirm), $"{where}: confirm button is clipped");
                    Assert.True(InsideClientArea(form, Find<Button>(form, b => b.Text == "取消")), $"{where}: cancel button is clipped");
                    AssertRendersSomething(form);
                }

                Check("place mode");
                play.BeginSkill(); Check("skill mode");
                play.ClickPoint(P(3, 2)); Check("swap previewed");
                play.ClickPoint(P(0, 0)); Check("illegal target");
                play.ClickPoint(P(3, 2)); play.Confirm(); Check("stage complete");
                session.NextStage(); Check("next stage");
            }
            finally { form.Dispose(); }
        });
    }

    [Fact]
    public void Place_and_skill_buttons_do_not_vanish_when_a_stage_is_won()
    {
        OnSta(() =>
        {
            var (form, play, session) = Open(LevelCatalog.Level2());
            try
            {
                var place = Find<Button>(form, b => b.Text == "放士兵");
                var skill = Find<Button>(form, b => b.Text.StartsWith("技能"));
                Assert.True(place.Visible && skill.Visible);
                var top = ConfirmButton(form).Top;

                play.BeginSkill(); play.ClickPoint(P(3, 2)); play.Confirm();
                Assert.True(session.StageComplete);
                form.PerformLayout(); Application.DoEvents();

                Assert.True(place.Visible && skill.Visible, "the mode row collapsed at stage completion");
                Assert.False(place.Enabled);                   // locked, but still shown
                Assert.Equal(top, ConfirmButton(form).Top);    // nothing jumped
            }
            finally { form.Dispose(); }
        });
    }

    [Fact]
    public void Cancel_leaves_skill_mode_even_with_no_target_selected()
    {
        OnSta(() =>
        {
            var (form, play, _) = Open(LevelCatalog.Level2());
            try
            {
                play.BeginSkill();
                var cancel = Find<Button>(form, b => b.Text == "取消");
                Assert.True(cancel.Enabled, "cancel is greyed out in skill mode, so the skill could only be left with Esc");
                cancel.PerformClick();
                Assert.Equal(PlayMode.Place, play.Mode);
            }
            finally { form.Dispose(); }
        });
    }

    [Fact]
    public void Enter_confirms_and_is_suppressed_so_a_focused_button_cannot_also_fire()
    {
        OnSta(() =>
        {
            var (form, play, session) = Open(LevelCatalog.Level2());
            try
            {
                play.BeginSkill();
                play.ClickPoint(P(3, 2));
                var onKey = typeof(MainForm).GetMethod("OnKey", BindingFlags.Instance | BindingFlags.NonPublic)!;
                var args = new KeyEventArgs(Keys.Enter);
                onKey.Invoke(form, [form, args]);

                Assert.True(args.Handled);
                Assert.True(args.SuppressKeyPress);
                Assert.True(session.StageComplete);            // the swap was confirmed exactly once
            }
            finally { form.Dispose(); }
        });
    }

    [Fact]
    public void New_game_dialog_offers_one_radio_per_catalog_level_plus_free_play()
    {
        OnSta(() =>
        {
            using var dialog = new NewGameDialog(tutorialAvailable: true);
            var radios = All(dialog).OfType<RadioButton>().ToList();
            Assert.Equal(LevelCatalog.Levels.Count + 1, radios.Count);
            Assert.Equal(1, dialog.TutorialLevel);             // level 1 is the default choice
            foreach (var level in LevelCatalog.Levels)
                Assert.Contains(radios, r => r.Text.Contains($"第 {level.Number} 關"));

            using var noTutorial = new NewGameDialog(tutorialAvailable: false);
            Assert.Null(noTutorial.TutorialLevel);             // free play only
        });
    }

    [Fact]
    public void The_skill_status_is_computed_once_per_state()
    {
        var play = new PlayController(new RuleConfig());
        var session = new LevelSession(play, LevelCatalog.Level2());
        Assert.NotNull(session);
        var first = play.Skill;
        Assert.Same(first, play.Skill);                        // cached for the same state
        play.BeginSkill();
        play.ClickPoint(P(3, 2));
        play.Confirm();
        Assert.NotSame(first, play.Skill);                     // a new state gets a fresh evaluation
    }
}

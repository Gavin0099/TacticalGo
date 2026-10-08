using TacticalGo.Domain;
using TacticalGo.Play;

namespace TacticalGo.Play.Tests;

public class GameplayVisualTests
{
    [Fact]
    public void Empty_display_and_small_display_dimensions_never_produce_negative_form_sizes()
    {
        var unavailable = MainForm.WindowSizes(Rectangle.Empty);
        Assert.Equal(new Size(1140, 710), unavailable.Client);
        Assert.Equal(new Size(900, 700), unavailable.Minimum);
        var small = MainForm.WindowSizes(new Rectangle(0, 0, 800, 600));
        Assert.Equal(new Size(760, 510), small.Client);
        Assert.True(small.Minimum.Width <= small.Client.Width && small.Minimum.Height <= small.Client.Height);
    }

    [Theory]
    [InlineData(900, 700)]
    [InlineData(1140, 760)]
    public void Full_game_action_controls_stay_inside_viewport_with_actual_art_and_skill_previews(int width, int height)
    {
        ClassPickTests.OnSta(() =>
        {
            foreach (var hero in new[] { HeroClass.Warrior, HeroClass.Mage, HeroClass.Rogue })
            {
                var play = new PlayController(LocalMatch.Config(), hero, HeroClass.Rogue);
                using var form = new MainForm(play) { ClientSize = new Size(width, height), Location = new System.Drawing.Point(-3000, 40), StartPosition = FormStartPosition.Manual, ShowInTaskbar = false };
                form.Show(); Application.DoEvents();
                LocalMatchTests.Summon(play, 3, 4);
                LocalMatchTests.Summon(play, 4, 1); LocalMatchTests.Place(play, 3, 3);
                play.BeginSkill();
                switch (hero)
                {
                    case HeroClass.Warrior: play.ClickPoint(new(2, 4)); play.ClickPoint(new(4, 4)); break;
                    case HeroClass.Mage: play.ClickPoint(new(3, 3)); play.ChoosePushDirection(PushDirection.Left); break;
                    case HeroClass.Rogue: play.ClickPoint(new(3, 3)); break;
                }
                Assert.True(play.CanConfirm, play.Feedback);
                Application.DoEvents(); form.PerformLayout(); Application.DoEvents();
                Assert.Equal(2, ClassPickTests.All(form).OfType<PictureBox>().Count(p => p.Visible && p.Image is not null));
                Assert.Contains(ClassPickTests.All(form).OfType<Label>(), l => l.Visible && l.Text.Contains("黑方：") && l.Text.Contains("白方："));
                foreach (var button in ClassPickTests.All(form).OfType<Button>().Where(b => b.Visible))
                {
                    var bounds = form.RectangleToClient(button.RectangleToScreen(button.ClientRectangle));
                    Assert.True(form.ClientRectangle.Contains(bounds), $"{hero}: {button.Text} {bounds} outside {form.ClientRectangle}");
                    var parentBounds = button.Parent!.RectangleToClient(button.RectangleToScreen(button.ClientRectangle));
                    Assert.True(button.Parent.ClientRectangle.Contains(parentBounds), $"{hero}: {button.Text} clipped in parent {parentBounds}");
                }
                var board = ClassPickTests.All(form).OfType<BoardView>().Single();
                Assert.True(form.ClientRectangle.Contains(form.RectangleToClient(board.RectangleToScreen(board.ClientRectangle))));
                Save(form, $"{hero}-{width}x{height}-preview.png");
                var before = play.State.Fingerprint();
                play.Cancel(); Assert.Equal(before, play.State.Fingerprint());
            }
            using var choices = new ClassPickDialog(LocalMatch.Config()) { Location = new System.Drawing.Point(-3000, 40), StartPosition = FormStartPosition.Manual, ShowInTaskbar = false };
            choices.Show(); Application.DoEvents();
            Assert.Equal(3, ClassPickTests.All(choices).OfType<Button>().Count(b => b.Image is not null));
            Save(choices, "class-cards.png");
            choices.Choose(HeroClass.Mage); Application.DoEvents();
            Assert.Contains(ClassPickTests.All(choices).OfType<Label>(), l => l.Visible && l.Text == "黑方已選：法師");
            Save(choices, "class-cards-white-choice.png");
        });
    }

    private static void Save(Form form, string name)
    {
        using var bitmap = new Bitmap(form.Width, form.Height);
        form.DrawToBitmap(bitmap, new Rectangle(0, 0, form.Width, form.Height));
        if (Environment.GetEnvironmentVariable("TACTICALGO_QA_DIR") is { Length: > 0 } directory)
        {
            Directory.CreateDirectory(directory);
            bitmap.Save(Path.Combine(directory, name), System.Drawing.Imaging.ImageFormat.Png);
        }
    }
}

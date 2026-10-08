using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

static class Program
{
    /// <summary>
    /// Normal start: opens the game window.
    /// Verification aid: <c>--snapshot out.png [script]</c> renders the window after replaying a tiny script and exits.
    /// Script tokens separated by ';': <c>p3,4</c> select then press "放這裡", <c>s3,4</c> select only, <c>i4,7</c> inspect,
    /// <c>e</c> end turn, <c>u</c> undo, <c>n</c> next stage, <c>N</c> next level, <c>r</c> restart stage, <c>c</c> cancel,
    /// <c>k</c> skill mode, <c>m</c> place mode, <c>h</c> summon mode, <c>U/R/D/L</c> push direction, <c>v</c> confirm.
    /// <c>--level 2</c> starts at level 2; <c>--free</c> opens 7x7 public class choices, <c>--classes Mage,Rogue</c> skips choices for replay.
    /// </summary>
    [STAThread]
    static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();
        var play = new PlayController(new RuleConfig());
        // The tutorial is the default start for new players; "--free" opens plain free play.
        var levelArg = Array.IndexOf(args, "--level");
        var startLevel = levelArg >= 0 && levelArg + 1 < args.Length && int.TryParse(args[levelArg + 1], out var n)
            ? LevelCatalog.Levels.FirstOrDefault(l => l.Number == n) ?? LevelCatalog.Level1()
            : LevelCatalog.Level1();
        var level = new LevelSession(play, startLevel);
        if (Array.IndexOf(args, "--free") >= 0)
        {
            var config = LocalMatch.Config(mageSkill: Array.IndexOf(args, "--seal") >= 0 ? MageSkill.Seal : MageSkill.MagicHand);
            HeroClass one, two;
            var classesAt = Array.IndexOf(args, "--classes");
            if (classesAt >= 0 && classesAt + 1 < args.Length)
            {
                var choices = args[classesAt + 1].Split(',');
                if (choices.Length != 2 || !Enum.TryParse(choices[0], true, out one) || !Enum.TryParse(choices[1], true, out two)
                    || one is not (HeroClass.Warrior or HeroClass.Mage or HeroClass.Rogue) || two is not (HeroClass.Warrior or HeroClass.Mage or HeroClass.Rogue))
                { MessageBox.Show("--classes 需要兩個職業，例如 Warrior,Mage"); return; }
            }
            else
            {
                using var classes = new ClassPickDialog(config);
                if (classes.ShowDialog() != DialogResult.OK) return;
                one = classes.ClassOne; two = classes.ClassTwo;
            }
            level.Active = false;
            play.NewGame(config, one, two);
        }
        var form = new MainForm(play, level);

        var helpAt = Array.IndexOf(args, "--help-page");
        if (helpAt >= 0 && helpAt + 2 < args.Length)
        {
            using var help = new HelpForm(new RuleConfig());
            help.ShowPage(int.Parse(args[helpAt + 1]));
            help.StartPosition = FormStartPosition.Manual;
            help.Location = new System.Drawing.Point(40, 40);
            help.Show();
            Application.DoEvents();
            using var bmp = new Bitmap(help.ClientSize.Width, help.ClientSize.Height);
            help.DrawToBitmap(bmp, new Rectangle(System.Drawing.Point.Empty, help.ClientSize));
            bmp.Save(args[helpAt + 2], System.Drawing.Imaging.ImageFormat.Png);
            return;
        }

        var snap = Array.IndexOf(args, "--snapshot");
        if (snap >= 0 && snap + 1 < args.Length)
        {
            Replay(play, level, snap + 2 < args.Length ? args[snap + 2] : "");
            form.StartPosition = FormStartPosition.Manual;
            form.Location = new System.Drawing.Point(-3000, 40);
            form.ShowInTaskbar = false;
            form.Show();
            Application.DoEvents();
            form.PerformLayout();                                      // make sure a size change made before Show is laid out
            Application.DoEvents();
            using var bmp = new Bitmap(form.Width, form.Height);       // whole window, including the title bar
            form.DrawToBitmap(bmp, new Rectangle(0, 0, form.Width, form.Height));
            bmp.Save(args[snap + 1], System.Drawing.Imaging.ImageFormat.Png);
            return;
        }

        Application.Run(form);
    }

    private static void Replay(PlayController play, LevelSession? level, string script)
    {
        foreach (var token in script.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries))
        {
            switch (token[0])
            {
                case 'e': play.EndTurn(); break;
                case 'u': play.Undo(); break;
                case 'n': level?.NextStage(); break;
                case 'N': level?.NextLevel(); break;
                case 'k': play.BeginSkill(); break;
                case 'm': play.UsePlaceMode(); break;     // choose "放士兵"
                case 'h': play.BeginSummon(); break;
                case 'U': play.ChoosePushDirection(PushDirection.Up); break;
                case 'R': play.ChoosePushDirection(PushDirection.Right); break;
                case 'D': play.ChoosePushDirection(PushDirection.Down); break;
                case 'L': play.ChoosePushDirection(PushDirection.Left); break;
                case 'v': play.Confirm(); break;
                case 'r': level?.RestartStage(); break;
                case 'c': play.Cancel(); break;
                case 'p':
                case 's':
                case 'i':
                    var xy = token[1..].Split(',').Select(int.Parse).ToArray();
                    play.ClickPoint(new Point(xy[0], xy[1]));
                    if (token[0] == 'p') play.Confirm();     // "✔ 放這裡"
                    break;
            }
        }
    }
}

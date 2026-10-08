using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

static class Program
{
    /// <summary>
    /// Normal start: opens the game window.
    /// Verification aid: <c>--snapshot out.png [script]</c> renders the window after replaying a tiny script and exits.
    /// Script tokens separated by ';': <c>p3,4</c> select then press "放這裡", <c>s3,4</c> select only, <c>i4,7</c> inspect,
    /// <c>e</c> end turn, <c>u</c> undo, <c>n</c> next stage, <c>r</c> restart stage, <c>c</c> cancel.
    /// </summary>
    [STAThread]
    static void Main(string[] args)
    {
        ApplicationConfiguration.Initialize();
        var play = new PlayController(new RuleConfig());
        // The tutorial is the default start for new players; "--free" opens plain free play.
        var level = Array.IndexOf(args, "--free") >= 0 ? null : new LevelSession(play, LevelCatalog.Level1());
        if (level is null) play.OpponentPolicy = null;
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
            form.Location = new System.Drawing.Point(40, 40);
            form.Show();
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

using TacticalGo.Domain;

namespace TacticalGo.Play;

/// <summary>
/// Five short, picture-first pages. Each diagram is a small real position shown through the same controller and board view
/// as the game (so counts, previews and refusal reasons are produced by the engine). Not the current game.
/// </summary>
public sealed class HelpForm : Form
{
    private readonly IReadOnlyList<HelpPage> _pages;
    private readonly Label _title = new() { Dock = DockStyle.Top, Height = 40, Font = new Font("Microsoft JhengHei UI", 15f, FontStyle.Bold), Padding = new Padding(12, 8, 0, 0) };
    private readonly Label _example = new() { Dock = DockStyle.Top, Height = 22, ForeColor = Color.DimGray, Padding = new Padding(12, 0, 0, 0), Text = "示意圖：獨立的小棋盤，不是你現在的對局" };
    private readonly Label _caption = new() { Dock = DockStyle.Bottom, Height = 96, Padding = new Padding(14, 6, 14, 0), Font = new Font("Microsoft JhengHei UI", 11.5f) };
    private readonly Panel _stage = new() { Dock = DockStyle.Fill };
    private readonly Button _prev = new() { Text = "◀ 上一頁", Width = 110, Height = 34 };
    private readonly Button _next = new() { Text = "下一頁 ▶", Width = 110, Height = 34 };
    private readonly Button _close = new() { Text = "關閉", Width = 90, Height = 34, DialogResult = DialogResult.Cancel };
    private readonly RuleConfig _config;
    private int _index;

    public HelpForm(RuleConfig config)
    {
        _config = config;
        _pages = HelpScenarios.Pages(config);
        Text = "怎麼玩";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterParent;
        MaximizeBox = MinimizeBox = false;
        ClientSize = new Size(560, 640);
        Font = new Font("Microsoft JhengHei UI", 10f);

        var nav = new FlowLayoutPanel { Dock = DockStyle.Bottom, Height = 50, FlowDirection = FlowDirection.RightToLeft, Padding = new Padding(8) };
        nav.Controls.Add(_close);
        nav.Controls.Add(_next);
        nav.Controls.Add(_prev);

        Controls.Add(_stage);
        Controls.Add(_caption);
        Controls.Add(nav);
        Controls.Add(_example);
        Controls.Add(_title);
        CancelButton = _close;

        _prev.Click += (_, _) => Show(_index - 1);
        _next.Click += (_, _) => Show(_index + 1);
        Show(0);
    }

    public void ShowPage(int index) => Show(index);

    private void Show(int index)
    {
        _index = Math.Clamp(index, 0, _pages.Count - 1);
        var page = _pages[_index];
        _title.Text = page.Title;
        _caption.Text = page.Caption;
        _prev.Enabled = _index > 0;
        _next.Enabled = _index < _pages.Count - 1;

        foreach (Control c in _stage.Controls) c.Dispose();
        _stage.Controls.Clear();

        if (page.Position is null)
        {
            var apMax = _config.ApPerTurn;
            var first = _config.FirstTurnApResolved;
            var text = $"●●  →  ●○  →  ○○  →  換對手\n\n每放一顆子，少一個 ●。\n先手第一回合只有 {first} 個。";
            _stage.Controls.Add(new Label
            {
                Dock = DockStyle.Fill, TextAlign = ContentAlignment.MiddleCenter,
                Font = new Font("Microsoft JhengHei UI", 20f, FontStyle.Bold), Text = apMax == 1 ? text.Replace("●●  →  ●○  →  ○○", "●  →  ○") : text,
            });
            return;
        }

        var play = new PlayController(page.Position, "示意");
        if (page.Click is { } click) play.ClickPoint(click);
        var board = new BoardView(play) { Dock = DockStyle.Fill, Interactive = false, MinimumSize = Size.Empty };
        _stage.Controls.Add(board);
    }
}

using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

public sealed class MainForm : Form
{
    private readonly PlayController _play;
    private readonly BoardView _board;
    private readonly Label _turn = new() { AutoSize = true, Font = new Font("Microsoft JhengHei UI", 16f, FontStyle.Bold) };
    private readonly Label _resources = new() { AutoSize = true, Font = new Font("Microsoft JhengHei UI", 11f) };
    private readonly Label _rules = new() { AutoSize = true, ForeColor = Color.DimGray };
    private readonly Label _message = new()
    {
        AutoSize = false, Height = 78, Dock = DockStyle.Top, Padding = new Padding(8), BorderStyle = BorderStyle.FixedSingle,
        Font = new Font("Microsoft JhengHei UI", 10.5f),
    };
    private readonly Button _confirm = Btn("確認落子 (Enter)");
    private readonly Button _cancel = Btn("取消選取 (Esc)");
    private readonly Button _endTurn = Btn("結束回合");
    private readonly Button _undo = Btn("復原 (Ctrl+Z)");
    private readonly Button _newGame = Btn("新局…");
    private readonly ComboBox _liberties = new() { DropDownStyle = ComboBoxStyle.DropDownList, Width = 200 };
    private readonly ListBox _log = new() { Dock = DockStyle.Fill, IntegralHeight = false, HorizontalScrollbar = true };

    public MainForm(PlayController play)
    {
        _play = play;
        Text = "Tactical Go — 原型 UI-1（Windows 試玩，非正式版）";
        ClientSize = new Size(1040, 700);
        MinimumSize = new Size(900, 620);
        Font = new Font("Microsoft JhengHei UI", 10f);
        KeyPreview = true;

        _board = new BoardView(play) { Dock = DockStyle.Fill };
        _board.PointTapped += p => _play.ClickPoint(p);

        var side = new Panel { Dock = DockStyle.Right, Width = 340, Padding = new Padding(12) };
        var stack = new FlowLayoutPanel { Dock = DockStyle.Top, FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoSize = true };
        stack.Controls.AddRange([_turn, _resources, _rules]);

        var buttons = new TableLayoutPanel { Dock = DockStyle.Top, ColumnCount = 2, RowCount = 3, Height = 150, Padding = new Padding(0, 8, 0, 8) };
        buttons.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
        buttons.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
        buttons.Controls.Add(_confirm, 0, 0);
        buttons.Controls.Add(_cancel, 1, 0);
        buttons.Controls.Add(_endTurn, 0, 1);
        buttons.Controls.Add(_undo, 1, 1);
        buttons.Controls.Add(_newGame, 0, 2);

        _liberties.Items.AddRange(["氣數：關", "氣數：僅危險棋串與主將（預設）", "氣數：全部棋串"]);
        _liberties.SelectedIndex = (int)_play.Liberties;
        _liberties.SelectedIndexChanged += (_, _) => { _play.Liberties = (LibertyDisplay)_liberties.SelectedIndex; _board.Invalidate(); };

        var logTitle = new Label { Text = "行動紀錄", Dock = DockStyle.Top, Height = 24, ForeColor = Color.DimGray };

        side.Controls.Add(_log);
        side.Controls.Add(logTitle);
        side.Controls.Add(_liberties);
        side.Controls.Add(buttons);
        side.Controls.Add(_message);
        side.Controls.Add(stack);
        _liberties.Dock = DockStyle.Top;

        Controls.Add(_board);
        Controls.Add(side);

        _confirm.Click += (_, _) => _play.Confirm();
        _cancel.Click += (_, _) => _play.Cancel();
        _endTurn.Click += (_, _) => _play.EndTurn();
        _undo.Click += (_, _) => _play.Undo();
        _newGame.Click += (_, _) => AskNewGame();
        KeyDown += OnKey;

        _play.Changed += Refresh_;
        Refresh_();
    }

    private static Button Btn(string text) => new() { Text = text, Dock = DockStyle.Fill, Margin = new Padding(3), Height = 40 };

    private void OnKey(object? sender, KeyEventArgs e)
    {
        if (e.KeyCode == Keys.Enter) { _play.Confirm(); e.Handled = true; }
        else if (e.KeyCode == Keys.Escape) { _play.Cancel(); e.Handled = true; }
        else if (e.KeyCode == Keys.Z && e.Control) { _play.Undo(); e.Handled = true; }
    }

    private void AskNewGame()
    {
        using var dialog = new NewGameDialog();
        if (dialog.ShowDialog(this) == DialogResult.OK) _play.NewGame(dialog.Config);
    }

    private void Refresh_()
    {
        var s = _play.State;
        var who = EventText.Name(s.Current);
        _turn.Text = _play.GameOver
            ? (s.Status == GameStatus.Won ? $"★ {EventText.Name(s.Winner!.Value)}獲勝" : "和局")
            : $"{(s.Current == Player.One ? "●" : "○")} {who}回合　第 {s.Ply} 手";
        var pips = new string('●', s.ApRemaining) + new string('○', Math.Max(0, ApMax(s) - s.ApRemaining));
        _resources.Text = _play.GameOver
            ? $"黑方 Mana {s.ManaOf(Player.One)}　白方 Mana {s.ManaOf(Player.Two)}"
            : $"AP {pips}  {s.ApRemaining}/{ApMax(s)}\nMana {s.ManaOf(s.Current)}/{s.Config.ManaCap}（對手 {s.ManaOf(s.Current.Opponent())}）";
        _rules.Text = _play.RuleSummary;

        _message.Text = _play.Message;
        _message.ForeColor = _play.MessageIsError ? Color.FromArgb(0xB0, 0x2A, 0x1C) : SystemColors.ControlText;
        _message.BackColor = _play.MessageIsError ? Color.FromArgb(0xFB, 0xE9, 0xE6) : Color.FromArgb(0xFF, 0xF8, 0xE1);

        _confirm.Enabled = _play.CanConfirm;
        _cancel.Enabled = _play.Selected is not null || _play.Inspect is not null;
        _endTurn.Enabled = !_play.GameOver;
        _undo.Enabled = _play.CanUndo;

        _log.BeginUpdate();
        _log.Items.Clear();
        foreach (var line in _play.Log) _log.Items.Add(line);
        _log.EndUpdate();
        if (_log.Items.Count > 0) _log.TopIndex = _log.Items.Count - 1;
        _board.Invalidate();
    }

    /// <summary>AP the current player started this turn with (first turn may be reduced); used only for display.</summary>
    private static int ApMax(GameState s) =>
        s.Ply == 1 ? s.Config.FirstTurnApResolved : s.Config.ApPerTurn;
}

internal sealed class NewGameDialog : Form
{
    private readonly ComboBox _rule = new() { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Top };

    public RuleConfig Config => _rule.SelectedIndex switch
    {
        1 => RuleConfig.TwoApBaseline,
        2 => RuleConfig.TwoApBaseline with { ApPerTurn = 1, MaxPlies = 200 },
        _ => new RuleConfig(),
    };

    public NewGameDialog()
    {
        Text = "新局";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterParent;
        MaximizeBox = MinimizeBox = false;
        ClientSize = new Size(380, 150);
        Padding = new Padding(12);

        _rule.Items.AddRange([
            "每回合 2 AP，先手首回合 1 AP（暫定預設）",
            "每回合 2 AP，先手首回合也 2 AP（基線）",
            "每回合 1 AP（對照）",
        ]);
        _rule.SelectedIndex = 0;

        var ok = new Button { Text = "開始", DialogResult = DialogResult.OK, Dock = DockStyle.Bottom, Height = 36 };
        var hint = new Label { Text = "職業選擇在 UI-2 加入；此版本雙方皆為無職業。", Dock = DockStyle.Top, Height = 40, ForeColor = Color.DimGray };
        Controls.Add(ok);
        Controls.Add(hint);
        Controls.Add(_rule);
        AcceptButton = ok;
    }
}

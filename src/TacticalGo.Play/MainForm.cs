using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

public sealed class MainForm : Form
{
    private static readonly Color Accent = Color.FromArgb(0x25, 0x63, 0xEB);

    private readonly PlayController _play;
    private readonly BoardView _board;

    private readonly Label _goal = new()
    {
        Dock = DockStyle.Top, Height = 34, TextAlign = ContentAlignment.MiddleCenter,
        BackColor = Color.FromArgb(0x1F, 0x2A, 0x44), ForeColor = Color.White,
        Font = new Font("Microsoft JhengHei UI", 12f, FontStyle.Bold),
        Text = "目標：包圍並提吃對方的「主」就獲勝",
    };
    private readonly Label _turn = new() { AutoSize = true, Font = new Font("Microsoft JhengHei UI", 16f, FontStyle.Bold) };
    private readonly Label _ap = new() { AutoSize = true, Font = new Font("Microsoft JhengHei UI", 12f) };
    private readonly Label _mana = new() { AutoSize = true, Font = new Font("Microsoft JhengHei UI", 11f) };
    private readonly Label _rules = new() { AutoSize = true, ForeColor = Color.DimGray };
    private readonly Label _mineCommander = CommanderLabel();
    private readonly Label _enemyCommander = CommanderLabel();
    private readonly Label _sharedNote = new()
    {
        AutoSize = true, MaximumSize = new Size(330, 0), ForeColor = Color.DimGray, Font = new Font("Microsoft JhengHei UI", 9f),
        Text = "生存空格：棋子旁邊的空格。相連的棋共用同一組，降到 0 就被提掉。",
    };
    private readonly Label _hint = new()
    {
        AutoSize = true, MaximumSize = new Size(330, 0), Font = new Font("Microsoft JhengHei UI", 11f, FontStyle.Bold),
    };
    private readonly Label _feedback = new()
    {
        AutoSize = false, Height = 60, Dock = DockStyle.Fill, Padding = new Padding(8), BorderStyle = BorderStyle.FixedSingle,
        Font = new Font("Microsoft JhengHei UI", 10.5f),
    };
    private readonly Button _confirm = Btn("確認落子 (Enter)");
    private readonly Button _cancel = Btn("取消選取 (Esc)");
    private readonly Button _endTurn = Btn("結束回合");
    private readonly Button _undo = Btn("復原 (Ctrl+Z)");
    private readonly Button _newGame = Btn("新局…");
    private readonly Button _help = Btn("怎麼玩？");
    private readonly ComboBox _liberties = new() { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Fill };
    private readonly ListBox _log = new() { Dock = DockStyle.Fill, IntegralHeight = false, HorizontalScrollbar = true };

    public MainForm(PlayController play)
    {
        _play = play;
        Text = "Tactical Go — 原型 UI-1.1（Windows 試玩，非正式版）";
        ClientSize = new Size(1100, 840);
        MinimumSize = new Size(940, 760);
        Font = new Font("Microsoft JhengHei UI", 10f);
        KeyPreview = true;

        _board = new BoardView(play) { Dock = DockStyle.Fill };
        _board.PointTapped += p => _play.ClickPoint(p);

        var side = new TableLayoutPanel
        {
            Dock = DockStyle.Right, Width = 370, Padding = new Padding(12, 8, 12, 8),
            ColumnCount = 1, RowCount = 10,
        };
        side.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        for (var i = 0; i < 8; i++) side.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        side.RowStyles.Add(new RowStyle(SizeType.Absolute, 72)); // feedback
        side.RowStyles.Add(new RowStyle(SizeType.Percent, 100)); // log

        var header = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.TopDown, WrapContents = false, Margin = Padding.Empty };
        header.Controls.AddRange([_turn, _ap, _mana, _rules]);

        var commanders = new TableLayoutPanel { Dock = DockStyle.Top, AutoSize = true, ColumnCount = 1, Margin = new Padding(0, 6, 0, 0) };
        commanders.Controls.Add(_mineCommander);
        commanders.Controls.Add(_enemyCommander);
        commanders.Controls.Add(_sharedNote);

        var buttons = new TableLayoutPanel { Dock = DockStyle.Top, ColumnCount = 2, RowCount = 3, Height = 108, Margin = new Padding(0, 6, 0, 0) };
        buttons.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
        buttons.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
        for (var i = 0; i < 3; i++) buttons.RowStyles.Add(new RowStyle(SizeType.Percent, 33.33f));
        buttons.Controls.Add(_confirm, 0, 0);
        buttons.Controls.Add(_cancel, 1, 0);
        buttons.Controls.Add(_endTurn, 0, 1);
        buttons.Controls.Add(_undo, 1, 1);
        buttons.Controls.Add(_newGame, 0, 2);
        buttons.Controls.Add(_help, 1, 2);

        _liberties.Items.AddRange(["生存空格數字：全部隱藏", "生存空格數字：只標危險棋串與主將（預設）", "生存空格數字：全部棋串"]);
        _liberties.SelectedIndex = (int)_play.Liberties;
        _liberties.SelectedIndexChanged += (_, _) => { _play.Liberties = (LibertyDisplay)_liberties.SelectedIndex; _board.Invalidate(); };

        var logTitle = new Label { Text = "行動紀錄", AutoSize = true, ForeColor = Color.DimGray, Margin = new Padding(0, 6, 0, 0) };

        side.Controls.Add(header, 0, 0);
        side.Controls.Add(commanders, 0, 1);
        side.Controls.Add(_hint, 0, 2);
        side.Controls.Add(_feedback, 0, 3);
        side.Controls.Add(buttons, 0, 4);
        side.Controls.Add(_liberties, 0, 5);
        side.Controls.Add(logTitle, 0, 6);
        side.Controls.Add(_log, 0, 7);
        // rows 8/9 intentionally unused; layout keeps the log as the elastic row
        side.RowStyles[3] = new RowStyle(SizeType.Absolute, 72);
        side.RowStyles[7] = new RowStyle(SizeType.Percent, 100);

        Controls.Add(_board);
        Controls.Add(side);
        Controls.Add(_goal);

        _confirm.Click += (_, _) => _play.Confirm();
        _cancel.Click += (_, _) => _play.Cancel();
        _endTurn.Click += (_, _) => _play.EndTurn();
        _undo.Click += (_, _) => _play.Undo();
        _newGame.Click += (_, _) => AskNewGame();
        _help.Click += (_, _) => { using var help = new HelpForm(_play.State.Config); help.ShowDialog(this); };
        KeyDown += OnKey;

        _play.Changed += Refresh_;
        Refresh_();
    }

    private static Button Btn(string text) =>
        new() { Text = text, Dock = DockStyle.Fill, Margin = new Padding(3), FlatStyle = FlatStyle.Standard };

    private static Label CommanderLabel() => new()
    {
        AutoSize = false, Width = 346, Height = 34, TextAlign = ContentAlignment.MiddleLeft, Padding = new Padding(8, 0, 0, 0),
        Font = new Font("Microsoft JhengHei UI", 11f, FontStyle.Bold), Margin = new Padding(0, 3, 0, 0), BorderStyle = BorderStyle.FixedSingle,
    };

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

    private static void ShowCommander(Label label, string title, CommanderInfo info)
    {
        if (info.Captured)
        {
            label.Text = $"{title}：已被提掉";
            label.BackColor = Color.FromArgb(0x3A, 0x3A, 0x3A);
            label.ForeColor = Color.White;
        }
        else if (info.InDanger)
        {
            label.Text = $"{title}：生存空格 1　⚠ 危險！";
            label.BackColor = Color.FromArgb(0xC0, 0x39, 0x2B);
            label.ForeColor = Color.White;
        }
        else if (info.Liberties == 2)
        {
            label.Text = $"{title}：生存空格 2　（注意）";
            label.BackColor = Color.FromArgb(0xFD, 0xE7, 0xB8);
            label.ForeColor = Color.FromArgb(0x7A, 0x4B, 0x00);
        }
        else
        {
            label.Text = $"{title}：生存空格 {info.Liberties}";
            label.BackColor = Color.FromArgb(0xF3, 0xF4, 0xF6);
            label.ForeColor = Color.FromArgb(0x1D, 0x1B, 0x16);
        }
    }

    private void Refresh_()
    {
        var s = _play.State;
        var me = s.Current;

        _turn.Text = _play.GameOver
            ? _play.ResultText
            : $"{(me == Player.One ? "●" : "○")} {_play.TurnTitle}";
        _turn.ForeColor = _play.GameOver ? Color.FromArgb(0x1E, 0x7B, 0x3E) : SystemColors.ControlText;

        var apMax = s.Ply == 1 ? s.Config.FirstTurnApResolved : s.Config.ApPerTurn;
        _ap.Visible = !_play.GameOver;
        _ap.Text = $"行動點 {new string('●', s.ApRemaining)}{new string('○', Math.Max(0, apMax - s.ApRemaining))}  （每放一子 -1）　ply {s.Ply}";

        _mana.Visible = _play.ShowMana;
        _mana.Text = $"Mana {s.ManaOf(me)}/{s.Config.ManaCap}";
        _rules.Text = _play.RuleSummary;

        ShowCommander(_mineCommander, $"我方主將（{EventText.Name(me)}）", _play.Commander(me));
        ShowCommander(_enemyCommander, $"敵方主將（{EventText.Name(me.Opponent())}）", _play.Commander(me.Opponent()));

        _hint.Text = _play.Hint;
        _feedback.Text = _play.Feedback;
        (_feedback.BackColor, _feedback.ForeColor) = _play.FeedbackKind switch
        {
            FeedbackKind.Error => (Color.FromArgb(0xFB, 0xE9, 0xE6), Color.FromArgb(0xB0, 0x2A, 0x1C)),
            FeedbackKind.Warning => (Color.FromArgb(0xFD, 0xE7, 0xB8), Color.FromArgb(0x7A, 0x4B, 0x00)),
            FeedbackKind.Success => (Color.FromArgb(0xE3, 0xF4, 0xE8), Color.FromArgb(0x1E, 0x6B, 0x38)),
            FeedbackKind.Info => (Color.FromArgb(0xE8, 0xF0, 0xFE), Color.FromArgb(0x1D, 0x3A, 0x8A)),
            _ => (SystemColors.Control, SystemColors.ControlText),
        };

        _confirm.Enabled = _play.CanConfirm;
        _confirm.BackColor = _play.CanConfirm ? Accent : SystemColors.Control;
        _confirm.ForeColor = _play.CanConfirm ? Color.White : SystemColors.GrayText;
        _confirm.FlatStyle = _play.CanConfirm ? FlatStyle.Flat : FlatStyle.Standard;
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
        ClientSize = new Size(400, 150);
        Padding = new Padding(12);

        _rule.Items.AddRange([
            "每回合 2 AP，先手首回合 1 AP（暫定預設）",
            "每回合 2 AP，先手首回合也 2 AP（基線）",
            "每回合 1 AP（對照）",
        ]);
        _rule.SelectedIndex = 0;

        var ok = new Button { Text = "開始", DialogResult = DialogResult.OK, Dock = DockStyle.Bottom, Height = 36 };
        var hint = new Label { Text = "職業與關卡之後加入；此版本雙方皆為無職業。", Dock = DockStyle.Top, Height = 40, ForeColor = Color.DimGray };
        Controls.Add(ok);
        Controls.Add(hint);
        Controls.Add(_rule);
        AcceptButton = ok;
    }
}

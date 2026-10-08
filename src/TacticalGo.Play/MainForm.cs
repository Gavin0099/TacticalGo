using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

public sealed class MainForm : Form
{
    private static readonly Color Accent = Color.FromArgb(0x25, 0x63, 0xEB);
    private static readonly Color GoodGreen = Color.FromArgb(0x1E, 0x7B, 0x3E);

    private readonly PlayController _play;
    private readonly LevelSession? _level;
    private readonly BoardView _board;

    private readonly Label _goal = new()
    {
        Dock = DockStyle.Top, Height = 38, TextAlign = ContentAlignment.MiddleCenter,
        BackColor = Color.FromArgb(0x1F, 0x2A, 0x44), ForeColor = Color.White,
        Font = new Font("Microsoft JhengHei UI", 13f, FontStyle.Bold),
    };

    // fixed action area under the board: nothing here can cover a stone
    private readonly Button _confirm = new()
    {
        Text = "✔ 放這裡", Width = 235, Height = 58, FlatStyle = FlatStyle.Flat,
        Font = new Font("Microsoft JhengHei UI", 17f, FontStyle.Bold), Margin = new Padding(8, 8, 6, 8),
    };
    private readonly Button _cancel = new()
    {
        Text = "取消", Width = 100, Height = 58, Font = new Font("Microsoft JhengHei UI", 14f), Margin = new Padding(6, 8, 6, 8),
    };
    private readonly Button _modePlace = ModeBtn("放士兵");
    private readonly Button _modeSkill = ModeBtn("技能：換位");
    private readonly Button _modeSummon = ModeBtn("召喚英雄");
    private readonly Label _heroes = new() { AutoSize = true, MaximumSize = new Size(340, 0) };
    private readonly PictureBox _portraitOne = new() { Size = new Size(44, 44), SizeMode = PictureBoxSizeMode.Zoom };
    private readonly PictureBox _portraitTwo = new() { Size = new Size(44, 44), SizeMode = PictureBoxSizeMode.Zoom };
    private readonly FlowLayoutPanel _heroRow = new() { AutoSize = true, WrapContents = false, Margin = Padding.Empty };
    private readonly FlowLayoutPanel _directionRow = new() { Dock = DockStyle.Fill, AutoSize = true, WrapContents = true, Margin = Padding.Empty };
    private readonly Dictionary<PushDirection, Button> _directions = [];
    private readonly Label _skillNote = new()
    {
        AutoSize = false, Dock = DockStyle.Fill, Height = 44, TextAlign = ContentAlignment.MiddleLeft, ForeColor = Color.DimGray,
        Font = new Font("Microsoft JhengHei UI", 10.5f), Margin = new Padding(10, 2, 0, 0),
    };
    // Separate rows keep controls within the board column at the supported minimum window size.
    private readonly TableLayoutPanel _bar = new()
    {
        Dock = DockStyle.Bottom, AutoSize = true, AutoSizeMode = AutoSizeMode.GrowAndShrink, ColumnCount = 1, RowCount = 5,
        BackColor = Color.FromArgb(0xEE, 0xEA, 0xDF), Margin = Padding.Empty, Padding = Padding.Empty,
    };
    private readonly FlowLayoutPanel _modeRow = new()
    {
        Dock = DockStyle.Fill, Height = 58, FlowDirection = FlowDirection.LeftToRight, WrapContents = false,
        Padding = new Padding(4, 6, 4, 0), Visible = false, Margin = Padding.Empty,
    };
    private readonly Label _barInfo = new()
    {
        AutoSize = false, Dock = DockStyle.Fill, Height = 34, TextAlign = ContentAlignment.MiddleLeft, ForeColor = Color.DimGray,
        Font = new Font("Microsoft JhengHei UI", 10.5f), Margin = new Padding(10, 0, 8, 6),
    };

    private readonly Label _turn = new() { AutoSize = true, MaximumSize = new Size(340, 0), Font = new Font("Microsoft JhengHei UI", 15f, FontStyle.Bold) };
    private readonly Label _ap = new() { AutoSize = true, Font = new Font("Microsoft JhengHei UI", 12f) };
    private readonly Label _mana = new() { AutoSize = true, Font = new Font("Microsoft JhengHei UI", 11f) };
    private readonly Label _rules = new() { AutoSize = true, ForeColor = Color.DimGray };

    private readonly Panel _levelPanel = new() { AutoSize = true, Dock = DockStyle.Top, Padding = new Padding(0, 0, 0, 6) };
    private readonly Label _levelProgress = new()
    {
        AutoSize = true, MaximumSize = new Size(340, 0), Font = new Font("Microsoft JhengHei UI", 11f, FontStyle.Bold), ForeColor = Accent,
    };
    private readonly Label _stageText = new() { AutoSize = true, MaximumSize = new Size(340, 0), Font = new Font("Microsoft JhengHei UI", 11f) };
    private readonly Label _stageDone = new()
    {
        AutoSize = true, MaximumSize = new Size(340, 0), Font = new Font("Microsoft JhengHei UI", 11.5f, FontStyle.Bold), ForeColor = GoodGreen,
    };
    private readonly Button _nextStage = new() { Text = "下一段 ▶", Width = 160, Height = 40, FlatStyle = FlatStyle.Flat, BackColor = GoodGreen, ForeColor = Color.White, Font = new Font("Microsoft JhengHei UI", 12f, FontStyle.Bold) };
    private readonly Button _restartStage = new() { Text = "重來本段", Width = 120, Height = 40 };
    private readonly Button _levelUndo = new() { Text = "復原 (Ctrl+Z)", Width = 140, Height = 40 };
    private readonly Button _nextLevel = new() { Text = "前往下一關 ▶", Width = 190, Height = 40, FlatStyle = FlatStyle.Flat, BackColor = GoodGreen, ForeColor = Color.White, Font = new Font("Microsoft JhengHei UI", 12f, FontStyle.Bold) };

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
        AutoSize = false, Dock = DockStyle.Fill, Padding = new Padding(8), BorderStyle = BorderStyle.FixedSingle,
        Font = new Font("Microsoft JhengHei UI", 10.5f),
    };
    private readonly Button _endTurn = Btn("結束回合");
    private readonly Button _undo = Btn("復原 (Ctrl+Z)");
    private readonly Button _newGame = Btn("新局／選模式…");
    private readonly Button _help = Btn("怎麼玩？");
    private readonly ComboBox _liberties = new() { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Fill };
    private readonly ListBox _log = new() { Dock = DockStyle.Fill, IntegralHeight = false, HorizontalScrollbar = true };
    private readonly TableLayoutPanel _freeButtons;

    public MainForm(PlayController play, LevelSession? level = null)
    {
        _play = play;
        _level = level;
        Text = "Tactical Go — 原型（Windows 試玩，非正式版）";
        Font = new Font("Microsoft JhengHei UI", 10f);     // set BEFORE sizing: changing the font later rescales the window
        // Never taller/wider than the screen can show, so the fixed action bar under the board is always visible.
        var work = Screen.PrimaryScreen?.WorkingArea ?? new Rectangle(0, 0, 1280, 800);
        var sizes = WindowSizes(work);
        ClientSize = sizes.Client;
        MinimumSize = sizes.Minimum;
        KeyPreview = true;

        _board = new BoardView(play) { Dock = DockStyle.Fill };
        _board.PointTapped += p => _play.ClickPoint(p);

        // ---- left: board + fixed action bar ----
        var actionRow = new FlowLayoutPanel
        {
            Dock = DockStyle.Fill, Height = 76, FlowDirection = FlowDirection.LeftToRight, WrapContents = false,
            Padding = new Padding(4, 0, 4, 0), Margin = Padding.Empty,
        };
        actionRow.Controls.AddRange([_confirm, _cancel]);
        _modeRow.Controls.AddRange([_modePlace, _modeSummon, _modeSkill]);
        _modeRow.WrapContents = true;
        _modeRow.AutoSize = true;
        _bar.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        for (var row = 0; row < 5; row++) _bar.RowStyles.Add(new RowStyle(SizeType.AutoSize));
        _bar.Controls.Add(_modeRow, 0, 0);
        _bar.Controls.Add(_skillNote, 0, 1);
        foreach (var (direction, text) in new[] { (PushDirection.Up, "↑ 上"), (PushDirection.Right, "→ 右"), (PushDirection.Down, "↓ 下"), (PushDirection.Left, "← 左") })
        {
            var button = new Button { Text = text, Width = 95, Height = 38, Margin = new Padding(6, 0, 6, 6) };
            button.Click += (_, _) => { _play.ChoosePushDirection(direction); _board.Focus(); };
            _directions.Add(direction, button);
            _directionRow.Controls.Add(button);
        }
        _bar.Controls.Add(_directionRow, 0, 2);
        _bar.Controls.Add(actionRow, 0, 3);
        _bar.Controls.Add(_barInfo, 0, 4);
        var host = new Panel { Dock = DockStyle.Fill };
        host.Controls.Add(_board);
        host.Controls.Add(_bar);

        // ---- right: information ----
        var side = new TableLayoutPanel
        {
            Dock = DockStyle.Right, Width = 380, Padding = new Padding(12, 8, 12, 8), ColumnCount = 1, RowCount = 9,
        };
        side.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
        for (var i = 0; i < 5; i++) side.RowStyles.Add(new RowStyle(SizeType.AutoSize));  // header, level, commanders, hint (+ spare)
        side.RowStyles[3] = new RowStyle(SizeType.AutoSize);
        side.RowStyles[4] = new RowStyle(SizeType.Absolute, 74);                          // feedback
        side.RowStyles.Add(new RowStyle(SizeType.AutoSize));                              // buttons
        side.RowStyles.Add(new RowStyle(SizeType.AutoSize));                              // combo
        side.RowStyles.Add(new RowStyle(SizeType.AutoSize));                              // log title
        side.RowStyles.Add(new RowStyle(SizeType.Percent, 100));                          // log

        var header = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.TopDown, WrapContents = false, Margin = Padding.Empty };
        _heroes.MaximumSize = new Size(246, 0);
        _heroRow.Controls.AddRange([_portraitOne, _heroes, _portraitTwo]);
        header.Controls.AddRange([_turn, _ap, _mana, _heroRow, _rules]);

        var levelStack = new FlowLayoutPanel { AutoSize = true, FlowDirection = FlowDirection.TopDown, WrapContents = false, Dock = DockStyle.Top };
        var levelButtons = new FlowLayoutPanel { AutoSize = true, MaximumSize = new Size(350, 0), FlowDirection = FlowDirection.LeftToRight, WrapContents = true };
        levelButtons.Controls.AddRange([_nextStage, _nextLevel, _restartStage, _levelUndo]);
        levelStack.Controls.AddRange([_levelProgress, _stageText, _stageDone, levelButtons]);
        _levelPanel.Controls.Add(levelStack);

        var commanders = new TableLayoutPanel { Dock = DockStyle.Top, AutoSize = true, ColumnCount = 1, Margin = new Padding(0, 6, 0, 0) };
        commanders.Controls.Add(_mineCommander);
        commanders.Controls.Add(_enemyCommander);
        commanders.Controls.Add(_sharedNote);

        _freeButtons = new TableLayoutPanel { Dock = DockStyle.Top, ColumnCount = 2, RowCount = 2, Height = 80, Margin = new Padding(0, 6, 0, 0) };
        _freeButtons.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
        _freeButtons.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 50));
        _freeButtons.RowStyles.Add(new RowStyle(SizeType.Percent, 50));
        _freeButtons.RowStyles.Add(new RowStyle(SizeType.Percent, 50));
        _freeButtons.Controls.Add(_endTurn, 0, 0);
        _freeButtons.Controls.Add(_undo, 1, 0);
        _freeButtons.Controls.Add(_newGame, 0, 1);
        _freeButtons.Controls.Add(_help, 1, 1);

        _liberties.Items.AddRange(["生存空格數字：全部隱藏", "生存空格數字：只標危險棋串與主將（預設）", "生存空格數字：全部棋串"]);
        _liberties.SelectedIndex = (int)_play.Liberties;
        _liberties.SelectedIndexChanged += (_, _) => { _play.Liberties = (LibertyDisplay)_liberties.SelectedIndex; _board.Invalidate(); };

        var logTitle = new Label { Text = "行動紀錄", AutoSize = true, ForeColor = Color.DimGray, Margin = new Padding(0, 6, 0, 0) };

        side.Controls.Add(header, 0, 0);
        side.Controls.Add(_levelPanel, 0, 1);
        side.Controls.Add(commanders, 0, 2);
        side.Controls.Add(_hint, 0, 3);
        side.Controls.Add(_feedback, 0, 4);
        side.Controls.Add(_freeButtons, 0, 5);
        side.Controls.Add(_liberties, 0, 6);
        side.Controls.Add(logTitle, 0, 7);
        side.Controls.Add(_log, 0, 8);

        Controls.Add(host);
        Controls.Add(side);
        Controls.Add(_goal);

        _confirm.Click += (_, _) => _play.Confirm();
        _cancel.Click += (_, _) => _play.Cancel();
        _endTurn.Click += (_, _) => _play.EndTurn();
        _undo.Click += (_, _) => _play.Undo();
        _newGame.Click += (_, _) => AskNewGame();
        _help.Click += (_, _) => { using var help = new HelpForm(_play.State.Config); help.ShowDialog(this); };
        _modePlace.Click += (_, _) => { _play.UsePlaceMode(); _board.Focus(); };   // do not keep focus on a button
        _modeSkill.Click += (_, _) => { _play.BeginSkill(); _board.Focus(); };
        _modeSummon.Click += (_, _) => { _play.BeginSummon(); _board.Focus(); };
        _levelUndo.Click += (_, _) => _play.Undo();
        _nextLevel.Click += (_, _) => _level?.NextLevel();
        _nextStage.Click += (_, _) => _level?.NextStage();
        _restartStage.Click += (_, _) => _level?.RestartStage();
        KeyDown += OnKey;

        _play.Changed += Refresh_;
        Refresh_();
    }

    private bool InLevel => _level is { Active: true };

    // A temporarily missing/empty display during desktop changes must not produce negative form dimensions.
    internal static (Size Client, Size Minimum) WindowSizes(Rectangle work)
    {
        if (work.Width <= 0 || work.Height <= 0) work = new Rectangle(0, 0, 1280, 800);
        var width = Math.Max(640, work.Width - 40);
        var height = Math.Max(480, work.Height - 90);
        return (new(Math.Min(1140, width), Math.Min(860, height)), new(Math.Min(900, width), Math.Min(700, height)));
    }

    private static Button ModeBtn(string text) => new()
    {
        Text = text, Width = 145, Height = 46, Font = new Font("Microsoft JhengHei UI", 11.5f, FontStyle.Bold), Margin = new Padding(6, 0, 6, 0),
    };

    private static void StyleMode(Button b, bool selected, bool enabled)
    {
        b.Enabled = enabled;
        b.FlatStyle = selected ? FlatStyle.Flat : FlatStyle.Standard;
        b.BackColor = selected ? Accent : SystemColors.Control;
        b.ForeColor = selected ? Color.White : enabled ? SystemColors.ControlText : SystemColors.GrayText;
    }

    private static Button Btn(string text) =>
        new() { Text = text, Dock = DockStyle.Fill, Margin = new Padding(3), FlatStyle = FlatStyle.Standard };

    private static Label CommanderLabel() => new()
    {
        AutoSize = false, Width = 350, Height = 34, TextAlign = ContentAlignment.MiddleLeft, Padding = new Padding(8, 0, 0, 0),
        Font = new Font("Microsoft JhengHei UI", 11f, FontStyle.Bold), Margin = new Padding(0, 3, 0, 0), BorderStyle = BorderStyle.FixedSingle,
    };

    private void OnKey(object? sender, KeyEventArgs e)
    {
        if (e.KeyCode == Keys.Enter) { _play.Confirm(); e.Handled = e.SuppressKeyPress = true; }   // suppress so a focused button does not also fire
        else if (e.KeyCode == Keys.Escape) { _play.Cancel(); e.Handled = e.SuppressKeyPress = true; }
        else if (e.KeyCode == Keys.Z && e.Control) { _play.Undo(); e.Handled = e.SuppressKeyPress = true; }
    }

    private void AskNewGame()
    {
        using var dialog = new NewGameDialog(_level is not null);
        if (dialog.ShowDialog(this) != DialogResult.OK) return;
        if (dialog.TutorialLevel is { } number && _level is not null)
        {
            _level.Active = true;
            _level.LoadLevel(LevelCatalog.Levels.First(l => l.Number == number));
        }
        else
        {
            using var classes = new ClassPickDialog(dialog.Config);
            if (classes.ShowDialog(this) != DialogResult.OK) return;
            if (_level is not null) _level.Active = false;
            _play.OpponentPolicy = null;
            _play.Locked = false;
            _play.NewGame(dialog.Config, classes.ClassOne, classes.ClassTwo);
        }
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
            label.Text = $"{title}：⚠ 生存空格 1！";
            label.BackColor = Color.FromArgb(0xC0, 0x39, 0x2B);
            label.ForeColor = Color.White;
        }
        else if (info.Liberties == 2)
        {
            label.Text = $"{title}：生存空格 2（注意）";
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
        var level = InLevel ? _level : null;

        // goal bar + level panel
        _goal.Text = level is not null ? level.Stage.Goal : "目標：包圍並提吃對方的「主」就獲勝";
        _levelPanel.Visible = level is not null;
        _freeButtons.Visible = level is null;
        _endTurn.Visible = _undo.Visible = _help.Visible = level is null;
        if (level is not null)
        {
            _levelProgress.Text = level.Progress;
            _stageText.Text = level.StageComplete ? "" : level.Stage.Instruction;
            _stageDone.Text = level.StageComplete
                ? level.Learned + (level.LevelComplete ? "\n\n" + level.Level.AfterLastStage : "")
                : "";
            _nextStage.Visible = level.StageComplete && !level.IsLastStage;
            _nextLevel.Visible = level.HasNextLevel;
            _nextLevel.Text = level.NextLevelLabel;
            _board.OverlayText = level.StageComplete ? (level.LevelComplete ? $"✔ 第 {level.Level.Number} 關完成！" : "✔ 完成！") : null;
        }
        else
        {
            _board.OverlayText = null;
            _nextLevel.Visible = false;
        }
        _levelUndo.Visible = level is not null;
        _levelUndo.Enabled = _play.CanUndo;

        // turn / actions
        _turn.Text = level is { StageComplete: true }
            ? "✔ 本段完成"
            : _play.GameOver && level is null
                ? _play.ResultText
                : $"{(me == Player.One ? "●" : "○")} {_play.TurnTitle}";
        _turn.ForeColor = _play.GameOver || level is { StageComplete: true } ? GoodGreen : SystemColors.ControlText;

        var apMax = s.Ply == 1 ? s.Config.FirstTurnApResolved : s.Config.ApPerTurn;
        _ap.Visible = !_play.GameOver;
        _ap.Text = $"還能行動 {s.ApRemaining} 次  {new string('●', s.ApRemaining)}{new string('○', Math.Max(0, apMax - s.ApRemaining))}";

        _mana.Visible = _play.ShowMana;
        _mana.Text = level is null ? $"Mana：黑 {s.ManaOf(Player.One)}/{s.Config.ManaCap}　白 {s.ManaOf(Player.Two)}/{s.Config.ManaCap}" : $"Mana {s.ManaOf(me)}/{s.Config.ManaCap}";
        _heroRow.Visible = level is null && _play.ShowMana;
        _heroes.Visible = level is null && _play.ShowMana;
        _heroes.Text = $"{_play.HeroSummary(Player.One)}\n{_play.HeroSummary(Player.Two)}";
        _portraitOne.Image = HeroArt.Portrait(s.HeroClassOf(Player.One));
        _portraitTwo.Image = HeroArt.Portrait(s.HeroClassOf(Player.Two));
        _rules.Text = level is null ? _play.RuleSummary + $"　ply {s.Ply}" : "";

        ShowCommander(_mineCommander, "我方主將（黑）", _play.Commander(Player.One));
        ShowCommander(_enemyCommander, "敵方主將（白）", _play.Commander(Player.Two));
        if (level is null)
        {
            // free play is two humans taking turns: label by whose turn it is
            ShowCommander(_mineCommander, $"我方主將（{(me == Player.One ? "黑" : "白")}）", _play.Commander(me));
            ShowCommander(_enemyCommander, $"敵方主將（{(me.Opponent() == Player.One ? "黑" : "白")}）", _play.Commander(me.Opponent()));
        }

        _hint.Text = level switch
        {
            { StageComplete: true, LevelComplete: false } => "按「下一段 ▶」繼續，或「重來本段」再看一次。",
            { StageComplete: true, HasNextLevel: true } => "按「前往下一關 ▶」，或「重來本段」再玩一次。",
            { StageComplete: true } => "這一關完成了。可以「重來本段」，或到「新局／選模式…」。",
            not null when _play.Selected is null && _play.Inspect is null && _play.Mode == PlayMode.Place && _play.Skill.State != SkillState.None
                => "先選下方「放士兵」或「技能：換位」，再點棋盤預覽，最後按確認。",
            not null when _play.Selected is null && _play.Inspect is null && _play.Mode == PlayMode.Place => "先點棋盤上的空格看預覽，再按下方「✔ 放這裡」。",
            _ => _play.Hint,
        };
        _feedback.Text = _play.Feedback;
        (_feedback.BackColor, _feedback.ForeColor) = _play.FeedbackKind switch
        {
            FeedbackKind.Error => (Color.FromArgb(0xFB, 0xE9, 0xE6), Color.FromArgb(0xB0, 0x2A, 0x1C)),
            FeedbackKind.Warning => (Color.FromArgb(0xFD, 0xE7, 0xB8), Color.FromArgb(0x7A, 0x4B, 0x00)),
            FeedbackKind.Success => (Color.FromArgb(0xE3, 0xF4, 0xE8), Color.FromArgb(0x1E, 0x6B, 0x38)),
            FeedbackKind.Info => (Color.FromArgb(0xE8, 0xF0, 0xFE), Color.FromArgb(0x1D, 0x3A, 0x8A)),
            _ => (SystemColors.Control, SystemColors.ControlText),
        };

        // fixed action bar
        _confirm.Text = _play.ConfirmLabel;
        _confirm.Enabled = _play.CanConfirm;
        _confirm.BackColor = _play.CanConfirm ? Accent : SystemColors.Control;
        _confirm.ForeColor = _play.CanConfirm ? Color.White : SystemColors.GrayText;
        _cancel.Enabled = _play.Selected is not null || _play.Inspect is not null || _play.Mode != PlayMode.Place;
        _barInfo.Text = _play.ActionBarInfo;

        // place / skill switch (only when the current player has a hero class)
        var skill = _play.Skill;
        var canSwitch = !_play.Locked && !_play.GameOver;
        _modeRow.Visible = _play.HasHeroClass;   // stays visible when a stage is won (no layout jump)
        _skillNote.Visible = _play.HasHeroClass;
        StyleMode(_modePlace, _play.Mode == PlayMode.Place, canSwitch);
        _modeSummon.Visible = level is null;
        StyleMode(_modeSummon, _play.Mode == PlayMode.Summon, canSwitch && _play.Summon.CanBegin);
        StyleMode(_modeSkill, _play.Mode == PlayMode.Skill, canSwitch && skill.CanBegin);
        _modeSkill.Text = "技能：" + _play.SkillPresentation.Name;
        _skillNote.Text = _play.GameOver ? "本局已結束，不能再落子或施放技能。" : _play.Mode == PlayMode.Summon ? _play.Summon.Text : _play.Mode == PlayMode.Skill ? _play.SkillPresentation.Help : skill.Text;
        _directionRow.Visible = _play.Mode == PlayMode.Skill && _play.IsMagicHand;
        var directions = _play.PushDirections;
        foreach (var (direction, button) in _directions)
            StyleMode(button, _play.SelectedDirection == direction, canSwitch && directions.Any(d => d.Direction == direction && d.Result.IsLegal));

        _endTurn.Enabled = !_play.GameOver && !_play.Locked;
        _undo.Enabled = _play.CanUndo;
        _restartStage.Visible = level is not null;

        _log.BeginUpdate();
        _log.Items.Clear();
        foreach (var line in _play.Log) _log.Items.Add(line);
        _log.EndUpdate();
        if (_log.Items.Count > 0) _log.TopIndex = _log.Items.Count - 1;
        _board.Invalidate();
    }

    protected override void Dispose(bool disposing)
    {
        if (disposing) _play.Changed -= Refresh_;
        base.Dispose(disposing);
    }
}

internal sealed class NewGameDialog : Form
{
    private readonly List<(RadioButton Radio, int Level)> _levels = [];
    private readonly RadioButton _free = new() { Text = "自由對局（本機雙人，7×7）", Dock = DockStyle.Top, Height = 32 };
    private readonly ComboBox _rule = new() { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Top, Enabled = false };
    private readonly ComboBox _mage = new() { DropDownStyle = ComboBoxStyle.DropDownList, Dock = DockStyle.Top, Enabled = false };

    /// <summary>The chosen tutorial level number, or null for free play.</summary>
    public int? TutorialLevel => _levels.Where(l => l.Radio.Checked).Select(l => (int?)l.Level).FirstOrDefault();

    public RuleConfig Config => LocalMatch.Config(_rule.SelectedIndex, _mage.SelectedIndex == 1 ? MageSkill.Seal : MageSkill.MagicHand);

    public NewGameDialog(bool tutorialAvailable)
    {
        Text = "新局／選模式";
        FormBorderStyle = FormBorderStyle.FixedDialog;
        StartPosition = FormStartPosition.CenterParent;
        MaximizeBox = MinimizeBox = false;
        Padding = new Padding(12);

        foreach (var level in LevelCatalog.Levels)
        {
            var hint = level.Number == 1 ? "（建議先玩這個）" : "";
            var radio = new RadioButton { Text = $"新手教學：第 {level.Number} 關 {level.Title}{hint}", Dock = DockStyle.Top, Height = 32, Enabled = tutorialAvailable };
            _levels.Add((radio, level.Number));
        }
        ClientSize = new Size(470, 175 + 32 * (_levels.Count + 1));

        _rule.Items.AddRange([
            "每回合行動 2 次，先手第一回合 1 次（暫定預設）",
            "每回合行動 2 次，先手第一回合也 2 次（基線）",
            "每回合行動 1 次（對照）",
        ]);
        _rule.SelectedIndex = 0;
        _mage.Items.AddRange(["法師：魔法之手（預設，可推雙方普通士兵）", "法師：封印（比較選項）"]);
        _mage.SelectedIndex = 0;
        if (_levels.Count > 0) _levels[0].Radio.Checked = tutorialAvailable;
        _free.Checked = !tutorialAvailable;
        _free.CheckedChanged += (_, _) => _rule.Enabled = _mage.Enabled = _free.Checked;
        _rule.Enabled = _mage.Enabled = _free.Checked;

        var ok = new Button { Text = "開始", DialogResult = DialogResult.OK, Dock = DockStyle.Bottom, Height = 40 };
        Controls.Add(ok);
        Controls.Add(_mage);
        Controls.Add(_rule);
        Controls.Add(_free);
        foreach (var (radio, _) in Enumerable.Reverse(_levels)) Controls.Add(radio);   // last added docks on top
        AcceptButton = ok;
    }
}

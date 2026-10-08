using TacticalGo.Domain;

namespace TacticalGo.Play;

/// <summary>Two public, sequential choices; the game starts only after both are confirmed.</summary>
internal sealed class ClassPickDialog : Form
{
    private readonly Label _title = new() { Dock = DockStyle.Top, Height = 60, TextAlign = ContentAlignment.MiddleCenter };
    private readonly Label _first = new() { Dock = DockStyle.Bottom, Height = 42, TextAlign = ContentAlignment.MiddleCenter };
    private readonly RuleConfig _config;
    private bool _pickingTwo;
    public HeroClass ClassOne { get; private set; } = HeroClass.None;
    public HeroClass ClassTwo { get; private set; } = HeroClass.None;

    public ClassPickDialog(RuleConfig config)
    {
        _config = config;
        Text = "選職業・雙方公開輪流選擇";
        Font = new Font("Microsoft JhengHei UI", 11f);
        ClientSize = new Size(610, 300);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = MinimizeBox = false;
        StartPosition = FormStartPosition.CenterParent;
        var cards = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 3, Padding = new Padding(12) };
        foreach (var hero in new[] { HeroClass.Warrior, HeroClass.Mage, HeroClass.Rogue })
        {
            cards.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100f / 3));
            var ability = hero switch { HeroClass.Warrior => "築壘：增加兩兵", HeroClass.Mage => "法師技能", _ => "換位：交換位置" };
            var card = new Button { Dock = DockStyle.Fill, Margin = new Padding(6), Text = $"{EventText.ClassName(hero)}\n\n召喚 {_config.SummonCost(hero)} Mana\n{ability}\n技能 1 行動＋{_config.SkillManaCost} Mana" };
            card.Click += (_, _) => Choose(hero);
            cards.Controls.Add(card);
        }
        var cancel = new Button { Text = "取消新局", Dock = DockStyle.Bottom, Height = 36, DialogResult = DialogResult.Cancel };
        Controls.Add(cards);
        Controls.Add(_title);
        Controls.Add(_first);
        Controls.Add(cancel);
        CancelButton = cancel;
        _title.Text = "① 黑方先選職業（雙方可選同一職業）";
    }

    internal void Choose(HeroClass hero)
    {
        if (hero is not (HeroClass.Warrior or HeroClass.Mage or HeroClass.Rogue)) throw new ArgumentOutOfRangeException(nameof(hero));
        if (!_pickingTwo)
        {
            ClassOne = hero;
            _pickingTwo = true;
            _first.Text = $"黑方已選：{EventText.ClassName(hero)}";
            _title.Text = "② 白方選職業（黑方的選擇已公開）";
        }
        else
        {
            ClassTwo = hero;
            DialogResult = DialogResult.OK;
            Close();
        }
    }
}

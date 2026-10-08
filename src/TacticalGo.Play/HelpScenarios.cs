using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

/// <summary>One page of the "how to play" window. The diagram is a real engine position, driven by the real controller.</summary>
public sealed record HelpPage(string Title, string Caption, GameState? Position, Point? Click);

/// <summary>
/// The help diagrams are small separate boards (labelled as examples, not the current game). They are built with the engine
/// and shown through <see cref="PlayController"/>, so liberties, previews and refusal reasons come from the same code as real play.
/// </summary>
public static class HelpScenarios
{
    private const int Size = 5;

    private static string Pad(params string[] rows)
    {
        var cleaned = rows.Select(r => new string(r.Where(c => !char.IsWhiteSpace(c)).ToArray())).ToList();
        while (cleaned.Count < Size) cleaned.Add("");
        return string.Join('\n', cleaned.Select(r => r.PadRight(Size, '.')));
    }

    private static GameState Position(RuleConfig config, params string[] rows) =>
        GameSetup.FromDiagram(config, Pad(rows), HeroClass.None, HeroClass.None, Player.One, ap: config.ApPerTurn);

    public static IReadOnlyList<HelpPage> Pages(RuleConfig config)
    {
        var first = config.FirstTurnApResolved;
        var turnText = first != config.ApPerTurn
            ? $"每回合 {config.ApPerTurn} AP（先手第一回合只有 {first} AP）。"
            : $"每回合 {config.ApPerTurn} AP。";

        return
        [
            new("1／5　怎樣才算贏",
                "把對方的「主」圍到沒有生存空格，就立刻獲勝。\n示意圖：白主將只剩 1 個生存空格，黑方下在紅點就贏。",
                Position(config, ". x", "x O x"), new Point(1, 2)),
            new("2／5　什麼是「生存空格」",
                "棋子上下左右的空格叫生存空格；相連的同色棋共用同一組。\n點棋子可看到：藍圈 = 這一串，藍點 = 生存空格，數字徽章 = 還剩幾個。",
                Position(config, "", ". x x o"), new Point(1, 1)),
            new("3／5　回合與行動點 AP",
                turnText + "\n每放一顆子花 1 AP；AP 用完自動換對手，也可以按「結束回合」。",
                null, null),
            new("4／5　落子要點兩次",
                "第一次點空交叉點 = 只是選取（顯示半透明棋與「再點一次落子」）。\n再點同一點，或按「確認落子」才真的下。想反悔按「取消選取」。",
                Position(config, "", ". . x"), new Point(2, 2)),
            new("5／5　不能下的地方",
                "不能下時會出現紅色 ✕ 與原因，並圈出相關的子。\n這裡黑棋下去自己沒有生存空格（自殺）。",
                Position(config, ". o", "o"), new Point(0, 0)),
        ];
    }
}

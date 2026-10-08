using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

/// <summary>Plain-language descriptions of engine events and rejection reasons. Presentation only: it never decides anything.</summary>
public static class EventText
{
    public static string Name(Player p) => p == Player.One ? "黑方" : "白方";

    public static string At(Point p) => $"({p.X},{p.Y})";

    public static string KindName(PieceKind kind) => kind switch
    {
        PieceKind.Commander => "主將",
        PieceKind.Hero => "英雄",
        _ => "士兵",
    };

    public static string ClassName(HeroClass c) => c switch
    {
        HeroClass.Warrior => "戰士",
        HeroClass.Mage => "法師",
        HeroClass.Rogue => "盜賊",
        _ => "無職業",
    };

    public static char ClassGlyph(HeroClass c) => c switch
    {
        HeroClass.Warrior => '戰',
        HeroClass.Mage => '法',
        HeroClass.Rogue => '盜',
        _ => '英',
    };

    /// <summary>Full-sentence reason for a rejected action (the engine's own text is English and kept only as a fallback).</summary>
    public static string Reason(ValidationResult result) => result.Reason switch
    {
        IllegalReason.Suicide => "這樣會讓你自己的棋沒有生存空格（自殺），而且提不掉對方的子。",
        IllegalReason.Ko => "打劫：不能讓盤面回到之前出現過的樣子，請先下別處。",
        IllegalReason.Occupied => "這個位置已經有棋子。",
        IllegalReason.OutOfBounds => "這個位置在棋盤外。",
        IllegalReason.Sealed => "這個點被對手封印，這回合不能放置。",
        IllegalReason.GameOver => "對局已經結束。",
        IllegalReason.NoActionPoints => "這回合沒有行動點了。",
        IllegalReason.NotEnoughMana => "Mana 不夠。",
        IllegalReason.NoHeroClass => "你沒有職業，不能召喚英雄。",
        IllegalReason.HeroAlreadyOnBoard => "場上已經有你的英雄。",
        IllegalReason.HeroAlreadySummoned => "你的英雄已經陣亡，第一版不能再召喚。",
        IllegalReason.NotAdjacentToFriend => "英雄必須放在己方棋子的上下左右旁邊。",
        IllegalReason.WrongClass => "這個技能不屬於你的職業。",
        IllegalReason.NoHeroOnBoard => "你的英雄不在場上，不能施放技能。",
        IllegalReason.SkillAlreadyUsed => "每回合只能施放一次技能。",
        IllegalReason.OutOfRange => "超出技能範圍。",
        IllegalReason.InvalidTarget => "這不是合法的技能目標。",
        IllegalReason.DuplicateTarget => "兩個目標不能是同一點。",
        _ => result.Message,
    };

    /// <summary>A few words, short enough to sit on the board next to the point.</summary>
    public static string ShortReason(ValidationResult result) => result.Reason switch
    {
        IllegalReason.Suicide => "自殺：沒有生存空格",
        IllegalReason.Ko => "打劫：不能重複盤面",
        IllegalReason.Occupied => "已有棋子",
        IllegalReason.Sealed => "被封印",
        IllegalReason.OutOfBounds => "棋盤外",
        _ => "不能下",
    };

    public static IEnumerable<string> Describe(IEnumerable<ActionEvent> events)
    {
        foreach (var e in events)
        {
            switch (e)
            {
                case PiecePlaced p:
                    yield return $"{Name(p.Player)} 在 {At(p.At)} 放置{KindName(p.Kind)}";
                    break;
                case PiecesSwapped s:
                    yield return $"{Name(s.Player)} 換位：{At(s.A)} ⇄ {At(s.B)}";
                    break;
                case SealPlaced s:
                    yield return $"{Name(s.Caster)} 封印 {At(s.At)}（{Name(s.BlockedPlayer)}下一回合不能放置）";
                    break;
                case SealExpired s:
                    yield return $"封印解除 {At(s.At)}";
                    break;
                case PiecesCaptured c:
                    var list = string.Join(" ", c.Pieces.Select(x => At(x.At)));
                    var note = c.Pieces.Any(x => x.Piece.Kind == PieceKind.Commander) ? "，含主將" :
                               c.Pieces.Any(x => x.Piece.Kind == PieceKind.Hero) ? "，含英雄" : "";
                    yield return $"{Name(c.Capturer)} 提掉 {c.Pieces.Count} 子：{list}{note}";
                    break;
                case ResourcesSpent r when r.Mana > 0:
                    yield return $"  花費 {r.Mana} Mana";
                    break;
                case TurnEnded t:
                    yield return $"{Name(t.Player)} 結束回合";
                    break;
                case TurnStarted t:
                    yield return $"— 第 {Round(t.Ply)} 輪・{Name(t.Player)}回合開始（ply {t.Ply}）AP {t.Ap}";
                    break;
                case GameWon w:
                    yield return $"★ {Name(w.Winner)} 獲勝：提掉敵方主將";
                    break;
                case GameDrawn d:
                    yield return $"和局：{d.Reason}";
                    break;
            }
        }
    }

    /// <summary>Display round: black and white each play one ply per round. The engine's ply value is unchanged.</summary>
    public static int Round(int ply) => (ply + 1) / 2;
}

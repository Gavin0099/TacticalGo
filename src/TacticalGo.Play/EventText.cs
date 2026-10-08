using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play;

/// <summary>Plain-language descriptions of engine events. Presentation only: it never decides anything.</summary>
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
                    yield return $"— {Name(t.Player)} 回合開始（第 {t.Ply} 手）AP {t.Ap}，Mana {t.Mana}";
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
}

using TacticalGo.Domain;

namespace TacticalGo.Play;

/// <summary>Labels and input instructions only; legality and outcomes stay in Domain.</summary>
public sealed record SkillPresentation(string Name, string Help)
{
    public string ConfirmLabel => $"✔ 確定{Name}";
    public static SkillPresentation For(GameState state) => state.HeroClassOf(state.Current) switch
    {
        HeroClass.Warrior => new("築壘", "築壘：依序選戰士上下左右相鄰的兩個不同空點，預覽後確認。"),
        HeroClass.Rogue => new("換位", "換位：選一顆與盜賊上下左右相鄰的敵方士兵（不能是主將或英雄）。"),
        HeroClass.Mage => new("封印", "法師技能介面尚未開放。"),
        _ => new("技能", "尚未選擇職業。"),
    };
}

using TacticalGo.Domain;

namespace TacticalGo.Play;

/// <summary>Labels and input instructions only; legality and outcomes stay in Domain.</summary>
public sealed record SkillPresentation(string Name, string Help)
{
    public string ConfirmLabel => $"✔ 確定{Name}";
    public static SkillPresentation For(GameState state) => For(state.HeroClassOf(state.Current), state.Config);
    public static SkillPresentation For(HeroClass hero, RuleConfig config) => hero switch
    {
        HeroClass.Warrior => new("築壘", "築壘：依序選戰士上下左右相鄰的兩個不同空點，預覽後確認。"),
        HeroClass.Rogue => new("換位", "換位：選一顆與盜賊上下左右相鄰的敵方士兵（不能是主將或英雄）。"),
        HeroClass.Mage when config.MageSkill == MageSkill.MagicHand => new("魔法之手", $"魔法之手：選距法師 ≤{config.MagicHandRange} 的雙方普通士兵，再選推動方向。主將與英雄不能推。"),
        HeroClass.Mage => new("封印", $"封印：選距法師 ≤{config.SealRange} 的空點，阻止對手下一回合在該點放置。"),
        _ => new("技能", "尚未選擇職業。"),
    };
}

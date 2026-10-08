namespace TacticalGo.Domain;

/// <summary>All tunable Draft numbers live here so balance changes never touch engine code.</summary>
public sealed record RuleConfig
{
    public int BoardSize { get; init; } = 9;
    public int ApPerTurn { get; init; } = 2;

    /// <summary>
    /// AP for the very first turn of the game; null = same as <see cref="ApPerTurn"/>.
    /// Draft default 1 (first player compensation, see docs/S0_AP_GATE.md). Use <see cref="TwoApBaseline"/> for the original rule.
    /// </summary>
    public int? FirstTurnAp { get; init; } = 1;

    /// <summary>The original un-compensated rule (first turn also gets full AP), kept as the comparison baseline.</summary>
    public static RuleConfig TwoApBaseline => new() { FirstTurnAp = null };

    /// <summary>If false (Draft default) a hero that was captured cannot be summoned again.</summary>
    public bool AllowResummon { get; init; }

    public int InitialMana { get; init; } = 3;
    public int ManaGainPerTurn { get; init; } = 1;
    public int ManaCap { get; init; } = 6;

    public int SkillManaCost { get; init; } = 2;
    public int SummonCostWarrior { get; init; } = 2;
    public int SummonCostMage { get; init; } = 3;
    public int SummonCostRogue { get; init; } = 2;

    public int SealRange { get; init; } = 2;

    /// <summary>Owner-selected Mage default; Seal remains available as an explicit comparison baseline.</summary>
    public MageSkill MageSkill { get; init; } = MageSkill.MagicHand;
    public int MagicHandRange { get; init; } = 2;

    /// <summary>Turn limit (plies, one ply = one player's turn). Reaching it without a decapitation is a draw.</summary>
    public int MaxPlies { get; init; } = 100;

    public Point CommanderOneStart { get; init; } = new(4, 7);
    public Point CommanderTwoStart { get; init; } = new(4, 1);

    public int FirstTurnApResolved => FirstTurnAp ?? ApPerTurn;

    public int SummonCost(HeroClass heroClass) => heroClass switch
    {
        HeroClass.Warrior => SummonCostWarrior,
        HeroClass.Mage => SummonCostMage,
        HeroClass.Rogue => SummonCostRogue,
        _ => int.MaxValue,
    };
}

using TacticalGo.Domain;

namespace TacticalGo.Play;

/// <summary>Owner-approved Windows playtest setup. Reference-engine defaults and old fixtures remain independent.</summary>
public static class LocalMatch
{
    public static RuleConfig Config(int comparison = 0, MageSkill mageSkill = MageSkill.MagicHand)
    {
        var rules = comparison switch
        {
            1 => RuleConfig.TwoApBaseline,
            2 => RuleConfig.TwoApBaseline with { ApPerTurn = 1, MaxPlies = 200 },
            _ => new RuleConfig(),
        };
        return rules with { BoardSize = 7, CommanderOneStart = new(3, 5), CommanderTwoStart = new(3, 1), MageSkill = mageSkill };
    }
}

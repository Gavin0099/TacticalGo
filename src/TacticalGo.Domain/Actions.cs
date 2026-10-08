namespace TacticalGo.Domain;

/// <summary>One atomic player action. Each costs 1 AP except <see cref="EndTurn"/>.</summary>
public abstract record GameAction;

public sealed record PlaceSoldier(Point At) : GameAction;

public sealed record SummonHero(Point At) : GameAction;

/// <summary>Warrior 築壘: two soldiers on two empty points orthogonally adjacent to the Warrior.</summary>
public sealed record CastBastion(Point First, Point Second) : GameAction;

/// <summary>Mage 封印: opponent may not place on <see cref="At"/> during their next turn.</summary>
public sealed record CastSeal(Point At) : GameAction;

/// <summary>Mage 魔法之手: push one ordinary soldier of either player to the adjacent empty point in the chosen direction.</summary>
public sealed record CastMagicHand(Point Target, PushDirection Direction) : GameAction;

/// <summary>Rogue 換位: swap places with an adjacent enemy soldier.</summary>
public sealed record CastSwap(Point Target) : GameAction;

public sealed record EndTurn : GameAction;

public enum IllegalReason
{
    None,
    GameOver,
    NoActionPoints,
    OutOfBounds,
    Occupied,
    Sealed,
    Suicide,
    Ko,
    NotEnoughMana,
    NoHeroClass,
    HeroAlreadyOnBoard,
    NotAdjacentToFriend,
    HeroAlreadySummoned,
    WrongClass,
    NoHeroOnBoard,
    SkillAlreadyUsed,
    OutOfRange,
    InvalidTarget,
    DuplicateTarget,
    SkillNotSelected,
    InvalidDirection,
}

public sealed record ValidationResult(bool IsLegal, IllegalReason Reason, string Message)
{
    public static readonly ValidationResult Ok = new(true, IllegalReason.None, "OK");

    public static ValidationResult Fail(IllegalReason reason, string message) => new(false, reason, message);
}

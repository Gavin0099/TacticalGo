using System.Text;

namespace TacticalGo.Domain;

/// <summary>A Mage seal: <see cref="BlockedPlayer"/> may not place anything on <see cref="At"/> until the end of their own next turn.</summary>
public sealed record SealEffect(Point At, Player Caster, Player BlockedPlayer);

/// <summary>Persistent (shared-tail) list of board hashes seen so far, for positional superko.</summary>
internal sealed class PositionHistory
{
    private readonly ulong _hash;
    private readonly PositionHistory? _previous;

    public PositionHistory(ulong hash, PositionHistory? previous)
    {
        _hash = hash;
        _previous = previous;
    }

    public bool Contains(ulong hash)
    {
        for (var node = this; node is not null; node = node._previous)
            if (node._hash == hash) return true;
        return false;
    }
}

/// <summary>
/// Whole game state. The engine never mutates a state it was given: every applied action works on a
/// <see cref="Clone"/>, so a rejected action cannot leave partial changes behind.
/// </summary>
public sealed class GameState
{
    private readonly int[] _mana;
    private readonly HeroClass[] _classes;
    private readonly bool[] _heroSummoned;

    public RuleConfig Config { get; }
    public Board Board { get; internal set; }
    public Player Current { get; internal set; }
    public int Ply { get; internal set; }
    public int ApRemaining { get; internal set; }
    public bool SkillUsedThisTurn { get; internal set; }
    public GameStatus Status { get; internal set; }
    public Player? Winner { get; internal set; }
    public IReadOnlyList<SealEffect> Seals { get; internal set; }
    internal PositionHistory History { get; set; }

    internal GameState(RuleConfig config, Board board, HeroClass classOne, HeroClass classTwo)
    {
        Config = config;
        Board = board;
        _mana = new int[2];
        _classes = [classOne, classTwo];
        _heroSummoned = new bool[2];
        Seals = [];
        History = new PositionHistory(board.ComputeHash(), null);
    }

    private GameState(GameState other)
    {
        Config = other.Config;
        Board = other.Board.Clone();
        _mana = (int[])other._mana.Clone();
        _classes = (HeroClass[])other._classes.Clone();
        _heroSummoned = (bool[])other._heroSummoned.Clone();
        Current = other.Current;
        Ply = other.Ply;
        ApRemaining = other.ApRemaining;
        SkillUsedThisTurn = other.SkillUsedThisTurn;
        Status = other.Status;
        Winner = other.Winner;
        Seals = other.Seals;
        History = other.History;
    }

    public GameState Clone() => new(this);

    public int ManaOf(Player player) => _mana[(int)player];

    internal void SetMana(Player player, int value) => _mana[(int)player] = value;

    public HeroClass HeroClassOf(Player player) => _classes[(int)player];

    /// <summary>True once this player's hero has been on the board (even if it was captured since).</summary>
    public bool HasSummonedHero(Player player) => _heroSummoned[(int)player];

    internal void MarkHeroSummoned(Player player) => _heroSummoned[(int)player] = true;

    public bool IsSealedFor(Point at, Player player) =>
        Seals.Any(s => s.At == at && s.BlockedPlayer == player);

    /// <summary>Every field that can change as a result of an action; used by tests to prove rollback.</summary>
    public string Fingerprint()
    {
        var sb = new StringBuilder();
        sb.Append(Board).Append('\n');
        sb.Append($"cur={Current} ply={Ply} ap={ApRemaining} skill={SkillUsedThisTurn} status={Status} winner={Winner}\n");
        sb.Append($"mana={_mana[0]}/{_mana[1]} classes={_classes[0]}/{_classes[1]} summoned={_heroSummoned[0]}/{_heroSummoned[1]}\n");
        sb.Append("seals=").Append(string.Join(';', Seals.Select(s => $"{s.At}:{s.BlockedPlayer}")));
        return sb.ToString();
    }
}

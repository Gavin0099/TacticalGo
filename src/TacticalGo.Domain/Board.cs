namespace TacticalGo.Domain;

public sealed class Board
{
    private readonly Piece?[] _cells;

    public int Size { get; }

    public Board(int size)
    {
        Size = size;
        _cells = new Piece?[size * size];
    }

    private Board(int size, Piece?[] cells)
    {
        Size = size;
        _cells = cells;
    }

    public Board Clone() => new(Size, (Piece?[])_cells.Clone());

    public bool InBounds(Point p) => p.X >= 0 && p.Y >= 0 && p.X < Size && p.Y < Size;

    public Piece? this[Point p]
    {
        get => _cells[p.Y * Size + p.X];
        set => _cells[p.Y * Size + p.X] = value;
    }

    public bool IsEmpty(Point p) => this[p] is null;

    public IEnumerable<Point> AllPoints()
    {
        for (var y = 0; y < Size; y++)
            for (var x = 0; x < Size; x++)
                yield return new Point(x, y);
    }

    public IEnumerable<Point> Neighbors(Point p)
    {
        if (p.Y > 0) yield return new Point(p.X, p.Y - 1);
        if (p.X < Size - 1) yield return new Point(p.X + 1, p.Y);
        if (p.Y < Size - 1) yield return new Point(p.X, p.Y + 1);
        if (p.X > 0) yield return new Point(p.X - 1, p.Y);
    }

    public Point? FindCommander(Player owner) => Find(owner, PieceKind.Commander);

    public Point? FindHero(Player owner) => Find(owner, PieceKind.Hero);

    private Point? Find(Player owner, PieceKind kind)
    {
        for (var i = 0; i < _cells.Length; i++)
        {
            if (_cells[i] is { } piece && piece.Owner == owner && piece.Kind == kind)
                return new Point(i % Size, i / Size);
        }
        return null;
    }

    /// <summary>Deterministic 64-bit Zobrist-style hash of piece placement (used for superko).</summary>
    public ulong ComputeHash()
    {
        ulong h = 0;
        for (var i = 0; i < _cells.Length; i++)
        {
            if (_cells[i] is { } piece)
            {
                var code = 1UL + (ulong)piece.Owner * 3 + (ulong)piece.Kind; // 1..6
                h ^= SplitMix64(((ulong)i << 3) + code);
            }
        }
        return h;
    }

    private static ulong SplitMix64(ulong x)
    {
        x += 0x9E3779B97F4A7C15UL;
        x = (x ^ (x >> 30)) * 0xBF58476D1CE4E5B9UL;
        x = (x ^ (x >> 27)) * 0x94D049BB133111EBUL;
        return x ^ (x >> 31);
    }

    /// <summary>Stable text form, one row per line, for fingerprints and debugging.</summary>
    public override string ToString() => BoardText.Render(this);
}

namespace TacticalGo.Domain;

public sealed record CaptureResolution(IReadOnlyList<CapturedPiece> Captured, bool MoverHasDeadGroup);

/// <summary>Pure Go mechanics: groups, liberties, capture/suicide resolution. Knows nothing about turns or classes.</summary>
public static class BoardRuleEngine
{
    /// <summary>Orthogonally connected same-owner pieces (commander/hero/soldier all connect).</summary>
    public static List<Point> GetGroup(Board board, Point start)
    {
        var owner = board[start]?.Owner ?? throw new ArgumentException($"No piece at {start}.");
        var group = new List<Point> { start };
        var seen = new HashSet<Point> { start };
        for (var i = 0; i < group.Count; i++)
        {
            foreach (var n in board.Neighbors(group[i]))
            {
                if (board[n] is { } p && p.Owner == owner && seen.Add(n))
                    group.Add(n);
            }
        }
        return group;
    }

    public static HashSet<Point> GetLiberties(Board board, IEnumerable<Point> group)
    {
        var libs = new HashSet<Point>();
        foreach (var p in group)
            foreach (var n in board.Neighbors(p))
                if (board.IsEmpty(n)) libs.Add(n);
        return libs;
    }

    public static int CountLiberties(Board board, Point at) => GetLiberties(board, GetGroup(board, at)).Count;

    /// <summary>
    /// Standard order: (1) remove every opponent group without liberties, (2) report whether any mover group is
    /// still without liberties (= suicide, the caller must reject the whole action). Mutates <paramref name="board"/>.
    /// </summary>
    public static CaptureResolution ResolveCaptures(Board board, Player mover)
    {
        var captured = new List<CapturedPiece>();

        // Pass 1: opponent groups without liberties are removed first (a capture may free the mover's own stones).
        foreach (var group in FindDeadGroups(board, owner => owner != mover))
        {
            foreach (var g in group.OrderBy(q => q.Y).ThenBy(q => q.X))
            {
                captured.Add(new CapturedPiece(g, board[g]!.Value));
                board[g] = null;
            }
        }

        // Pass 2: only now can the mover's own groups be judged.
        var moverDead = FindDeadGroups(board, owner => owner == mover).Count > 0;
        return new CaptureResolution(captured, moverDead);
    }

    private static List<List<Point>> FindDeadGroups(Board board, Func<Player, bool> ownerFilter)
    {
        var size = board.Size;
        var visited = new bool[size * size];
        var dead = new List<List<Point>>();
        foreach (var p in board.AllPoints())
        {
            if (board[p] is not { } piece || visited[p.Y * size + p.X]) continue;
            var group = GetGroup(board, p);
            foreach (var g in group) visited[g.Y * size + g.X] = true;
            if (ownerFilter(piece.Owner) && GetLiberties(board, group).Count == 0) dead.Add(group);
        }
        return dead;
    }
}

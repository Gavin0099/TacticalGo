using TacticalGo.Domain;
using Point = TacticalGo.Domain.Point;

namespace TacticalGo.Play.Tests;

/// <summary>
/// Deliberately small, level-specific search (not a general solver). The tutorial opponent only passes, so only the player's
/// action sequences matter. It answers: can the player win, in how many rounds, with and without the hero skill, and which
/// first-round action sequences win. All moves go through the real engine.
///
/// Candidate placements are the liberties of the enemy commander's group (the "narrow" mode). Under a passive opponent no other
/// stone can shorten a win; the "wide" mode adds every empty point within 2 of an enemy piece to cross-check that claim.
/// </summary>
internal static class LevelSearch
{
    /// <summary>Fewest rounds (player turns) after which the player has captured the commander, or null within the limit.</summary>
    public static int? MinRoundsToWin(GameState start, bool allowSkill, int maxRounds, bool wide = false)
    {
        var frontier = new List<GameState> { start };
        for (var round = 1; round <= maxRounds; round++)
        {
            var next = new Dictionary<string, GameState>();
            foreach (var state in frontier)
            {
                var found = false;
                Expand(state, allowSkill, wide, [], end =>
                {
                    if (end.Status == GameStatus.Won && end.Winner == Player.One) found = true;
                    else if (end.Status == GameStatus.Ongoing)
                    {
                        var after = PassOpponent(end);
                        next.TryAdd(Key(after), after);
                    }
                });
                if (found) return round;
            }
            frontier = [.. next.Values];
        }
        return null;
    }

    /// <summary>Every ordered action sequence that wins within the player's first turn (e.g. "CastSwap (3,2) → PlaceSoldier (4,1)").</summary>
    public static List<string> WinningFirstTurnSequences(GameState start, bool allowSkill, bool wide = false)
    {
        var wins = new List<string>();

        void Go(GameState s, List<GameAction> path)
        {
            foreach (var action in Candidates(s, allowSkill, wide))
            {
                var outcome = GameEngine.Apply(s, action);
                if (!outcome.Success) continue;
                var p = path.Append(action).ToList();
                if (outcome.State.Status == GameStatus.Won && outcome.State.Winner == Player.One)
                    wins.Add(string.Join(" → ", p.Select(Describe)));
                else if (outcome.State.Status == GameStatus.Ongoing && outcome.State.Current == Player.One)
                    Go(outcome.State, p);
            }
        }

        Go(start, []);
        return wins;
    }

    private static string Describe(GameAction a) => a switch
    {
        PlaceSoldier p => $"Place {p.At}",
        CastSwap s => $"Swap {s.Target}",
        _ => a.ToString() ?? "?",
    };

    private static void Expand(GameState s, bool allowSkill, bool wide, HashSet<string> seen, Action<GameState> onTurnEnd)
    {
        IEnumerable<GameAction> actions = Candidates(s, allowSkill, wide);
        if (s.ApRemaining < s.Config.ApPerTurn) actions = actions.Append(new EndTurn());   // ending a turn with nothing done only wastes it

        foreach (var action in actions)
        {
            var outcome = GameEngine.Apply(s, action);
            if (!outcome.Success) continue;
            var n = outcome.State;
            if (n.Status != GameStatus.Ongoing || n.Current != Player.One) onTurnEnd(n);
            else if (seen.Add(Key(n))) Expand(n, allowSkill, wide, seen, onTurnEnd);
        }
    }

    private static IEnumerable<GameAction> Candidates(GameState s, bool allowSkill, bool wide)
    {
        var board = s.Board;
        IEnumerable<Point> points;
        if (wide)
        {
            var enemies = board.AllPoints().Where(p => board[p] is { } piece && piece.Owner == Player.Two).ToList();
            points = board.AllPoints().Where(p => board.IsEmpty(p) && enemies.Any(e => e.ManhattanTo(p) <= 2));
        }
        else
        {
            points = board.FindCommander(Player.Two) is { } c
                ? BoardRuleEngine.GetLiberties(board, BoardRuleEngine.GetGroup(board, c))
                : [];
        }

        foreach (var p in points.OrderBy(p => p.Y).ThenBy(p => p.X)) yield return new PlaceSoldier(p);

        if (allowSkill && board.FindHero(Player.One) is { } hero)
            foreach (var n in board.Neighbors(hero)) yield return new CastSwap(n);
    }

    private static GameState PassOpponent(GameState s)
    {
        while (s.Status == GameStatus.Ongoing && s.Current == Player.Two)
            s = GameEngine.Apply(s, new EndTurn()).State;
        return s;
    }

    private static string Key(GameState s) =>
        $"{s.Board.ComputeHash()}|{s.ManaOf(Player.One)}|{s.ApRemaining}|{s.SkillUsedThisTurn}|{s.Current}";
}

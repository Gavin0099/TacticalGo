using TacticalGo.Domain;

namespace TacticalGo.Sim;

public interface IBot
{
    GameAction Choose(GameState state);
}

public sealed class RandomBot(int seed) : IBot
{
    private readonly Random _rng = new(seed);

    public GameAction Choose(GameState state)
    {
        var legal = ActionValidator.GetLegalActions(state);
        return legal[_rng.Next(legal.Count)];
    }
}

/// <summary>
/// One-action lookahead: try every legal action on a copy, score the resulting position, take the best.
/// It understands liberties, atari and "can the opponent kill my commander next turn", nothing deeper.
/// Evidence from it is a rough probe, not a stand-in for human play (see docs/S0_AP_GATE.md).
/// </summary>
public sealed class HeuristicBot(int seed, double noise = 2.0) : IBot
{
    private readonly Random _rng = new(seed);

    public GameAction Choose(GameState state)
    {
        var me = state.Current;
        GameAction? best = null;
        var bestScore = double.NegativeInfinity;
        foreach (var action in ActionValidator.GetLegalActions(state))
        {
            var next = GameEngine.Apply(state, action).State;
            var score = Evaluate(next, me) + _rng.NextDouble() * noise;
            if (action is not EndTurn && action is not PlaceSoldier) score -= 0.5; // tiny reluctance to spend Mana
            if (score > bestScore)
            {
                bestScore = score;
                best = action;
            }
        }
        return best ?? new EndTurn();
    }

    public static double Evaluate(GameState s, Player me)
    {
        if (s.Status == GameStatus.Won) return s.Winner == me ? 1_000_000 : -1_000_000;
        if (s.Status == GameStatus.Drawn) return 0;

        var board = s.Board;
        var opp = me.Opponent();
        var score = 0.0;

        var visited = new HashSet<Point>();
        foreach (var p in board.AllPoints())
        {
            if (board[p] is not { } piece || !visited.Add(p)) continue;
            var group = BoardRuleEngine.GetGroup(board, p);
            foreach (var g in group) visited.Add(g);
            var libs = BoardRuleEngine.GetLiberties(board, group).Count;
            var sign = piece.Owner == me ? 1 : -1;
            score += sign * 8 * group.Count;               // material
            if (libs == 1) score -= sign * 14;              // atari hurts its owner
        }

        var myCommander = board.FindCommander(me);
        var oppCommander = board.FindCommander(opp);
        var myLibs = LibertiesOf(board, myCommander);
        var oppLibs = LibertiesOf(board, oppCommander);
        score += 6 * Math.Min(myLibs.Count, 8) - 7 * Math.Min(oppLibs.Count, 8);

        if (s.Current != me)
        {
            // Turn is over: can the opponent fill all my commander's liberties with their AP? A seal on one of them stops that.
            if (myLibs.Count <= s.ApRemaining && !myLibs.Any(l => s.IsSealedFor(l, opp))) score -= 5000;
        }
        else if (oppLibs.Count <= s.ApRemaining && !oppLibs.Any(l => s.IsSealedFor(l, me)))
        {
            score += 3000; // I can finish the commander with the AP I still have
        }

        return score;
    }

    private static HashSet<Point> LibertiesOf(Board board, Point? at) =>
        at is { } p ? BoardRuleEngine.GetLiberties(board, BoardRuleEngine.GetGroup(board, p)) : [];
}

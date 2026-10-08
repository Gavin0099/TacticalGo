using TacticalGo.Domain;

namespace TacticalGo.Sim;

public sealed record GameResult(
    Player? Winner,
    int Plies,
    int ActionsInWinningTurn,
    bool Ended,
    HeroClass ClassOne,
    HeroClass ClassTwo,
    int SkillsCast);

public static class Runner
{
    public static GameResult PlayOne(RuleConfig config, HeroClass classOne, HeroClass classTwo, IBot botOne, IBot botTwo)
    {
        var session = new GameSession(GameSetup.NewGame(config, classOne, classTwo));
        var actionsThisTurn = 0;
        var skills = 0;

        while (session.State.Status == GameStatus.Ongoing)
        {
            var state = session.State;
            var bot = state.Current == Player.One ? botOne : botTwo;
            var action = bot.Choose(state);
            var plyBefore = state.Ply;
            var outcome = session.Apply(action);
            if (!outcome.Success)
                throw new InvalidOperationException($"Bot chose an illegal action {action}: {outcome.Validation.Message}");

            if (action is not EndTurn) actionsThisTurn++;
            if (action is CastBastion or CastSeal or CastSwap) skills++;
            if (session.State.Ply != plyBefore) actionsThisTurn = 0;
        }

        var final = session.State;
        return new GameResult(final.Winner, final.Ply, final.Winner is null ? 0 : actionsThisTurn, true, classOne, classTwo, skills);
    }

    public static List<GameResult> Batch(int games, Func<int, GameResult> play)
    {
        var results = new GameResult[games];
        Parallel.For(0, games, i => results[i] = play(i));
        return [.. results];
    }

    public static string Summarize(string label, IReadOnlyList<GameResult> r)
    {
        var n = r.Count;
        var p1 = r.Count(x => x.Winner == Player.One);
        var p2 = r.Count(x => x.Winner == Player.Two);
        var draws = n - p1 - p2;
        var wins = r.Where(x => x.Winner is not null).ToList();
        var medianPly = wins.Count == 0 ? 0 : wins.Select(x => x.Plies).OrderBy(x => x).ElementAt(wins.Count / 2);
        var earlyKill = wins.Count(x => x.Plies <= 6);
        var combo = wins.Count(x => x.ActionsInWinningTurn >= 2);
        string Pct(int k, int d) => d == 0 ? "  -  " : $"{100.0 * k / d,5:F1}%";
        return $"{label,-28} n={n,-5} P1 {Pct(p1, n)}  P2 {Pct(p2, n)}  draw {Pct(draws, n)}  " +
               $"median-kill-ply {medianPly,3}  kill<=ply6 {Pct(earlyKill, n)}  2-action-kills {Pct(combo, wins.Count)}";
    }
}

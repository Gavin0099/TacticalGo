namespace TacticalGo.Domain;

/// <summary>Public legality queries. Uses the same code path as applying, so what the UI shows is what the engine enforces.</summary>
public static class ActionValidator
{
    public static ValidationResult Validate(GameState state, GameAction action) =>
        ActionResolver.Prepare(state, action).Result;

    /// <summary>All legal actions for the current player, <see cref="EndTurn"/> included (last).</summary>
    public static List<GameAction> GetLegalActions(GameState state)
    {
        var legal = new List<GameAction>();
        if (state.Status != GameStatus.Ongoing) return legal;

        foreach (var candidate in Candidates(state))
            if (Validate(state, candidate).IsLegal) legal.Add(candidate);

        legal.Add(new EndTurn());
        return legal;
    }

    private static IEnumerable<GameAction> Candidates(GameState state)
    {
        if (state.ApRemaining < 1) yield break;

        var board = state.Board;
        var me = state.Current;
        var heroClass = state.HeroClassOf(me);
        var hero = board.FindHero(me);

        foreach (var p in board.AllPoints())
        {
            if (!board.IsEmpty(p)) continue;
            yield return new PlaceSoldier(p);
            if (heroClass != HeroClass.None && hero is null) yield return new SummonHero(p);
        }

        if (hero is not { } h) yield break;

        switch (heroClass)
        {
            case HeroClass.Warrior:
                var around = board.Neighbors(h).Where(board.IsEmpty).ToList();
                for (var i = 0; i < around.Count; i++)
                    for (var j = i + 1; j < around.Count; j++)
                        yield return new CastBastion(around[i], around[j]);
                break;
            case HeroClass.Mage:
                if (state.Config.MageSkill == MageSkill.Seal)
                {
                    foreach (var p in board.AllPoints())
                        if (board.IsEmpty(p) && h.ManhattanTo(p) is >= 1 && h.ManhattanTo(p) <= state.Config.SealRange)
                            yield return new CastSeal(p);
                }
                else if (state.Config.MageSkill == MageSkill.MagicHand)
                {
                    foreach (var p in board.AllPoints())
                        if (board[p] is { Kind: PieceKind.Soldier } &&
                            h.ManhattanTo(p) <= state.Config.MagicHandRange)
                            foreach (var direction in Enum.GetValues<PushDirection>())
                                yield return new CastMagicHand(p, direction);
                }
                break;
            case HeroClass.Rogue:
                foreach (var n in board.Neighbors(h))
                    yield return new CastSwap(n);
                break;
        }
    }
}

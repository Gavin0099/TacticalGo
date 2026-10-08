namespace TacticalGo.Domain;

/// <summary>Turn lifecycle on a state clone: start, end, seal expiry, mana gain, turn-limit draw.</summary>
internal static class TurnEngine
{
    public static void StartFirstTurn(GameState s, List<ActionEvent> events)
    {
        s.Current = Player.One;
        s.Ply = 1;
        s.ApRemaining = s.Config.FirstTurnApResolved;
        s.SkillUsedThisTurn = false;
        GainMana(s);
        events.Add(new TurnStarted(s.Current, s.Ply, s.ApRemaining, s.ManaOf(s.Current)));
    }

    public static void EndTurn(GameState s, List<ActionEvent> events)
    {
        events.Add(new TurnEnded(s.Current, s.Ply));

        var expired = s.Seals.Where(x => x.BlockedPlayer == s.Current).ToList();
        if (expired.Count > 0)
        {
            s.Seals = s.Seals.Where(x => x.BlockedPlayer != s.Current).ToList();
            events.AddRange(expired.Select(x => new SealExpired(x.At)));
        }

        if (s.Ply >= s.Config.MaxPlies)
        {
            s.Status = GameStatus.Drawn;
            events.Add(new GameDrawn($"Turn limit reached ({s.Config.MaxPlies} plies)."));
            return;
        }

        s.Current = s.Current.Opponent();
        s.Ply++;
        s.ApRemaining = s.Config.ApPerTurn;
        s.SkillUsedThisTurn = false;
        GainMana(s);
        events.Add(new TurnStarted(s.Current, s.Ply, s.ApRemaining, s.ManaOf(s.Current)));
    }

    private static void GainMana(GameState s) =>
        s.SetMana(s.Current, Math.Min(s.Config.ManaCap, s.ManaOf(s.Current) + s.Config.ManaGainPerTurn));
}

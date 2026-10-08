namespace TacticalGo.Domain;

public static class GameSetup
{
    public static GameState NewGame(RuleConfig config, HeroClass classOne, HeroClass classTwo)
    {
        var board = new Board(config.BoardSize);
        board[config.CommanderOneStart] = new Piece(Player.One, PieceKind.Commander);
        board[config.CommanderTwoStart] = new Piece(Player.Two, PieceKind.Commander);

        var state = new GameState(config, board, classOne, classTwo);
        state.SetMana(Player.One, config.InitialMana);
        state.SetMana(Player.Two, config.InitialMana);
        TurnEngine.StartFirstTurn(state, []);
        return state;
    }

    /// <summary>
    /// Mid-game scenario from a text diagram (see <see cref="BoardText"/>). Mana and AP are set exactly as given
    /// (no start-of-turn mana gain), so a scenario reads the same as what the test asserts.
    /// </summary>
    public static GameState FromDiagram(
        RuleConfig config,
        string diagram,
        HeroClass classOne = HeroClass.None,
        HeroClass classTwo = HeroClass.None,
        Player current = Player.One,
        int manaOne = 3,
        int manaTwo = 3,
        int? ap = null,
        int ply = 1,
        bool heroSummonedOne = false,
        bool heroSummonedTwo = false)
    {
        var board = BoardText.Parse(diagram);
        var state = new GameState(config with { BoardSize = board.Size }, board, classOne, classTwo)
        {
            Current = current,
            Ply = ply,
            ApRemaining = ap ?? config.ApPerTurn,
        };
        state.SetMana(Player.One, manaOne);
        state.SetMana(Player.Two, manaTwo);
        // A hero already standing on the board has, by definition, been summoned.
        if (heroSummonedOne || board.FindHero(Player.One) is not null) state.MarkHeroSummoned(Player.One);
        if (heroSummonedTwo || board.FindHero(Player.Two) is not null) state.MarkHeroSummoned(Player.Two);
        return state;
    }
}

/// <summary>A game plus its action log, so any game can be replayed move for move.</summary>
public sealed class GameSession
{
    private readonly List<GameAction> _log = [];

    public GameState State { get; private set; }
    public IReadOnlyList<GameAction> Log => _log;

    public GameSession(GameState initial) => State = initial;

    public ActionOutcome Apply(GameAction action)
    {
        var outcome = GameEngine.Apply(State, action);
        if (outcome.Success)
        {
            State = outcome.State;
            _log.Add(action);
        }
        return outcome;
    }

    /// <summary>Re-run a recorded action list from a fresh game; throws if any recorded action is rejected.</summary>
    public static GameSession Replay(RuleConfig config, HeroClass classOne, HeroClass classTwo, IEnumerable<GameAction> actions)
    {
        var session = new GameSession(GameSetup.NewGame(config, classOne, classTwo));
        foreach (var action in actions)
        {
            var outcome = session.Apply(action);
            if (!outcome.Success)
                throw new InvalidOperationException($"Replay rejected {action}: {outcome.Validation.Message}");
        }
        return session;
    }
}

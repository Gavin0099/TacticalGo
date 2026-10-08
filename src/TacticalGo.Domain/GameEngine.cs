namespace TacticalGo.Domain;

/// <summary>Public entry point: pure function from (state, action) to an outcome. The input state is never modified.</summary>
public static class GameEngine
{
    public static ActionOutcome Apply(GameState state, GameAction action) => ActionResolver.Apply(state, action);
}

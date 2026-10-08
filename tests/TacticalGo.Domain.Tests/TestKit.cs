using TacticalGo.Domain;
using Xunit;

namespace TacticalGo.Domain.Tests;

internal static class TestKit
{
    public static Point P(int x, int y) => new(x, y);

    /// <summary>Top-left aligned partial diagram, padded with '.' to a size×size board. Whitespace inside rows is ignored.</summary>
    public static string Pad(int size, params string[] rows)
    {
        var cleaned = rows.Select(r => new string(r.Where(c => !char.IsWhiteSpace(c)).ToArray())).ToList();
        while (cleaned.Count < size) cleaned.Add("");
        return string.Join('\n', cleaned.Select(r => r.PadRight(size, '.')));
    }

    public static GameState Scenario(
        string[] rows,
        HeroClass one = HeroClass.None,
        HeroClass two = HeroClass.None,
        Player current = Player.One,
        int manaOne = 3,
        int manaTwo = 3,
        int? ap = null,
        RuleConfig? config = null) =>
        GameSetup.FromDiagram(config ?? new RuleConfig(), Pad(9, rows), one, two, current, manaOne, manaTwo, ap);

    /// <summary>Apply actions in order and require each to succeed.</summary>
    public static GameState Play(GameState state, params GameAction[] actions)
    {
        foreach (var action in actions)
        {
            var outcome = GameEngine.Apply(state, action);
            Assert.True(outcome.Success, $"{action} rejected: {outcome.Validation.Message}");
            state = outcome.State;
        }
        return state;
    }

    /// <summary>Require the action to be rejected for <paramref name="reason"/> and to leave the input state untouched.</summary>
    public static void AssertRejected(GameState state, GameAction action, IllegalReason reason)
    {
        var before = state.Fingerprint();
        var outcome = GameEngine.Apply(state, action);
        Assert.False(outcome.Success);
        Assert.Equal(reason, outcome.Validation.Reason);
        Assert.Same(state, outcome.State);
        Assert.Empty(outcome.Events);
        Assert.Equal(before, state.Fingerprint());
        Assert.Equal(reason, ActionValidator.Validate(state, action).Reason);
    }

    public static string Render(GameState s) => BoardText.Render(s.Board);
}

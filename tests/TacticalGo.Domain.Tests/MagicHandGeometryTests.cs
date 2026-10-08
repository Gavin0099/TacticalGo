using TacticalGo.Domain;

namespace TacticalGo.Domain.Tests;

public class MagicHandGeometryTests
{
    [Fact]
    public void Adjacent_push_leaves_the_source_as_the_targets_liberty_in_a_minimal_edge_shape()
    {
        // Independent geometry check, written and run before implementing the skill.
        // A=(1,1), B=(1,0). B's other two neighbors are occupied; A must be its sole liberty.
        var original = BoardText.Parse("x.x\nHo.\n...");
        var trial = original.Clone();
        trial[new Point(1, 0)] = trial[new Point(1, 1)];
        trial[new Point(1, 1)] = null;

        var resolution = BoardRuleEngine.ResolveCaptures(trial, Player.One);

        Assert.Empty(resolution.Captured);
        Assert.False(resolution.MoverHasDeadGroup);
        Assert.Equal(new Piece(Player.Two, PieceKind.Soldier), trial[new Point(1, 0)]);
        Assert.Equal(new[] { new Point(1, 1) },
            BoardRuleEngine.GetLiberties(trial, BoardRuleEngine.GetGroup(trial, new Point(1, 0))));
        Assert.Null(trial[new Point(1, 1)]);
        Assert.Equal('o', BoardText.ToChar(original[new Point(1, 1)]));
    }
}

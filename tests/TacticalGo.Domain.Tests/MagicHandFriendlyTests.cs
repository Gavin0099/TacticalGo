using TacticalGo.Domain;
using static TacticalGo.Domain.Tests.TestKit;

namespace TacticalGo.Domain.Tests;

public class MagicHandFriendlyTests
{
    private static readonly RuleConfig Hand = new() { MageSkill = MageSkill.MagicHand };

    [Theory]
    [InlineData(Player.One, PushDirection.Up, 2, 1)]
    [InlineData(Player.One, PushDirection.Right, 3, 2)]
    [InlineData(Player.One, PushDirection.Down, 2, 3)]
    [InlineData(Player.One, PushDirection.Left, 1, 2)]
    [InlineData(Player.Two, PushDirection.Up, 2, 1)]
    [InlineData(Player.Two, PushDirection.Right, 3, 2)]
    [InlineData(Player.Two, PushDirection.Down, 2, 3)]
    [InlineData(Player.Two, PushDirection.Left, 1, 2)]
    public void Either_player_can_push_its_own_soldier_in_all_directions_with_unchanged_costs(
        Player player, PushDirection direction, int x, int y)
    {
        var s = player == Player.One
            ? GameSetup.FromDiagram(Hand, "....O\n.H...\n..x..\n.....\nX....", HeroClass.Mage)
            : GameSetup.FromDiagram(Hand, "....X\n.Q...\n..o..\n.....\nO....", HeroClass.None,
                HeroClass.Mage, Player.Two);
        var before = s.Fingerprint();
        var action = new CastMagicHand(P(2,2), direction); // Exactly range 2 for both casters.
        Assert.Contains(action, ActionValidator.GetLegalActions(s));
        var moved = GameEngine.Apply(s, action);
        Assert.True(moved.Success, moved.Validation.Message);
        Assert.Equal(before, s.Fingerprint());
        Assert.Null(moved.State.Board[P(2,2)]);
        Assert.Equal(new Piece(player, PieceKind.Soldier), moved.State.Board[P(x,y)]);
        Assert.Contains(P(2,2), BoardRuleEngine.GetLiberties(moved.State.Board,
            BoardRuleEngine.GetGroup(moved.State.Board, P(x,y))));
        Assert.Equal(1, moved.State.ApRemaining);
        Assert.Equal(1, moved.State.ManaOf(player));
        Assert.True(moved.State.SkillUsedThisTurn);
        Assert.Collection(moved.Events,
            e => Assert.Equal(new ResourcesSpent(player, 1, 2), e),
            e => Assert.Equal(new PiecePushed(player, P(2,2), P(x,y), new Piece(player, PieceKind.Soldier)), e));
    }

    [Fact]
    public void Moving_a_friendly_connector_splits_its_group_but_all_parts_keep_liberties()
    {
        var s = GameSetup.FromDiagram(Hand, "..H.O\n.....\n.xxx.\n.....\nX....", HeroClass.Mage);
        Assert.Equal(3, BoardRuleEngine.GetGroup(s.Board, P(2,2)).Count);
        Assert.Equal(8, BoardRuleEngine.CountLiberties(s.Board, P(2,2)));
        var moved = Play(s, new CastMagicHand(P(2,2), PushDirection.Down));
        foreach (var p in new[] { P(1,2), P(3,2), P(2,3) })
        {
            Assert.Equal(new[] { p }, BoardRuleEngine.GetGroup(moved.Board, p));
            Assert.Equal(4, BoardRuleEngine.CountLiberties(moved.Board, p));
        }
    }

    [Fact]
    public void Friendly_push_can_capture_an_enemy_by_filling_its_last_liberty_with_ordered_events()
    {
        var s = GameSetup.FromDiagram(Hand, "o.x..\nx.H..\n.....\n.....\nX...O", HeroClass.Mage);
        Assert.Equal(new[] { P(1,0) }, BoardRuleEngine.GetLiberties(s.Board, [P(0,0)]));
        var moved = GameEngine.Apply(s, new CastMagicHand(P(2,0), PushDirection.Left));
        Assert.True(moved.Success, moved.Validation.Message);
        Assert.Null(moved.State.Board[P(0,0)]);
        Assert.Null(moved.State.Board[P(2,0)]);
        Assert.Equal(new Piece(Player.One, PieceKind.Soldier), moved.State.Board[P(1,0)]);
        Assert.Equal(P(2,1), moved.State.Board.FindHero(Player.One));
        Assert.Collection(moved.Events,
            e => Assert.Equal(new ResourcesSpent(Player.One,1,2), e),
            e => Assert.Equal(new PiecePushed(Player.One,P(2,0),P(1,0),new Piece(Player.One,PieceKind.Soldier)), e),
            e => Assert.Equal(new[] { new CapturedPiece(P(0,0),new Piece(Player.Two,PieceKind.Soldier)) },
                Assert.IsType<PiecesCaptured>(e).Pieces));
    }

    [Fact]
    public void Returning_a_friendly_soldier_to_an_older_board_is_superko_with_full_rollback()
    {
        var s = GameSetup.FromDiagram(Hand, "....O\n..x..\n..H..\n.....\nX....", HeroClass.Mage);
        s = Play(s, new CastMagicHand(P(2,1),PushDirection.Right), new EndTurn(), new EndTurn());
        AssertRejected(s, new CastMagicHand(P(3,1),PushDirection.Left), IllegalReason.Ko);
        Assert.True(GameEngine.Apply(s, new CastMagicHand(P(3,1),PushDirection.Down)).Success);
    }
}

using TacticalGo.Domain;
using static TacticalGo.Domain.Tests.TestKit;

namespace TacticalGo.Domain.Tests;

public class MagicHandReplayTests
{
    [Fact]
    public void Range_two_connector_is_a_custom_five_by_five_mechanism_demo_with_five_starting_liberties()
    {
        var config = new RuleConfig { BoardSize = 5, MageSkill = MageSkill.MagicHand,
            CommanderOneStart = P(4, 4), CommanderTwoStart = P(0, 1) };
        GameAction[] setup = [new PlaceSoldier(P(1, 4)), new PlaceSoldier(P(1, 1)), new PlaceSoldier(P(2, 1)),
            new PlaceSoldier(P(0, 0)), new PlaceSoldier(P(0, 2)), new EndTurn(),
            new SummonHero(P(1, 3)), new EndTurn(), new EndTurn()];
        var root = GameSession.Replay(config, HeroClass.Mage, HeroClass.None, setup).State;
        Assert.Equal("x....\nOoo..\nx....\n.H...\n.x..X", root.Board.ToString());
        // Independent coordinates from the Owner's board review; never change this board to fit a count.
        Assert.Equal(5, BoardRuleEngine.CountLiberties(root.Board, P(0, 1)));
        Assert.Equal(new[] { P(1, 0), P(2, 0), P(3, 1), P(1, 2), P(2, 2) },
            BoardRuleEngine.GetLiberties(root.Board, BoardRuleEngine.GetGroup(root.Board, P(0, 1)))
                .OrderBy(p => p.Y).ThenBy(p => p.X));
        Assert.Equal(Player.One, root.Current);
        Assert.Equal(7, root.Ply);
        Assert.Equal(2, root.ApRemaining);
        Assert.Equal(4, root.ManaOf(Player.One));
        var won = Play(root, new CastMagicHand(P(1, 1), PushDirection.Down), new PlaceSoldier(P(1, 1)));
        Assert.Equal(GameStatus.Won, won.Status);
        Assert.Equal(Player.One, won.Winner);
        Assert.Equal(P(1, 3), won.Board.FindHero(Player.One));
        Assert.Equal('o', BoardText.ToChar(won.Board[P(1, 2)]));
    }
}

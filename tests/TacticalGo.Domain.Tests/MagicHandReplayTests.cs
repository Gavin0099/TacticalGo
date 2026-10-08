using TacticalGo.Domain;
using static TacticalGo.Domain.Tests.TestKit;

namespace TacticalGo.Domain.Tests;

public class MagicHandReplayTests
{
    [Fact]
    public void Range_two_connector_tactic_is_reachable_by_a_legal_game_with_a_summoned_mage()
    {
        var config = new RuleConfig { BoardSize = 5, MageSkill = MageSkill.MagicHand,
            CommanderOneStart = P(4, 4), CommanderTwoStart = P(0, 1) };
        GameAction[] setup = [new PlaceSoldier(P(1, 4)), new PlaceSoldier(P(1, 1)), new PlaceSoldier(P(2, 1)),
            new PlaceSoldier(P(0, 0)), new PlaceSoldier(P(0, 2)), new EndTurn(),
            new SummonHero(P(1, 3)), new EndTurn(), new EndTurn()];
        var root = GameSession.Replay(config, HeroClass.Mage, HeroClass.None, setup).State;
        Assert.Equal("x....\nOoo..\nx....\n.H...\n.x..X", root.Board.ToString());
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
